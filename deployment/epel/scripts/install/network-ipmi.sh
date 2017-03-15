#!/bin/bash
#(c)2017 Alces Software Ltd. HPC Consulting Build Suite
#Job ID: <JOB>
#Cluster: <CLUSTER>

source /root/.deployment

NET="BMC"
NETDOMAIN=`get_value "_ALCES_${NET}DOMAIN"`
NETMASK=`get_value "_ALCES_${NET}NETMASK"`
NETWORK=`get_value "_ALCES_${NET}NETWORK"`
GATEWAY=`get_value "_ALCES_${NET}GATEWAY"`

#Force an IP, rather than attempt a lookup
IP=`get_value "_ALCES_${NET}IP"`

HOST="${_ALCES_BASE_HOSTNAME}.${NETDOMAIN}"

#No IP has been given, use the hosts file as a lookup table
if [ -z "${IP}" ]; then
  echo "Guessing IP using: $HOST"
  IP=`getent hosts | grep $HOST | awk ' { print $1 }'`
fi

BMCPASSWORD=`get_value "_ALCES_${NET}PASSWORD"`
BMCCHANNEL=`get_value "_ALCES_${NET}CHANNEL"`
BMCUSER=`get_value "_ALCES_${NET}USER"`

yum -y install ipmitool

if ! [ -z "$HOST" ]; then
  if ! [ -z "$IP" ]; then
    echo "Setting up BMC for $HOST. IP: $IP NETMASK: $NETMASK GATEWAY: $GATEWAY CHANNEL: $BMCCHANNEL USER: $BMCUSER"
    service ipmi start
    sleep 1
    ipmitool lan set $BMCCHANNEL ipsrc static
    sleep 2
    ipmitool lan set $BMCCHANNEL ipaddr $IP
    sleep 2
    ipmitool lan set $BMCCHANNEL netmask $NETMASK
    sleep 2
    ipmitool lan set $BMCCHANNEL defgw ipaddr $GATEWAY
    sleep 2
    ipmitool user set name $BMCUSER admin
    sleep 2
    ipmitool user set password $BMCUSER $BMCPASSWORD
    sleep 2
    ipmitool lan print $BMCCHANNEL
    ipmitool user list $BMCUSER
    ipmitool mc reset cold
  fi
fi
