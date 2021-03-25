#!/bin/bash

set -e

kinit -k

echo Checking if it is OK to stop
ceph daemon mds.`hostname -s` status | jq .state | grep standby

if facter -p is_virtual | grep -q false
then
    echo
    echo Resetting BMC...
    ipmitool mc reset cold
fi

echo
echo Disabling no_contact alarm...
roger update --nc_alarmed false --duration 30min

echo
echo Rebooting in 30 seconds \(ctrl-c to cancel\)...
sleep 30

reboot
