#!/bin/bash

# Usage: ./recreate-osds.sh
#
# This tool looks for destroyed OSDs on the localhost and uses ceph-volume to
# take an inventory of all usable devices. Finally, it suggests a ceph-volume
# command to be used to recreate missing OSDs.

set -e

HOST=$(hostname -s)
OSDS=$(ceph osd tree-from $HOST destroyed | grep osd\. | awk '{print $1}' | xargs echo)

if [ -z "$OSDS" ]
then
      echo ERROR: Could not find ID of destroyed OSDs on $HOST, exiting...
      exit 1
fi

DEVS=$(ceph-volume inventory --format json --filter-for-batch | jq -r .[].path | xargs echo)

echo This tool is in beta testing. Double check output before running the suggested command.
echo
echo Found OSDs $OSDS to be recreated. Use this command:
echo
echo ceph-volume batch $DEVS --osd-id $OSDS

