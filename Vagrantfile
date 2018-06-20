# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.


$dev_path='/tmp/metalware'
$script = <<SCRIPT

export alces_OS=el7
curl -sL http://git.io/metalware-installer | /bin/bash

echo "pathmunge /opt/metalware/opt/ruby/bin" > /etc/profile.d/metalware-ruby.sh
. /etc/profile

cd #{$dev_path}
bundle install

SCRIPT


Vagrant.configure(2) do |config|
  config.vm.box = 'centos/7'
  config.vm.network "private_network", type: 'dhcp'
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder '.', $dev_path
  config.vm.provision 'shell', inline: $script
end
