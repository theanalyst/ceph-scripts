#!/bin/bash

set -e

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

# Destroy all secrets, disable puppet
puppet agent --disable "HW Decommissioning"
rm -rf /etc/ceph/ /var/lib/ceph/
