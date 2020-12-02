#!/bin/bash

ceph-volume lvm batch /dev/sd[g-r] --db-devices /dev/sdc
ceph-volume lvm batch /dev/sd[s-z] /dev/sda[a-d] --db-devices /dev/sdd
ceph-volume lvm batch /dev/sda[d-p] --db-devices /dev/sde
ceph-volume lvm batch /dev/sda[q-z] /dev/sdb[a-b] --db-devices /dev/sdf
