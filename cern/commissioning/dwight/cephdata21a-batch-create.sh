#!/bin/bash

ceph-volume lvm batch /dev/sd[a-z] /dev/sda[a-v] --db-devices /dev/sda[y-z] /dev/sdb[a-b]
