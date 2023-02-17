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

PREFIX='cephfs-testcs8-arm-'
FLAVOR='a1.small'
IMAGE='c6fe6547-af62-44ab-8840-4397ab15166e'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
	  --nova-image $IMAGE \
	  --nova-sshkey 'ebocchi_arm' \
          --foreman-environment 'qa' \
          --foreman-hostgroup 'ceph/test/cephfs' \
          --prefix $PREFIX
