#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Kapoor";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='cephkapoor-mon-'
FLAVOR='m2.xlarge'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --rhel8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/kapoor/mon' \
          --prefix $PREFIX
