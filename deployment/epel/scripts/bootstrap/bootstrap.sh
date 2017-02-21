#!/bin/bash
#(c)2017 Alces Software Ltd. HPC Consulting Build Suite


BASEPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"

if ! [ -f "$CONFIG" ]; then
  echo "CAN'T FIND A CONFIG FILE" >&2
  exit 1
fi

source $CONFIG

CONFPATH=$BASEPATH/../../conf/
cp -v $CONFIG ${CONFPATH}/${_ALCES_CLUSTER}
ln -snf ${CONFPATH}/${_ALCES_CLUSTER} ${CONFPATH}/config
ln -snf ${CONFPATH}/${_ALCES_CLUSTER} /root/.deployment
