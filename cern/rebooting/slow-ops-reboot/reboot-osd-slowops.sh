#!/bin/bash

# #####
#
# This script is part of a set of two scripts (reboot-osd-slowops.sh,
#   startup-osd-slowops.sh) that help reducing SLOW_OPS when a node is rebooted.
#
# - reboot-osd-slowops.sh disables all the systemd units for OSDs and reboots
#     the node (similarly to the traditional reboot-osd.sh)
# - startup-osd-slowops.sh identifies the mapping of OSDs to fast journaling
#     devices (SSDs, NVMEs) and enables + start a group of OSDs such that no
#     more than one is activated per fast device.
#     In practice, on a node with 48 OSDs and 4 SSDs/NVMes, the script will
#     enable + start 4 OSDs at a time. This should help to not saturate SSDs/NVMes
#     and reduce the number of SLOW_OPS when bringing all the OSDs back.
#
# #####

set -e

echo "Checking if it is OK to stop"
HOSTNAME=$(hostname -s)
OSDS=$(ceph osd tree-from $HOSTNAME -f json | jq -r '.nodes[].children[]?')
ceph osd ok-to-stop ${OSDS}

echo
echo "Resetting BMC..."
ipmitool mc reset cold

echo
echo "Setting ceph configure"
ceph osd set noout
ceph osd set noin

echo
echo "Disabling no_contact alarm..."
kinit -k
roger update --nc_alarmed false --duration 30min ${HOSTNAME}

echo
echo "Masking all osd systemd units... "
echo "WARNING: osds will NOT come back automatically"
echo "Use startup-osd-slowops.sh to bring them back slowly..."
echo
for i in ${OSDS}
do
    systemctl mask ceph-osd@$i
done

echo
echo "Rebooting in 30 seconds (ctrl-c to cancel)..."
sleep 30

reboot
