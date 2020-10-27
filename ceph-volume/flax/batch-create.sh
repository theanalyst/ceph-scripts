#!/bin/bash

ceph-volume lvm batch /dev/sdc
ceph-volume lvm batch /dev/sdd ... 16 hdds
ceph-volume lvm batch /dev/sde ... 16 hdds
ceph-volume lvm batch /dev/sdf ... 16 hdds
