#!/bin/bash
set -e

VERBOSE=true

function print_debug {
  if $VERBOSE; then
    echo "$1"
  fi
}

echo DEBUG: Checking bash version...
if [ "$BASH_VERSINFO" -lt 4 ];
then
  print_debug "ERROR: Bash 4 (or greater) required"
  exit 1
fi

# We sleep for 2 mintues seconds after having activated a batch of OSDs
SLEEP_TIME=120
print_debug "DEBUG: Sleep time after having activated a batch of OSDs is set to $SLEEP_TIME seconds"


# We are interested in non-rotational (SSD, NVME) devices
print_debug "DEBUG: Identifying fast devices (typically used for journaling)..."
INVENTORY=$(ceph-volume inventory --format json)
DBDEVS=$(echo $INVENTORY | jq -r '.[] | select (.sys_api.rotational == "0") | .path' | xargs)
print_debug "DEBUG: Fast devices are ${DBDEVS}"

# Build mapping of which OSDs (using osd_id) are hosted on each journaling device
print_debug "DEBUG: Identifying hosted OSDs for each journaling device..."
declare -A MAPPING
for dbdev in ${DBDEVS}
do
    OSD_IDS=$(echo $INVENTORY | jq --arg jq_dbdev $dbdev -r '.[] | select (.path == $jq_dbdev) | .lvs | .[] | select (.type == "db") | .osd_id' | xargs)
    if [ x"$OSD_IDS" == x"" ]; then
        print_debug "DEBUG: $dbdev -- No OSDs found (system disk?). Dropping from list..."
    else
        print_debug "DEBUG: $dbdev -- $OSD_IDS"
        MAPPING[$dbdev]=$OSD_IDS
    fi
done

# Bring the OSDs back one batch at a time
print_debug "DEBUG: Activating one OSD per journaling device at a time..."
echo

FINISHED=false
while ! $FINISHED
do
  # Iterate over the devices used for journaling
  #   and start one OSD for each of them
  for dbdev in ${!MAPPING[@]}
  do
    osd_id=$(echo ${MAPPING[$dbdev]} | cut -d ' ' -f 1)
    echo "systemctl unmask ceph-osd@$osd_id && systemctl enable --runtime ceph-osd@$osd_id && systemctl start ceph-osd@$osd_id"

    remaining=$(echo ${MAPPING[$dbdev]} | cut -d ' ' -f 2- --only-delimited)
    MAPPING[$dbdev]=$remaining

    # If there are no more OSDs to activate, we are done
    # WARNING: This assumes all the devices used for journaling serve
    #          the same amount of rotational OSDs
    if [ x"$remaining" == x"" ]
    then
      FINISHED=true
    fi
  done
  echo sleep $SLEEP_TIME
  echo
done
