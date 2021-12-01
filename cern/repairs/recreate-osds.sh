#!/bin/bash

# Usage: ./recreate-osds.sh
#
# This tool looks for destroyed OSDs on the localhost and uses ceph-volume to
# take an inventory of all usable devices. Finally, it suggests a ceph-volume
# command to be used to recreate missing OSDs.

echo This tool is in beta testing. Double check output before running the suggested command.
echo

set -e

HOST=$(hostname -s)
OSDS=$(ceph osd tree-from $HOST destroyed | grep osd\. | awk '{print $1}' | xargs echo)

if [ -z "$OSDS" ]
then
      echo "ERROR: Could not find any destroyed OSDs on localhost (${HOST}), exiting..."
      exit 1
fi

echo -n "Found OSD(s) ${OSDS} to be recreated. Checking device inventory ... "

DEVS=$(ceph-volume inventory --format json --filter-for-batch | jq -r .[].path | xargs echo)
echo done
echo

echo "Please use this command to recreate OSDs. Check the planned changes and type 'yes' if it looks correct:"
echo
echo ceph-volume lvm batch ${DEVS} --osd-id ${OSDS}

