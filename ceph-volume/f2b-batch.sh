#!/bin/bash

set -x
set -e

kinit -k
roger update --appstate intervention --message "Reformatting machines to Bluestore" --duration 2d `hostname -s`

readarray -t OSD_IDS < <(ceph osd ls-tree `hostname -s`)

if [[ `ceph osd ok-to-stop ${OSD_IDS[@]} &> /dev/null` -ne 0 ]];
then
  echo "not okay to stop. abort."
  exit -1
fi

ceph osd set noout
ceph osd set norebalance

systemctl stop ceph-osd.target
while ((`pgrep ceph-osd | wc -l` > 0)); do
  sleep 1s
done

set +e
umount /var/lib/ceph/osd/ceph-*
rmdir /var/lib/ceph/osd/ceph-*
set -e

if ((`pvs | wc -l` > 0))
then
    if ((`vgs | wc -l` > 0))
    then
        yes | vgremove `vgs --no-headings | awk '{print $1}'`
    fi
    pvremove `pvs --no-headings | awk '{print $1}'`
fi

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
    # if all osds on this are bluestore already, skip this ssd
    if ((`pvs | grep ${SSDS[$i]} | wc -l` > 0))
    then
        continue
    fi
    BATCH_DEVS=$(printf "/dev/%s\n" "${HDDS[@]:((i*BATCH_SIZE)):BATCH_SIZE}" "${SSDS[$i]}")
    xargs -i printf "( wipefs -a %s; sleep 1; partprobe %s; sleep 1; ceph-volume lvm zap %s --destroy ) &\n" {} {} <<< "$BATCH_DEVS" | sh
    wait
    partprobe
    sleep 10s
    ceph-volume lvm batch --yes $BATCH_DEVS --osd-ids ${OSD_IDS[@]:((i*BATCH_SIZE)):BATCH_SIZE}
done

/root/ceph-scripts/tools/upmap/upmap-remapped.py | sh -x
/root/ceph-scripts/tools/upmap/upmap-remapped.py | sh -x
ceph osd unset norebalance
ceph osd unset noout
