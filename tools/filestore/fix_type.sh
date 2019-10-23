#!/bin/bash

# exit if no filestore osds running
if [ `ls -1 /var/lib/ceph/osd/ceph-*/journal 2>/dev/null | wc -l ` -lt 1 ]
then
  exit
fi

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
