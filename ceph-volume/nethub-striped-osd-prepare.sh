#!/bin/bash

# usage : ./nethub-striped-osd-prepare.sh /dev/sdX /dev/sdY osd-id

set -e

ceph-volume lvm zap $1 --destroy
ceph-volume lvm zap $2 --destroy
sleep 1
vgname=ceph-block-`uuid -v4`
lvname=osd-block-`uuid -v4`
vgcreate $vgname $1 $2
lvcreate -i 2 -l 100%FREE -n $lvname $vgname
ceph-volume lvm create --bluestore --data $vgname/$lvname --osd-id $3
