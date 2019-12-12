#! /bin/bash

#drives=`ceph-volume inventory | awk '{ if( $4 == "True" && $5 == "True") print $0}' | grep -v "/dev/m" `
drives=`ceph-volume inventory --format json | jq --arg host ${HOSTNAME} '.[] | select(.available) | . += { hostname:$host}'`

if [[ $drives -ne "" ]];
then
  echo "$drives"
fi
