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

PREFIX='cephfs-test9al-'
FLAVOR='m2.medium'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --nova-image 168d97d6-52b7-475d-8fa4-8fb32e35a31b \
          --foreman-environment 'qa' \
          --foreman-hostgroup 'ceph/test/cephfs' \
          --prefix $PREFIX
