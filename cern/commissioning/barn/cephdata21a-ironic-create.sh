## 
# This is for the HW delivery in January 2021
#
# See CEPH-1043 (https://its.cern.ch/jira/browse/CEPH-1043)
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Ironic";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='cephdata21a-'
FLAVOR='p1.dl8330179.S513-A-IP250'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --c8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX
