# encoding: utf-8

control 'configure Sysctl' do
  impact 1.0
  title 'Verify sysctl is configured as expected'
  desc 'Verify sysctl is configured as expected'

  describe command('sysctl -n vm.swappiness') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^40$/) }
  end

  describe file('/etc/sysctl.d/99-chef-merged-sysctl.conf') do
    it { should exist }
    it { should be_file }
    its(:content) { should match /^vm.swappiness=40$/ }
  end
end
