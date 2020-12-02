#!/bin/bash

set -e

echo Checking if it is OK to stop
HOSTNAME=$(hostname -s)
ceph mon ok-to-stop mon.`hostname -s`

echo 
echo Resetting BMC...
ipmitool mc reset cold

echo
echo Disabling no_contact alarm...
roger update --nc_alarmed false --duration 30min ${HOSTNAME}

echo
echo Rebooting in 30 seconds \(ctrl-c to cancel\)...
sleep 30

reboot
