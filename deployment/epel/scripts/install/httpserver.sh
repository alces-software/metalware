#!/bin/bash
#(c)2017 Alces Software Ltd. HPC Consulting Build Suite
#Job ID: <JOB>
#Cluster: <CLUSTER>

. /root/.deployment

yum -y install httpd

install_file httpddeployment /etc/httpd/conf.d/deployment.conf
mkdir -p /var/lib/metalware/rendered/exec/
install_file httpddeployment.kscomplete /var/lib/metalware/rendered/exec/kscomplete.php
chmod +x /var/lib/metalware/rendered/exec/kscomplete.php

service httpd start
systemctl enable httpd

