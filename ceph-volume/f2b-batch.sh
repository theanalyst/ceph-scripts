#!/bin/bash

set -x

roger update --appstate intervention --message "Reformatting machines to Bluestore" --duration 2d `hostname -s`

ceph osd set noout
systemctl stop ceph-osd.target
while ((`pgrep ceph-osd | wc -l` > 0)); do
  sleep 1s
done
umount /var/lib/ceph/osd/ceph-*
rmdir /var/lib/ceph/osd/ceph-*
if ((`pvs | wc -l` > 0))
then
    yes | vgremove `vgs --no-headings | awk {print $1}`
    pvremove `pvs --no-headings | awk {print $1}`
fi

readarray -t OSD_IDS < <(ceph osd ls-tree `hostname -s`) 

HDDS=()
SSDS=()

for DEV in $(awk 'NR==FNR{a[$0];next} !($0 in a)' <(df | grep '/md' | cut -d' ' -f1 | xargs -i mdadm -v --detail --scan {} | grep -Po '/dev/sd[a-z]+' | sort -u) <(lsscsi | grep -Po '/dev/sd[a-z]+') | grep -Po 'sd[a-z]+')
do
    if ((`cat /sys/block/$DEV/queue/rotational` == 1))
    then
       HDDS+=($DEV)
    else
       SSDS+=($DEV)
    fi
done

BATCH_SIZE=$((${#HDDS[@]}/${#SSDS[@]}))

ceph osd ls-tree `hostname -s` | xargs -i ceph osd destroy {} --yes-i-really-mean-it

for i in ${!SSDS[@]}
do
    BATCH_DEVS=$(printf "/dev/%s\n" "${HDDS[@]:((i*BATCH_SIZE)):BATCH_SIZE}" "${SSDS[$i]}")
    xargs -i printf "( wipefs -a %s; ceph-volume lvm zap %s ) &\n" {} {} <<< "$BATCH_DEVS" | sh
    wait
    ceph-volume lvm batch --yes $BATCH_DEVS --osd-ids ${OSD_IDS[@]:((i*BATCH_SIZE)):BATCH_SIZE}
done

ceph osd unset noout
