#!/bin/bash

if [ $(facter -p hostgroup_1) != "miniflax" ]
then
   echo ERROR: this script runs only on miniflax cluster
   exit 1
fi

init () {
  mkdir -p /cephfs
  SECRET=$(ceph auth get-key client.admin)
  umount /cephfs
  mount -t ceph `hostname -s`:/ /cephfs -oname=admin,secret=${SECRET}
  mkdir -p /cephfs/stressfs
  cd /cephfs/stressfs
  echo init: done
}

loadgen () {
  i=0
  while true
  do
    f=$(uuid -v4)
    mkdir -p ${f::3}
    touch ${f::3}/${f}
    i=$((i+1))
    if [ "$(($i % 1000))" == "0" ]
    then
      echo loadgen: created $i files
    fi
  done
}

rand_maxmds () {
  while true
  do
    sleep $(shuf -i 180-360 -n 1)
    MAX=$(shuf -i 1-3 -n 1)
    echo rand_maxmds: setting max_mds $MAX
    ceph fs set cephfs max_mds $MAX
    echo rand_maxmds: done
  done
}

rand_export_pin () {
  setfattr -n ceph.dir.pin -v -1 /cephfs/stressfs
  while true
  do
    sleep $(shuf -i 300-600 -n 1)
    cd /cephfs/stressfs
    for DIR in `find . -mindepth 1 -maxdepth 1 -type d | sort`
    do
      PIN=$(shuf -i 0-2 -n 1)
      echo rand_export_pin: pinning $DIR to $PIN ...
      setfattr -n ceph.dir.pin -v $PIN $DIR
    done
  done
}

trim () {
  while true
  do
    sleep $(shuf -i 0-20 -n 1)
    echo trim: trimming files more than 120m old...
    find /cephfs/stressfs/ -type f -mmin +120 -delete &> /dev/null
    find /cephfs/stressfs/ -type d -empty -delete &> /dev/null
    echo trim: done
  done
}

stat () {
  while true
  do
    echo stat: long listing all files...
    ls -lR /cephfs/stressfs/ &> /dev/null
    echo stat: done
  done
}

init
loadgen &
trim &
stat &

RANK=$(ceph daemon mds.`hostname -s` status | jq -r .whoami)
if [ "$RANK" == "0" ]
then
  echo "I am rank 0. Running rand_maxmds rand_export_pin"
  rand_maxmds &
  rand_export_pin &
fi

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
wait