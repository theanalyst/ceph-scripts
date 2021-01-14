#!/bin/bash

for PG in $(ceph pg ls inconsistent -f json | jq -r .pg_stats[].pgid)
do
   echo Checking inconsistent PG $PG
   if ceph pg ls repair | grep -wq ${PG}
   then
      echo PG $PG is already repairing, skipping
      continue
   fi

   # Increase osd_max_scrubs to ensure the repair will start
   ACTING=$(ceph pg $PG query | jq -r .acting[])
   for OSD in $ACTING
   do
      ceph config set osd.${OSD} osd_max_scrubs 3
   done

   ceph pg repair $PG

   sleep 10

   for OSD in $ACTING
   do
      ceph config rm osd.${OSD} osd_max_scrubs
   done

done
ceph status
