#!/bin/bash

set -e
set -x

ID=$1

ceph osd set noout
for OSD in /var/lib/ceph/osd/ceph-${ID};
do
  ID=`cat ${OSD}/whoami`
  ceph osd ok-to-stop ${ID}
  systemctl stop ceph-osd@${ID}
  sleep 10
  ceph-kvstore-tool bluestore-kv ${OSD} compact
  sleep 5
  systemctl start ceph-osd@${ID}
done
ceph osd unset noout
