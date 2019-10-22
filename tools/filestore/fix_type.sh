#!/bin/bash

# Loop over FileStore OSDs
for J in /var/lib/ceph/osd/ceph-*/journal
do
  OSD_BASE="`dirname ${J}`"
  if [ ! -f ${OSD_BASE}/type ]
  then
    ID="`cat ${OSD_BASE}/whoami`"
    TYPE="`ceph osd metadata ${ID} | jq -r .osd_objectstore`"
    if [ "${TYPE}" != "filestore" ]
    then
      echo echo Error osd.{ID} is not expected filestore
      exit 1
    fi
    echo "echo filestore > ${OSD_BASE}/type"
  fi
done
