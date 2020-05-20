#!/bin/bash

for OSD in /var/lib/ceph/osd/ceph-*;
do
  ID=`cat ${OSD}/whoami`
  ceph daemon osd.${ID} perf dump bluefs
done
