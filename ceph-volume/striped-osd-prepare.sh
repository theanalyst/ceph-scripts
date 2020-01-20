#!/bin/bash

set -e

# Check if cephrocks VG exists
vgs cephrocks &> /dev/null && ROCKSDB=true || ROCKSDB=false

# minimum must be (256MiB+2560MiB+25600MiB+1GiB)=28.75GiB
# bigger than that doesn't help (except during compaction)
DBSIZE="29GiB"

ls -l $@ | awk '{ print $10 }' | \
while read d1; read d2; do
    ceph-volume lvm zap $d1 --destroy
    ceph-volume lvm zap $d2 --destroy
    sleep 1
#    pvremove $d1
#    pvremove $d2
    pvscan --cache
    sleep 1
    vgname=ceph-block-`uuid -v4`
    lvname=osd-block-`uuid -v4`
    dbname=osd-block-db-`uuid -v4`
    vgcreate $vgname $d1 $d2
    lvcreate -i 2 -l 100%FREE -n $lvname $vgname
    if $ROCKSDB; then
        lvcreate -L $DBSIZE -n $dbname cephrocks
        ceph-volume lvm create --bluestore --data $vgname/$lvname --block.db cephrocks/$dbname
    else
        ceph-volume lvm create --bluestore --data $vgname/$lvname
    fi
done
