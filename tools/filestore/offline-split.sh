#!/bin/bash

echo killall ceph-osd
echo systemctl stop ceph-osd.target
echo sleep 10
DIRS=`mount | grep ceph | grep xfs | awk '{print $3}'`
for OSD in ${DIRS};
do
  ID=`cat ${OSD}/whoami`
  echo "sudo -H -u ceph bash -c 'ceph-objectstore-tool --debug --type=filestore --data-path ${OSD} --op apply-layout-settings --pool volumes' &> /var/log/ceph/offline-split.${ID}.volumes.log &"
done
echo wait
for OSD in ${DIRS};
do
  ID=`cat ${OSD}/whoami`
  echo "sudo -H -u ceph bash -c 'ceph-objectstore-tool --debug --type=filestore --data-path ${OSD} --op apply-layout-settings --pool images' &> /var/log/ceph/offline-split.${ID}.images.log &"
done
echo wait
echo systemctl start ceph-osd.target
