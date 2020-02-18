#!/bin/bash

ls -l $@ | awk '{ print $10 }' | \
while read d1; read d2; do
    ceph-volume lvm zap $d1 --destroy
    ceph-volume lvm zap $d2 --destroy
    sleep 1
    vgname=ceph-block-`uuid -v4`
    lvname=osd-block-`uuid -v4`
    vgcreate $vgname $d1 $d2
    lvcreate -i 2 -l 100%FREE -n $lvname $vgname
    ceph-volume lvm create --bluestore --data $vgname/$lvname
done
