#!/bin/bash

set -e

echo Checking if it is OK to stop
HOSTNAME=$(hostname -s)
ceph mon ok-to-stop mon.`hostname -s`

if facter -p is_virtual | grep -q false
then
    echo
    echo Resetting BMC...
    ipmitool mc reset cold
fi

echo
echo Disabling no_contact alarm...
kinit -k
roger update --nc_alarmed false --duration 30min ${HOSTNAME}

echo
echo Rebooting in 30 seconds \(ctrl-c to cancel\)...
sleep 30

reboot
