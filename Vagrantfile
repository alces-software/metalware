$script = <<SCRIPT
yum install -y nano

mkdir -p /root/.ssh
cat /home/vagrant/.ssh/authorized_keys > /root/.ssh/authorized_keys

rm -rf /opt/metalware
curl https://raw.githubusercontent.com/alces-software/metalware/develop/scripts/bootstrap | /bin/bash

source /opt/metalware/bin/test
source /etc/profile.d/alces-metalware.sh

$alces_RUBY /opt/metalware/test/testsuite.rb 2>&1 | tee /tmp/vagrant-metalware-test.log
SCRIPT

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Launches a Centos VM
  config.vm.box = "hfm4/centos7"
  config.vm.box_check_update = false
  config.vm.network "private_network", ip: "192.168.50.101"

  config.vm.provision "shell",
    inline: $script,
    env: {
      alces_SOURCE_BRANCH: "feature/fs-repo",
      alces_OS: "el7",
      alces_TEST: true
    }

  config.vm.synced_folder ".", "/opt/metalware/"
end
