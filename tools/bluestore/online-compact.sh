#!/bin/bash

for OSD in /var/lib/ceph/osd/ceph-*;
do
  ID=`cat ${OSD}/whoami`
  echo ceph daemon osd.${ID} compact
done
