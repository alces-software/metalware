#!/bin/bash
#(c)2017 Alces Software Ltd. HPC Consulting Build Suite
#Job ID: <JOB>
#Cluster: <CLUSTER>

source /root/.deployment

install_file hosts /etc/hosts

yum -y install git vim emacs xauth xhost xdpyinfo xterm xclock tigervnc-server ntpdate wget vconfig bridge-utils patch tcl-devel gettext

rm -rf /etc/yum.repos.d/*.repo
install_file $_ALCES_YUMTEMPLATE /etc/yum.repos.d/cluster.repo
yum -y install ntp
install_file ntp /etc/ntp.conf
systemctl enable ntpd
systemctl restart ntpd
systemctl disable chronyd

mkdir -m 0700 /root/.ssh
install_file authorized_keys /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

echo "StrictHostKeyChecking no" >> /root/.ssh/config

yum -y install yum-plugin-priorities yum-utils

yum -y install net-tools bind-utils ipmitool

yum -y update 

#Branch for profile
if [ "${_ALCES_PROFILE}" == 'INFRA' ]; then
  yum -y install device-mapper-multipath sg3_utils
  yum -y groupinstall "Gnome Desktop"
  mpathconf
  mpathconf --enable
else
  echo "Unrecognised profile"    
fi

