## 
# This is for the HW delivery in Autumn 2021
#
# See 
#   - CEPH-1226 (https://its.cern.ch/jira/browse/CEPH-1226)
#   - DCRUN32021-892 (https://its.cern.ch/jira/browse/DCRUN32021-892)
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

PREFIX='cephdata21b-'
FLAVOR='p1.dl8642293.S513-C-IP152'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --c8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX
