module SysctlCookbook
  class SysctlParam < Chef::Resource
    require_relative 'helpers_param'
    include SysctlHelpers::Param

    resource_name :sysctl_param

    property :key, String, name_property: true
    property :value, [Array, String, Integer], coerce: proc { |v| coerce_value(v) }, required: true

    SYSCTL_MERGED_FILE = '/etc/sysctl.d/99-chef-merged-sysctl.conf'.freeze

    load_current_value do
      begin
        value get_sysctl_value(key)
      rescue
        current_value_does_not_exist!
      end
    end

    default_action :apply

    declare_action_class.class_eval do
      def whyrun_supported?
        true
      end

      def create_init
        template '/etc/rc.d/init.d/procps' do
          cookbook 'sysctl'
          source 'procps.init-rhel.erb'
          mode '0775'
          only_if { platform_family?('rhel', 'fedora', 'pld', 'amazon') }
        end

        s = service_type
        service 'procps' do
          service_name s['name'] if s['name']
          provider s['provider'] if s['provider']
          action :enable
        end
      end

      def combine_sysctl_file_no_symlink
        execute 'combine sysctl files' do
          command "cat #{confd_sysctl}/*.conf > #{config_sysctl}"
          action :run
        end unless sysctld?
      end

      # - Deprecated method to add new attributes to sysctl
      # - Using concat_sysctl_files method to be read by sysctl.

      # def create_sysctld(key, value)
      #   directory confd_sysctl
      #
      #   template "#{confd_sysctl}/99-chef-#{key}.conf" do
      #     cookbook 'sysctl'
      #     source 'sysctl.conf.erb'
      #     variables(
      #       k: key,
      #       v: value
      #     )
      #     notifies :start, 'service[procps]', :immediately if restart_procps?
      #   end
      #
      #   case node['platform']
      #   when 'redhat', 'rhel'
      #     if node['platform_version'].to_f < 7
      #       combine_sysctl_file_no_symlink
      #     end
      #   when 'suse', 'sles'
      #     if node['platform_version'].to_f < 12
      #       combine_sysctl_file_no_symlink
      #     end
      #   end
      # end

      def backup_sysctl_files(item)
        backup = "#{item}.backup"
        contents = ::File.readlines(item)
        ::File.open(backup, 'w') { |f| f.write(contents.join('')) }
      end

      def concat_sysctl_files
        paths  = ['/etc/sysctl.d/*.conf', '/run/sysctl.d/*.conf', '/usr/lib/sysctl.d/*.conf']
        merged = []

        return unless ::File.exist?(SYSCTL_MERGED_FILE)

        paths.each do |path|
          Dir.glob(path) do |item|
            merged << "\n# Parameters from #{item}"
            ::File.readlines(item).each do |line|
              # -- removes whitespaces and persists the change in "line"
              line.gsub!(/\s+/, '')

              next if merged.grep(/#{Regexp.escape(line)}/)
              merged << line unless line[0] == '#' || line.nil? || line.empty?
            end
            if path =~ /etc/
              backup_sysctl_files(item)
              ::FileUtils.rm(item)
            end
          end
        end
        template SYSCTL_MERGED_FILE do
          cookbook 'sysctl'
          source '99-chef-merged-sysctl.erb'
          variables(
            values: merged
          )
        end
      end

      def add_parameter_to_sysctl(key, value)
        bash 'insert_line' do
          user 'root'
          code <<-EOS
          echo "\n# CHEF MANAGED SYSCTL ATTRIBUTE (#{key})" >> #{SYSCTL_MERGED_FILE}
          echo "#{key}=#{value}" >> #{SYSCTL_MERGED_FILE}
          EOS
          not_if "grep -q #{key}=#{value} #{SYSCTL_MERGED_FILE}"
        end
      end

      def remove_paramater_from_sysctl(key)
        bash 'remove_line' do
          user 'root'
          code <<-EOS
          sed -i.backup "/#{key}/d" #{SYSCTL_MERGED_FILE}
          EOS
          only_if "grep -q #{key} #{SYSCTL_MERGED_FILE}"
        end
      end

      def restore_sysctl_backup
        path = '/etc/sysctl.d/*.backup'

        Dir.glob(path) do |item|
          item.gsub!(/\.backup/, '')

          bash 'restore_file' do
            user 'root'
            code <<-EOS
            mv #{item}.backup #{item}
            EOS
            only_if { ::File.exist?(SYSCTL_MERGED_FILE) }
          end
        end
        file SYSCTL_MERGED_FILE do
          action :delete
          only_if { ::File.exist?(SYSCTL_MERGED_FILE) }
        end
      end
    end

    action :apply do
      converge_if_changed do
        concat_sysctl_files
        add_parameter_to_sysctl(new_resource.key, new_resource.value)
        node.default['sysctl']['backup'][new_resource.key] ||= get_sysctl_value(new_resource.key)
        create_init
        set_sysctl_param(new_resource.key, new_resource.value)
      end
    end

    action :remove do
      converge_by "reverting #{new_resource.key}" do
        concat_sysctl_files
        remove_paramater_from_sysctl(new_resource.key)
        refresh_sysctl_param
      end
    end

    action :restore do
      converge_by 'restoring backup from /etc/sysctl.d/*.backup' do
        restore_sysctl_backup
        refresh_sysctl_param
      end
    end
  end
end
