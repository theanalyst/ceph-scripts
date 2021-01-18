#!/bin/bash

set -e

kinit -k

echo Checking if it is OK to stop
ceph daemon mds.`hostname -s` status | jq .state | grep standby

echo
echo Disabling no_contact alarm...
roger update --nc_alarmed false --duration 30min

echo
echo Rebooting in 30 seconds \(ctrl-c to cancel\)...
sleep 30

reboot
