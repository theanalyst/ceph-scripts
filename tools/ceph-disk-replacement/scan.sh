#! /bin/bash


journals=`blkid | grep journal | grep -v xfs | grep -v LVM | grep -v | awk 'BEGIN {FS="="} {print $3}' | tr -d "\""`


for line in $journals; do
    if [ `grep $line /var/lib/ceph/osd/ceph-*/journal_uuid | wc -l` -eq 0 ]; then
        if [ `lvs -odevices,tags | grep $line | wc -l` -eq 0 ]; then
            blkid | grep $line | sed -e 's/:.*$//'
        fi
    fi
done

