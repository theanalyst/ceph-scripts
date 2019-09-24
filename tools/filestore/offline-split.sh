#!/bin/bash

echo killall ceph-osd
echo systemctl stop ceph-osd.target
echo sleep 10
DIRS=`mount | grep ceph | grep xfs | awk '{print $3}'`
while (( "$#" )); do
  POOL=$1
  for OSD in ${DIRS};
  do
    ID=`cat ${OSD}/whoami`
    echo "sudo -H -u ceph bash -c 'ceph-objectstore-tool --debug --type=filestore --data-path ${OSD} --op apply-layout-settings --pool ${POOL} ' &> /var/log/ceph/offline-split.${ID}.${POOL}.log &"
  done
  echo wait
  shift
done
echo systemctl start ceph-osd.target
