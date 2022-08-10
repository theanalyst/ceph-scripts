##
# This is to create the mons for the PCC PoC in a special Cloud region
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="Ceph PoC";
export OS_REGION_NAME="poc";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='cephpoc-mon-'
FLAVOR='m2.large'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --cs8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/poc/mon' \
          --prefix $PREFIX
