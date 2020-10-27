#!/bin/bash

# use the first (of four) ssds as an osd
ceph-volume lvm batch /dev/sdc

# use the remaining 3 ssds as block.db for the 48 hdds
ceph-volume lvm batch /dev/sdd /dev/sd[g-v]
ceph-volume lvm batch /dev/sde /dev/sd[w-z] /dev/sda[a-l]
ceph-volume lvm batch /dev/sdf /dev/sda[m-z] /dev/sdb[a-b]
