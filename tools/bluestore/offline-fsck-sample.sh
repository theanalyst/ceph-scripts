#!/bin/bash

set -e
set -x

kinit -k
roger update --appstate=intervention --message="BlueStore FSCK OSDs"

ceph osd set noout
ceph osd set noin
for OSD in /var/lib/ceph/osd/ceph-*;
do
  ID=`cat ${OSD}/whoami`
  ceph osd ok-to-stop ${ID}
  systemctl stop ceph-osd@${ID}
  sleep 10
  ceph-bluestore-tool fsck --path $OSD 2>&1 | tee /var/log/ceph/fsck.${ID}.log
  sleep 5
  systemctl start ceph-osd@${ID}
  break
done
ceph osd unset noout
ceph osd unset noin

roger update --appstate=production
