#!/bin/bash

for OSD in /var/lib/ceph/osd/ceph-*/whoami;
do
  ID=`cat ${OSD}`
  echo ceph daemon osd.${ID} compact
  echo ceph daemon osd.${ID} compact
done
