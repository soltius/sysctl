# encoding: utf-8

control 'restore sysctl file backup' do
  impact 1.0
  title 'Verify if backup file is restored successfuly'
  desc 'Verify if backup file is restored successfuly'

  describe file('/etc/sysctl.d/*.backup') do
    it { should_not exist }
    it { should_not be_file }
  end

  describe file('/etc/sysctl.d/99-chef-merged-sysctl.conf') do
    it { should_not exist }
  end

  describe command 'ls -lsa *.backup' do
    its(:exit_status) { should_not eq 0 }
    its(:stdout) { should_not match(/backup/) }
  end
end
