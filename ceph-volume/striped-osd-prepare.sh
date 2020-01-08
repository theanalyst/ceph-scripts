#!/bin/bash

# Check if cephrocks VG exists
vgs cephrocks &> /dev/null && ROCKSDB=true || ROCKSDB=false

# minimum must be (256MiB+2560MiB+25600MiB+1GiB)=28.75GiB
# bigger than that doesn't help (except during compaction)
DBSIZE="29GiB"

ls -l $@ | awk '{ print $10 }' | \
while read d1; read d2; do
    echo ceph-volume lvm zap $d1
    echo ceph-volume lvm zap $d2
    vgname=ceph-block-`uuid -v4`
    lvname=osd-block-`uuid -v4`
    dbname=osd-block-db-`uuid -v4`
    echo vgcreate $vgname $d1 $d2
    echo lvcreate -i 2 -l 100%FREE -n $lvname $vgname
    if $ROCKSDB; then
        echo lvcreate -L $DBSIZE -n $dbname cephrocks
        echo ceph-volume lvm create --bluestore --data $vgname/$lvname --block.db cephrocks/$dbname
    else
        echo ceph-volume lvm create --bluestore --data $vgname/$lvname
    fi
done
