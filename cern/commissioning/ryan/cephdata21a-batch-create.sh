#!/bin/bash

ceph-volume lvm batch /dev/sd[a-l] --db-devices /dev/sday
ceph-volume lvm batch /dev/sd[m-x] --db-devices /dev/sdaz
ceph-volume lvm batch /dev/sd[y-z] /dev/sda[a-j] --db-devices /dev/sdba
ceph-volume lvm batch /dev/sda[k-v] --db-devices /dev/sdbb
