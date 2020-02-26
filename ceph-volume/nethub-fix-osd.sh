#!/bin/bash 

#!/bin/bash

OSDS=`lvs -o +devices,tags | grep -E "/dev/sdd\(0\)|/dev/sdaa" | grep -Eo "osd_id=[0-9]+," | cut -d = -f 2 | tr -d "\n" | sed -e 's/,/ /g'`;

# Zap osds

for OSD in $OSDS; 
do
    echo "ceph-volume lvm zap --destroy --osd-id $OSD";
done

echo "./nethub-striped-osd-prepare.sh /dev/sdd  /dev/sdaa `echo $OSDS | cut -d ' '  -f 1`"
echo "./nethub-striped-osd-prepare.sh /dev/sdab /dev/sday `echo $OSDS | cut -d ' '  -f 2`"

