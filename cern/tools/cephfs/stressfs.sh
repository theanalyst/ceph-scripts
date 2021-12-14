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
    mkdir -p ${f::2}
    touch ${f::2}/${f}
    i=$((i+1))
    if [ "$(($i % 1000))" == "0" ]
    then
      echo loadgen: created $i files
    fi
  done
}

toggle_maxmds () {
  while true
  do
    sleep $(shuf -i 30-60 -n 1)
    MAXMDS=$(ceph fs dump -f json 2>/dev/null | jq -r .filesystems[0].mdsmap.max_mds)
    if [ "${MAXMDS}" == "1" ]
    then
      echo toggle_maxmds: setting max_mds 2
      ceph fs set cephfs max_mds 2
    else
      echo toggle_maxmds: setting max_mds 1
      ceph fs set cephfs max_mds 1
    fi
    echo toggle_maxmds: done
  done
}

rand_export_pin () {
  while true
  do
    sleep $(shuf -i 30-60 -n 1)
    PIN=$(shuf -i 0-1 -n 1)
    echo rand_export_pin: pinning to $PIN ...
    setfattr -n ceph.dir.pin -v $PIN /cephfs/stressfs
    echo rand_export_pin: pinned to $PIN
  done
}

trim () {
  while true
  do
    sleep $(shuf -i 0-20 -n 1)
    echo trim: trimming files more than 5m old...
    find /cephfs/stressfs/ -type f -mmin +5 -delete
    echo trim: done
  done
}

stat () {
  while true
  do
    echo stat: walking all files...
    find /cephfs/stressfs/ &> /dev/null
    echo stat: done
  done
}

init
loadgen &
toggle_maxmds &
rand_export_pin &
trim &
stat &

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT
wait
