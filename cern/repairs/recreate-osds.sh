#!/bin/bash

# Usage: ./recreate-osds.sh
#
# This tool looks for destroyed OSDs on the localhost and uses ceph-volume to
# take an inventory of all usable devices. Finally, it suggests a ceph-volume
# command to be used to recreate missing OSDs.
#
# The output from ceph-volume batch will show which OSD id, data, and block_db
# devices that it will use. Here is a good example; anything else should be
# aborted.
#
# Total OSDs: 1
#
#   Type            Path                                                    LV Size         % of device
# ----------------------------------------------------------------------------------------------------
#   OSD id          234
#   data            /dev/sdh                                                5.46 TB         100.00%
#   block_db        /dev/sdaa                                               37.26 GB        16.67%
# --> The above OSDs would be created if the operation continues
# --> do you want to proceed? (yes/no)
#

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

