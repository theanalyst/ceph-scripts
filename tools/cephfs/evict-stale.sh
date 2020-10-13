#!/bin/bash

echo Enabling debug_ms=1 for 10s
ceph daemon mds.`hostname -s` config set debug_ms 1
sleep 10
ceph daemon mds.`hostname -s` config set debug_ms 0/1

echo Checking for Stale fh errors... If positive, re-run with --evict option.

STALE=$(grep Stale /var/log/ceph/ceph-mds.*.log | awk '{print $8}' | sort | uniq | cut -d: -f1 | xargs -n1 host | awk '{print $5}' | sort)

for s in ${STALE}
do
    S=${s::-1}
    SS=$(echo ${S} | sed 's/.cern.ch//')
    echo checking load_avg on ${S}
    ceph tell mds.* client ls client_metadata.hostname=${S} 2>/dev/null | grep request_load_avg
    echo checking load_avg on ${SS}
    ceph tell mds.* client ls client_metadata.hostname=${SS} 2>/dev/null | grep request_load_avg
#    echo evicting ${S}
#    ceph tell mds.* client evict client_metadata.hostname=${S} 2>/dev/null | grep request_load_avg
#    echo evicting ${SS}
#    ceph tell mds.* client evict client_metadata.hostname=${SS} 2>/dev/null | grep request_load_avg
done
