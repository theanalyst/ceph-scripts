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

PREFIX='cephfs-testel9-'
FLAVOR='m2.medium'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --nova-image 5c5040cc-f04a-4abb-9689-f8dbe4e5a2ca \
          --foreman-environment 'qa' \
          --foreman-hostgroup 'ceph/test/cephfs' \
          --prefix $PREFIX
