## 
# This is for the HW delivery in January 2023
# See https://its.cern.ch/jira/browse/DCRUN32021-2325
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

PREFIX='cephflash22-'
FLAVOR='p1.dl8868181.S513-A-IP120' # BA03
FLAVOR='p1.dl8868181.S513-A-IP121' # BA05
FLAVOR='p1.dl8868181.S513-A-IP122' # BA07
FLAVOR='p1.dl8868181.S513-A-IP119' # BA04

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
	  --rhel8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX

