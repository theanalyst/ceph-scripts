#! /bin/bash


journals=`blkid | grep journal | awk 'BEGIN {FS="="} {print $3}' | tr -d "\""`


for line in $journals; do
    if [ `grep $line /var/lib/ceph/osd/ceph-*/journal_uuid | wc -l` -eq 0 ]; then
        if [ `lvs -odevices,tags | grep $line | wc -l` -eq 0 ]; then
            echo $line
        fi
    fi
done

