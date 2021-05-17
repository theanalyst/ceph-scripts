#!/bin/bash

set -e
set -x

ceph balancer off
ceph pg ls | grep -q backfilling && exit

# If there are OSDs here, check that they are already drained.
OSDS=$(ceph osd crush ls `hostname -s`)
if [ "${OSDS}" ]
then
    ceph osd ok-to-stop ${OSDS}
    ceph osd safe-to-destroy ${OSDS}
    ceph osd out ${OSDS}
fi

# Stop Ceph daemons
systemctl stop ceph.target

# Wipe all disks and destroy all osds
for OSD in ${OSDS}
do
    ID=$(echo ${OSD} | cut -d. -f2)
    ceph-volume lvm zap --osd-id=${ID} --destroy
    ceph osd purge ${OSD}
done

# remove the host from crush
if [ "${OSDS}" ]
then
    ceph osd crush rm `hostname -s`
fi

# Destroy all secrets
umount -Af /var/lib/ceph/osd/* &> /dev/null || true
rm -rf /etc/ceph/ /var/lib/ceph/

echo `hostname -s` has been removed from the cluster. Now do:
echo "   " ai-foreman updatehost -c ceph/decommissioning `hostname -s`
echo "   " roger update --all_alarms=false `hostname -s`
echo then run puppet. Next:
echo "   " ai-disownhost `hostname -s`
echo then run puppet one final time.
