#!/bin/bash

ceph-volume lvm batch /dev/sd[g-z] /dev/sda[a-d] --db-devices /dev/sd[c-f]
