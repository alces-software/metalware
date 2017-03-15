#!/bin/bash
#(c)2017 Alces Software Ltd. HPC Consulting Build Suite
#Job ID: <JOB>
#Cluster: <CLUSTER>

source /root/.deployment
yum -y -e0 install mariadb mariadb-test mariadb-libs mariadb-embedded mariadb-embedded-devel mariadb-devel mariadb-bench
yum -y -e0 install munge munge-devel munge-libs perl-Switch
install_file mungekey /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
chown munge /etc/munge/munge.key
systemctl enable munge
systemctl enable mariadb

yum -y install slurm slurm-devel slurm-munge slurm-perlapi slurm-plugins slurm-sjobexit slurm-sjstat slurm-slurmdbd slurm-sql

mkdir /var/log/slurm
chown nobody /var/log/slurm

install_file slurmconf /etc/slurm/slurm.conf

systemctl enable slurm

