#!/bin/bash

# Loop over FileStore OSDs
for J in /var/lib/ceph/osd/ceph-*/journal
do
  OSD_BASE="`dirname ${J}`"
  echo ceph-volume simple scan $OSD_BASE
done
