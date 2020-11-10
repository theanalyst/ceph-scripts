#!/bin/bash

ceph-volume lvm batch /dev/sdc /dev/sd[g-r]
ceph-volume lvm batch /dev/sdd /dev/sd[s-z] /dev/sda[a-d]
ceph-volume lvm batch /dev/sde /dev/sda[d-p]
ceph-volume lvm batch /dev/sdf /dev/sda[q-z] /dev/sdb[a-b]
