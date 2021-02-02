#!/bin/bash

set -e

echo Checking if it is OK to stop
HOSTNAME=$(hostname -s)
OSDS=$(ceph osd crush ls ${HOSTNAME})
ceph osd ok-to-stop ${OSDS}

echo 
echo Resetting BMC...
ipmitool mc reset cold

echo
echo Setting ceph config
ceph osd set noout
ceph osd set noin

echo
echo Disabling no_contact alarm...
kinit -k
roger update --nc_alarmed false --duration 30min ${HOSTNAME}

echo
echo Rebooting in 30 seconds \(ctrl-c to cancel\)...
sleep 30

reboot
