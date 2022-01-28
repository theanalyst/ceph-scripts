## 
# This is for the HW delivery in Summer 2021
#
# See 
#   - CEPH-1193 (https://its.cern.ch/jira/browse/CEPH-1193)
#   - CEPH-1206 (https://its.cern.ch/jira/browse/CEPH-1206)
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

PREFIX='cephnethub-data21-'
FLAVOR='p1.dl8642293.S773-C-IP180'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --cs8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX
