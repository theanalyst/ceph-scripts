#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Storage Service";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='cephfs-test8el-'
FLAVOR='m2.medium'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --nova-image f453ecdd-1428-4e5c-a776-b0779724ab76 \
          --foreman-environment 'qa' \
          --foreman-hostgroup 'ceph/test/cephfs' \
          --prefix $PREFIX
