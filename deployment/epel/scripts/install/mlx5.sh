#!/bin/bash

curl http://${_ALCES_BUILDSERVER}/${_ALCES_CLUSTER}/upstream/MLNX_OFED_LINUX-4.0-1.0.1.0-rhel7.3-x86_64.tgz > /tmp/MLNX_OFED_LINUX-4.0-1.0.1.0-rhel7.3-x86_64.tgz
tar -zxvf /tmp/MLNX_OFED_LINUX-4.0-1.0.1.0-rhel7.3-x86_64.tgz -C /tmp/
rm -v /tmp/MLNX_OFED_LINUX-4.0-1.0.1.0-rhel7.3-x86_64.tgz
cd /tmp/MLNX_OFED_LINUX-4.0-1.0.1.0-rhel7.3-x86_64

yum -y -e 0 install libnl lsof gcc-gfortran tcsh gtk2 tk
./mlnxofedinstall -q
#-c /tmp/MLNX_OFED_LINUX-4.0-1.0.1.0-rhel7.3-x86_64/docs/conf/ofed-all.conf

rm -rf /tmp/MLNX_OFED_LINUX-4.0-1.0.1.0-rhel7.3-x86_64
