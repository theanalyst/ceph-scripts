#!/bin/bash

HEALTH=$(ceph health)
if [ "$HEALTH" != 'HEALTH_OK' ];
then
    echo Aborting reboot because ceph is not healthy:
    echo
    ceph status
fi

echo -n Resetting BMC...
ipmitool mc reset cold
echo done.


echo -n Setting ceph noout, noin...
ceph osd set noout
ceph osd set noin
echo done.

echo -n Disabling no_contact alarm...
roger update --nc_alarmed false --duration 30min
echo done.

echo Rebooting in 30 seconds \(ctrl-c to cancel\)...
sleep 30

reboot
