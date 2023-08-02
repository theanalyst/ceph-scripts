## 
# This is to create a VM to test krbd
#
##

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

PREFIX='cephkrbd-test8al-'
FLAVOR='m2.small'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
	  --nova-flavor $FLAVOR \
	  --cs8 \
	  --nova-sshkey 'ebocchi' \
          --foreman-environment 'qa' \
          --foreman-hostgroup 'ceph/test/krbd' \
          --prefix $PREFIX
