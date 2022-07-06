#!/bin/bash


set -e
set -x

kinit -k
roger update --appstate=intervention --message="Compacting OSDs"

ceph osd set noout
ceph osd set noin

killall ceph-osd

systemctl stop ceph-osd.target
sleep 10
for OSD in /var/lib/ceph/osd/ceph-*;
do
  ID=`cat ${OSD}/whoami`
  ceph-kvstore-tool bluestore-kv ${OSD} compact &> /var/log/ceph/compact.${ID}.log &
done
wait
systemctl start ceph-osd.target
sleep 60
ceph osd unset noout
ceph osd unset noin

roger update --appstate=production
