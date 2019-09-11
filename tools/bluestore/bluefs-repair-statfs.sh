#!/bin/bash

systemctl stop ceph-osd.target
sleep 10
killall ceph-osd # make sure all the osds have stopped
for osd in /var/lib/ceph/osd/ceph-*
do
  ceph-bluestore-tool repair --path ${osd} &
done
wait
systemctl start ceph-osd.target
