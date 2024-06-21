#!/bin/bash

set -e

echo Checking if it is OK to stop
HOSTNAME=$(hostname -s)
CLUSTER=$(facter --json | jq .hostgroup_1 | xargs)
OSDS=$(ceph osd crush ls ${HOSTNAME})
ceph osd ok-to-stop ${OSDS}
ceph mon ok-to-stop mon.${HOSTNAME}

if [[ $CLUSTER =~ "gabe" ]]; then
        echo "$CLUSTER will incurr slowops on mon restart"
        echo "use ceph-scripts/cern/rebooting/slow-ops-reboot/ instead."
        exit
fi

if facter -p is_virtual | grep -q false
then
    echo
    echo Resetting BMC...
    ipmitool mc reset cold
fi

echo
echo Setting ceph config
ceph osd set noout
ceph osd set noin

echo
echo Disabling no_contact alarm...
kinit -k
roger update --nc_alarmed false --duration 30min ${HOSTNAME}

echo
echo Gracefully stoping mon...
echo Watch ceph -s for quorum state. Make sure there is a quorum before the node get rebooted.
systemctl stop ceph-mon.target

echo
echo Rebooting in 60 seconds \(ctrl-c to cancel\)...
sleep 60

reboot
