## 
# This is for the HW delivery in Spring 2022
#
# See 
#   - CEPH-1193 (https://its.cern.ch/jira/browse/CEPH-1193)
#   - DCRUN32021-2320 (https://its.cern.ch/jira/browse/DCRUN32021-2320)
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

PREFIX='cephnethub-data22-'
FLAVOR='p1.dl8822375.S773-C-IP200'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --cs8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX
