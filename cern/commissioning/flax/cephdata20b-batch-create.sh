#!/bin/bash

ceph-volume lvm batch /dev/sd[g-z] /dev/sda[a-z] /dev/sdb[a-b] --db-devices /dev/sd[c-f]
