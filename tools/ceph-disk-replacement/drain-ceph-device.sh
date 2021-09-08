#!/bin/bash

# Drain Ceph device
# Version 2021-09-08
#
# Usage: ./drain-ceph-device.sh /dev/sdX
#
# Pre-Checks:
#   * Installed Ceph >= 14.2.20
#   * Machine not in intervention state
#   * Ceph is HEALTH_OK
#   * Device exists
#   * Device maps to exactly one osd id (otherwise it is a block.db or not an osd)
#   * OSD is up, in, crush-weight > 0
#   * OSD is running
#   * OSD is holding some PGs
#   * OSD is 

MIN_CEPH_VERSION=14.2.20

usage() { echo "Usage: $0 [-v] -d /dev/sdX"; exit 1; }
err() { echo "Error: $1"; exit 1; }
log() { if [[ $VERBOSE -eq 1 ]]; then echo $1; fi }

while getopts "vd:" o; do
    case "${o}" in
        v)
            VERBOSE=1
            ;;
        d)
            DEVICE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${DEVICE}" ]; then
    usage
fi

log "Running $0 on device $DEVICE"
log "Sanity checks..."

# Check Installed Ceph >= 14.2.20
VER=$(rpm -q ceph-osd --info | grep Version | awk '{print $3}')
log "Ceph ${VER} is installed, continuing."

rpmdev-vercmp ${VER} ${MIN_CEPH_VERSION} > /dev/null
if [ $? -ne 11 ];
then
  err "Ceph version ${VER} is unsupported by this tool. Contact ceph-admins."
fi

log "Ceph is newer than ${MIN_CEPH_VERSION}, continuing."

# Check: Machine not in intervention state
APPSTATE=$(roger show $HOSTNAME  | jq -r .[].appstate)
if [ "${APPSTATE}" != "production" ]
then
  err "Machine is not in production state. Try again later or contact ceph-admins."
fi
log "Roger appstate ${APPSTATE} is good, continuing."

# Check: HEALTH_OK
HEALTH=$(ceph health)
if [ "${HEALTH}" != "HEALTH_OK" ]
then
  err "Ceph is not healthy. Try again later or contact ceph-admins."
fi
log "$HEALTH, continuing."

# Check: device exists
stat $DEVICE | grep -q 'block special file'
if [ $? -ne 0 ]
then
  err "Device $DEVICE does not seem to exist or is not a block device. Please contact ceph-admins."
fi
log "$DEVICE is a block device, continuing."

# Check device maps to exactly one osd id (otherwise it is a block.db or not an osd)
DEV=$(basename $DEVICE)
NUM=$(ceph device ls-by-host $HOSTNAME | egrep "\\b${DEV}\\b" | grep -o osd. | wc -l)
if [[ $NUM != 1 ]]
then
  err "$DEV hosts data for $NUM osds. Please contact ceph-admins."
fi
log "$DEV hosts exactly one osd, continuing."

# Check: OSD is up, in, crush-weight > 0
ID=$(ceph device ls-by-host $HOSTNAME | egrep "\\b${DEV}\\b" | awk '{print $3}' | cut -d. -f2)
if [[ -z $ID ]]
then
  err "Could not find OSD ID for $DEV. Please contact ceph-admins."
fi
log "$DEV has OSD ID $ID, continuing"


# Check: ceph-osd@$ID is running
systemctl is-active --quiet ceph-osd@$ID
if [ $? -ne 0 ]
then
  err "Service ceph-osd@$ID is not active. Please contact ceph-admins."
fi
log "Service ceph-osd@$ID is active, continuing."

# Check: OSD is holding some PGs
NUM=$(ceph daemon osd.$ID status | jq -r .num_pgs)
if [[ $NUM < 1 ]]
then
  err "OSD $ID is active but is not hosting PG data. Please contact ceph-admins."
fi
log "OSD $ID hosts $NUM PGs, continuing."

OK=$(ceph osd ok-to-stop osd.$ID | jq -r .ok_to_stop)
if [[ "$OK" != "true" ]]
then
  err "OSD $ID is not ok-to-stop. Please try again later or contact ceph-admins."
fi
log "OSD $ID is ok-to-stop, continuing."

exit

log "All good, here are the drain commands"
echo "ceph osd out osd.$ID;"
echo "ceph osd primary-affinity osd.$ID 0;"
echo "while [ \`ceph osd df tree --filter_by=name --filter=osd.$ID --format=json | jq '.nodes[].pgs'\` -ne 0 ]; do"
echo "sleep 600; echo \"Draining in progress... (\`ceph osd df tree --filter_by=name --filter=osd.$ID --format=json | jq '.nodes[].pgs'\`)\";"
echo "done;"
echo "systemctl stop ceph-osd@$ID"
echo "if ! \`ceph health | grep -q \"HEALTH_OK\"\`"
echo "then echo \"OSD unsafe to destroy, please contact ceph-admins\";"
echo "else"
echo "ceph-volume lvm zap --destroy --osd-id $OSD"
echo "ceph osd destroy $OSD --yes-i-really-mean-it"
echo "fi"



