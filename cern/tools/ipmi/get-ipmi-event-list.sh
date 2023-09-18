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
CONSOLE=$(openstack console url show -f json $HOST)

POWER_STATUS=$(echo $CONSOLE | jq -r ".url.ipmitool_chassis_power_status")
if [ x"$POWER_STATUS" != x"null" ]; then
  echo $POWER_STATUS | \
    stdbuf -i0 -o0 -e0 sed -e 's/chassis power status/sel list/g'
fi

# In case BMC uses Supermicro Redfish
POWER_STATUS=$(echo $CONSOLE | jq -r ".url.power_status")
if [ x"$POWER_STATUS" != x"null" ]; then
  echo $POWER_STATUS | \
    stdbuf -i0 -o0 -e0 sed -e 's/^rf_power_reset.py /ipmitool -I lanplus /g' | \
    stdbuf -i0 -o0 -e0 sed -e 's/ --user / -U /g' | \
    stdbuf -i0 -o0 -e0 sed -e 's/ --password / -P /g' | \
    stdbuf -i0 -o0 -e0 sed -e 's# --rhost https://# -H #g' | \
    stdbuf -i0 -o0 -e0 sed -e 's/ --info/ sel list/g'
fi
