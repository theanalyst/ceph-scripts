## 
# This is to create VMs in the ARM project
#
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Storage Service - ARM";
export OS_REGION_NAME="cern";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

FLAVOR='a1.small'

## Alma 8
#PREFIX='cephfs-testal8-arm-'
#IMAGE='3be27fcc-3935-45eb-86c8-4ab8d65ea85f'

# Alma 9
PREFIX='cephfs-testal9-arm-'
IMAGE='be750991-9a66-461d-b6ba-8b0e1b56d5b7'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
	  --nova-image $IMAGE \
	  --nova-sshkey 'ebocchi_arm' \
          --foreman-environment 'qa' \
          --foreman-hostgroup 'ceph/test/cephfs/watchers' \
          --prefix $PREFIX
