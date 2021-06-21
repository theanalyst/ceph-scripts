#!/bin/bash

KBAD='4.18.0-301.1.el8.x86_64 4.18.0-305.el8.x86_64 4.18.0-305.3.1.el8.x86_64'

for k in ${KBAD}
do
  echo "Found client(s) running buggy kernel ${k}:"
  ceph tell mds.0 client ls client_metadata.kernel_version=${k} 2>/dev/null | jq -r .[].client_metadata.hostname
  echo
done
