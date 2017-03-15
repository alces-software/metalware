#!/bin/bash
#(c)2017 Alces Software Ltd. HPC Consulting Build Suite
#Job ID: <JOB>
#Cluster: <CLUSTER>

source /root/.deployment

run_script install/network-base.sh
run_script install/network-ipmi.sh

for n in $_ALCES_NETWORKS; do
  export _ALCES_NET=$n
  run_script install/network-join.sh
done

