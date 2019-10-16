#!/bin/bash

fix_bluestore_stats() {
    local DIR=$1
    local OSD=`cut -d- -f2 <<< $DIR`

    systemctl stop ceph-osd@$OSD

    local counter=10
    while ((counter>0)); do
        sleep 3s;
        if ! pgrep -f "ceph-osd.*--id $OSD\b" &> /dev/null; then
            break
        fi
        ((counter--))
    done
    if ((counter==0)); then
        echo "osd $OSD can't stop to fix bluestore stats, killing..."
        kill -9 `pgrep -f "ceph-osd.*--id $OSD\b"`
        sleep 3s
    fi
    ceph-bluestore-tool repair --path /var/lib/ceph/osd/$DIR
    systemctl start ceph-osd@$OSD
}
export -f fix_bluestore_stats

ls /var/lib/ceph/osd | xargs -i -P3 sh -c 'fix_bluestore_stats {}'
