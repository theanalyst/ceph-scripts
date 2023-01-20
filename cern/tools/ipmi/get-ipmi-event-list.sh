#!/bin/bash


HOST=$1
if [ x"" == x"$HOST" ];
then
  echo "ERR: Hostname not specified"
fi

eval $(ai-rc -s $HOST)
openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

echo
echo "Your ipmi sel list command is:"
openstack console url show -f json $HOST | \
  stdbuf -i0 -o0 -e0 jq -r ".url.ipmitool_chassis_power_status" | \
  stdbuf -i0 -o0 -e0 sed -e 's/chassis power status/sel list/g'

