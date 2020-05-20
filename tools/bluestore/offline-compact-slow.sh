#!/bin/bash

set -e
set -x

roger update --appstate=intervention --message="Compacting OSDs"

ceph osd set noout
ceph osd set noin
for OSD in /var/lib/ceph/osd/ceph-*;
do
  ID=`cat ${OSD}/whoami`
  ceph osd ok-to-stop ${ID}
  systemctl stop ceph-osd@${ID}
  sleep 10
  ceph-kvstore-tool bluestore-kv ${OSD} compact &> /var/log/ceph/compact.${ID}.log
  sleep 5
  systemctl start ceph-osd@${ID}
done
ceph osd unset noout
ceph osd unset noin

roger update --appstate=production
