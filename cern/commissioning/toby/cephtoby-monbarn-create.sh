## 
# This is to create a tiebreaker mon in the Barn for the Toby cluster
#
#  Critical power is not a hardly needed, but the Barn is the only place
#  where there is equal network connectivity against Main Room, Vault, and 773
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Storage Service - Critical Area";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='cephtoby-mon-'
FLAVOR='m2.large'
RHEL_ID='68b56d3a-2910-4cdb-8bf5-28b358f9b865'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          -i $RHEL_ID \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/toby/mon' \
          --prefix $PREFIX
