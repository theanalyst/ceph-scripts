#!/bin/bash

set -x

if ((`pgrep ceph-osd | wc -l` == 20))
then
    if ((`lsscsi | grep -i 'intel.*/dev/sd[c-f]' | wc -l` == 4)) &&
       ((`lsscsi | grep -i 'hgst.*hms5.*/dev/sd[g-z]' | wc -l` == 20))
    then
      ceph osd set noout
      systemctl stop ceph-osd.target
      while ((`pgrep ceph-osd | wc -l` > 0)); do
        sleep 1s
      done
      umount /var/lib/ceph/osd/ceph-*
      rmdir /var/lib/ceph/osd/ceph-*
      yes | vgremove `vgs --no-headings | awk '{print $1}'`
      pvremove `pvs --no-headings | awk '{print $1}'`

      ceph osd ls-tree `hostname -s` > /tmp/osd-ids
      cat /tmp/osd-ids | xargs -i ceph osd destroy {} --yes-i-really-mean-it

      i=0
      for DEV in /dev/sd[c-z]; do
        ( wipefs -a $DEV; ceph-volume lvm zap $DEV ) &
        ((i++))
        if ((i%5==0)); then wait; fi
      done
      wait
      ceph-volume lvm batch --yes /dev/sdc /dev/sd[g-k] --osd-ids `sed -n '1,5p'   /tmp/osd-ids`
      ceph-volume lvm batch --yes /dev/sdd /dev/sd[l-p] --osd-ids `sed -n '6,10p'  /tmp/osd-ids`
      ceph-volume lvm batch --yes /dev/sde /dev/sd[q-u] --osd-ids `sed -n '11,15p' /tmp/osd-ids`
      ceph-volume lvm batch --yes /dev/sdf /dev/sd[v-z] --osd-ids `sed -n '16,20p' /tmp/osd-ids`
      ceph osd unset noout
    fi
fi
