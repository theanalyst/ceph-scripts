#!/bin/bash

usage="scrub_largeomap.sh <pg>

where:
  <pg> is the PG with the large omap object
"

# Do we have a PG to deep scrub?
PG=$1
if [ x"$PG" == x"" ];
then
  echo "Error: PG to scrub not provided."
  echo "$usage"
  exit
fi

# Check the PG is not scrubbing already
echo Checking PG $PG to scrub
if ceph pg ls scrubbing | grep deep | grep -wq ${PG}
then
   echo PG $PG is already scubbing, skipping.
   exit
fi

# Increase osd_max_scrubs to ensure the repair will start
ACTING=$(ceph pg $PG query | jq -r .acting[])
for OSD in $ACTING
do
   ceph config set osd.${OSD} osd_max_scrubs 3
done

# Scrub the PG and wait to ensure scrubbing starts
ceph pg deep-scrub $PG
sleep 10

# Revert osd_max_scrubs
for OSD in $ACTING
do
   ceph config rm osd.${OSD} osd_max_scrubs
done
ceph status
