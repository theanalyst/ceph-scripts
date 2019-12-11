#! /bin/bash

#drives=`ceph-volume inventory | awk '{ if( $4 == "True" && $5 == "True") print $0}' | grep -v "/dev/m" `
drives=`ceph-volume inventory --format json | jq '.[] | select(.available)'`

if [[ $drives -ne "" ]];
then
  echo "$HOSTNAME: "
  echo "$drives"
  echo ""
fi
