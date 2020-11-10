#!/bin/bash

ceph-volume lvm batch /dev/sd[g-r] --block-dbs /dev/sdc
ceph-volume lvm batch /dev/sd[s-z] /dev/sda[a-d] --block-dbs /dev/sdd
ceph-volume lvm batch /dev/sda[d-p] --block-dbs /dev/sde
ceph-volume lvm batch /dev/sda[q-z] /dev/sdb[a-b] --block-dbs /dev/sdf
