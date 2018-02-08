# sysctl

This cookbook provides recipes for changing Sysctl attributes.

## Compatibility Matrix

| Recipe Name | amazon-2017.03 | redhat-7.4 | suse-12.2 | suse-12.3 | ubuntu-16.04 |
| --- | --- | --- | --- | --- | --- | --- |
| `sysctl::apply` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `sysctl::restore` | ✓ | ✓ | ✓ | ✓ | ✓ |

## Attributes overview

| Name | Type | Default | Required |
| --- | --- | --- | --- |
| `['sysctl']['restart_procps']` | boolean | true | No |
| `['sysctl']['ignore_error']` | boolean | false | No |


## Resources

### sysctl_param

The `sysctl_param` resource can be called from wrapper or application cookbooks to immediately set the kernel parameter and cue the kernel parameter to be written out to the configuration file.

This also requires that your run_list include the `sysctl::default` recipe in order to persist the settings.

#### Actions

- `:apply` (default)
- `:restore`

#### Examples

**`:apply`**
**Description:** Set vm.swappiness to 20 via sysctl_param resource.  [source code](libraries/sysctl_param.rb)

```ruby
    sysctl_param 'vm.swappiness' do
      value 20
	  action :apply
    end
```
**Description:** Update vm.swappiness from 20 to 30 via sysctl_param resource. [source code](libraries/sysctl_param.rb)
```ruby
    sysctl_param 'vm.swappiness' do
      value 30
	  action :apply
    end
```

 **`:restore`**
**Description:** Restore sysctl backup and set sysctl config files back to default. [source code](libraries/sysctl_param.rb)

```ruby
    sysctl_param 'any name' do
	  action :restore
    end
```
Note: The restore function only restores a backup made from the initial ```:apply``` function. If  ```:apply``` hasn't been called the backup file will not exist.
When you call the  ```:apply``` function, it will create .backup files in the folder "/etc/sysctl.d/"  from previous files named .conf which are called by the sysctl tool. Then, when you call the  ```:restore``` function is called it will restore all .backup files to its original names and deletes the "99-chef-merged" file.

### Ohai Plugin

The cookbook also includes an Ohai plugin that can be installed by adding `sysctl::ohai_plugin` to your run_list. This will populate `node['sys']` with automatic attributes that mirror the layout of `/proc/sys`.

To see Ohai plugin output manually, you can run `ohai -d /etc/chef/ohai/plugins sys` on the command line.

## Additional Reading

There are a lot of different documents that talk about system control parameters, the hope here is to point to some of the most useful ones to provide more guidance as to what the possible kernel parameters are and what they mean.

- [Chef OS Hardening Cookbook](https://github.com/dev-sec/chef-os-hardening)
- [Linux Kernel Sysctl](https://www.kernel.org/doc/Documentation/sysctl/)
- [Linux Kernel IP Sysctl](http://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt)
- [Linux Performance links](http://www.brendangregg.com/linuxperf.html) by Brendan Gregg
- [RHEL 7 Performance Tuning Guide](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/pdf/Performance_Tuning_Guide/Red_Hat_Enterprise_Linux-7-Performance_Tuning_Guide-en-US.pdf) by Laura Bailey and Charlie Boyle
- [Performance analysis & tuning of Red Hat Enterprise Linux at Red Hat Summit 2015 (video)](https://www.youtube.com/watch?v=ckarvGJE8Qc) slides [part 1](http://videos.cdn.redhat.com/summit2015/presentations/15284_performance-analysis-tuning-of-red-hat-enterprise-linux.pdf) by Jeremy Eder, D. John Shakshober, Larry Woodman and Bill Gray
- [Performance Tuning Linux Instances on EC2 (Nov 2014)](http://www.brendangregg.com/blog/2015-03-03/performance-tuning-linux-instances-on-ec2.html) by Brendan Gregg
- [Part 1: Lessons learned tuning TCP and Nginx in EC2 (Jan 2014)](http://engineering.chartbeat.com/2014/01/02/part-1-lessons-learned-tuning-tcp-and-nginx-in-ec2/)
- [Tuning TCP For The Web at Velocity 2013 (video)](http://vimeo.com/70369211), [slides](http://cdn.oreillystatic.com/en/assets/1/event/94/Tuning%20TCP%20For%20The%20Web%20Presentation.pdf) by Jason Cook
- [THE /proc FILESYSTEM (Jun 2009)](http://www.kernel.org/doc/Documentation/filesystems/proc.txt)

## Development

We have written unit tests using [chefspec](http://code.sethvargo.com/chefspec/) and integration tests in [serverspec](http://serverspec.org/) executed via [test-kitchen](http://kitchen.ci). Much of the tooling around this cookbook is exposed via guard and test kitchen, so it is highly recommended to learn more about those tools. The easiest way to get started is to install the [Chef Development Kit](https://downloads.chef.io/chef-dk/)

### Running tests

The following commands will run the tests:

```bash
chef exec bundle install
chef exec cookstyle
chef exec foodcritic .
chef exec kitchen verify
  OR
chef exec kitchen test
```

Please run the tests on any pull requests that you are about to submit and write tests for defects or new features to ensure backwards compatibility and a stable cookbook that we can all rely upon.

### Running tests continuously with guard

This cookbook is also setup to run the checks while you work via the [guard gem](http://guardgem.org/).

```bash
bundle install
bundle exec guard start
```

### ChefSpec Resource Matchers

The cookbook exposes a ChefSpec matcher to be used by wrapper cookbooks to test the cookbooks resource. See `libraries/matchers.rb` for basic usage.
