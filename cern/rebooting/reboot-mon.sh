#!/bin/bash

set -e

echo Checking if it is OK to stop
CLUSTER=$(facter --json | jq .hostgroup_1 | xargs)
HOSTNAME=$(hostname -s)

if [[ $cluster =~ "gabe" ]]
	echo "$cluster will incurr slowops on mon restart"
	echo "use ceph-scripts/cern/rebooting/slow-ops-reboot/ instead."
	exit 
fi

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
