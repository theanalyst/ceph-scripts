#!/bin/bash

echo ceph osd set noout
echo ceph osd set noin
echo killall ceph-osd
echo systemctl stop ceph-osd.target
echo sleep 10
for OSD in /var/lib/ceph/osd/ceph-*;
do
  ID=`cat ${OSD}/whoami`
  echo "ceph-kvstore-tool bluestore-kv ${OSD} compact &> /var/log/ceph/compact.${ID}.log &"
done
echo wait
echo systemctl start ceph-osd.target
echo sleep 60
echo ceph osd unset noout
echo ceph osd unset noin
