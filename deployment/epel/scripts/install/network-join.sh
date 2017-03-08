#!/bin/bash
#(c)2017 Alces Software Ltd. HPC Consulting Build Suite
#Job ID: <JOB>
#Cluster: <CLUSTER>

source /root/.deployment

if [ -z "${_ALCES_NET}" ]; then
  NET="PRV"
else
  NET="${_ALCES_NET}"
fi
NETDOMAIN=`get_value "_ALCES_${NET}DOMAIN"`
INTERFACE=`get_value "_ALCES_${NET}INTERFACE"`
NETMASK=`get_value "_ALCES_${NET}NETMASK"`
NETWORK=`get_value "_ALCES_${NET}NETWORK"`
GATEWAY=`get_value "_ALCES_${NET}GATEWAY"`

#This is literally translated to the TYPE in redhat-sysconfig-network
TYPE=`get_value "_ALCES_${NET}TYPE"`
#If TYPE is 'Bond' or 'Bridge', we'll also need these set to setup the slaves
SLAVEINTERFACES=`get_value "_ALCES_${INTERFACE}_INTERFACES"`
#If TYPE is 'Bond', you can set bonding options here
BONDOPTIONS=`get_value "_ALCES_${INTERFACE}_OPTIONS"`

#Force an IP, rather than attempt a lookup
IP=`get_value "_ALCES_${NET}IP"`

HOST="${_ALCES_BASE_HOSTNAME}.${NETDOMAIN}"

#No IP has been given, use the hosts file as a lookup table
if [ -z "${IP}" ]; then
  IP=`getent hosts | grep $HOST | awk ' { print $1 }'`
fi

echo "Running network configuration for NET:$NET HOSTNAME:$HOST INTERFACE:$INTERFACE NETMASK:$NETMASK NETWORK:$NETWORK GATEWAY:$GATEWAY IP:$IP"

CONFIGDIR=/etc/sysconfig/network-scripts/
FILENAME="${CONFIGDIR}ifcfg-${INTERFACE}"

if ! [ -z "${TYPE}" ]; then
  TYPE=$TYPE
elif ( `echo "${INTERFACE}" | grep -q "^bond.*$"` ); then 
  TYPE="Bond"
elif ( `echo "${INTERFACE}" | grep -q "^ib.*$"` ); then
  TYPE="InfiniBand"
else
  TYPE="Ethernet"
fi

if ! [ -z "${IP}" ]; then
  echo "Writing: $FILENAME"
  cat << EOF > $FILENAME
TYPE=$TYPE
BOOTPROTO=none
DEFROUTE=yes
PEERDNS=no
PEERROUTES=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
NAME=$INTERFACE
DEVICE=$INTERFACE
ONBOOT=yes
IPADDR=$IP
NETMASK=$NETMASK
ZONE=trusted
EOF
fi

if ! [ -z $GATEWAY ]; then
  echo "GATEWAY=\"${GATEWAY}\"" >> $FILENAME
fi

if [ $TYPE == "Bond" ]; then
  echo "Setting up bond for $INTERFACE ($BONDOPTIONS) - $SLAVEINTERFACES"
  echo "BONDING_OPTS=\"${BONDOPTIONS}\"" >> $FILENAME
  for i in $SLAVEINTERFACES; do
    FILENAME="${CONFIGDIR}ifcfg-${i}"
    echo "Writing: $FILENAME"
    cat << EOF > $FILENAME
TYPE=Ethernet
BOOTPROTO=none
DEFROUTE=no
PEERDNS=no
PEERROUTES=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_PEERDNS=no
IPV6_PEERROUTES=no
IPV6_FAILURE_FATAL=no
NAME=$i
DEVICE=$i
ONBOOT=yes
MASTER=$INTERFACE
SLAVE=yes
EOF
  done
fi

if [ $TYPE == "Bridge" ]; then
  echo "Setting up bridge for $INTERFACE - $SLAVEINTERFACES"
  echo "STP=no" >> $FILENAME
  for i in $SLAVEINTERFACES; do
    FILENAME="${CONFIGDIR}ifcfg-${i}"
    echo "Writing: $FILENAME"
    cat << EOF > $FILENAME
TYPE=Ethernet
BOOTPROTO=none
DEFROUTE=no
PEERDNS=no
PEERROUTES=no
IPV4_FAILURE_FATAL=no
IPV6INIT=no
IPV6_AUTOCONF=no
IPV6_DEFROUTE=no
IPV6_PEERDNS=no
IPV6_PEERROUTES=no
IPV6_FAILURE_FATAL=no
NAME=$i
DEVICE=$i
ONBOOT=yes
BRIDGE=$INTERFACE
EOF
  done
fi
