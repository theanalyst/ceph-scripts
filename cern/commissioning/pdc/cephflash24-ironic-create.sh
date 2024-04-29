## 
# This is for the PDC Flash HW delivery in 2024, spring 
#
# See 
# dcrun32023 https://its.cern.ch/jira/browse/DCRUN32023-3121
# ceph-1484  https://its.cern.ch/jira/browse/CEPH-1484
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT Ceph Ironic";
export OS_REGION_NAME="pdc";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='cephflash24-'
#FLAVOR="p1.dl1060642.S775-C5-IP21"
#FLAVOR="p1.dl1060642.S775-C5-IP22"
#FLAVOR="p1.dl1060642.S775-C5-IP23"
#FLAVOR="p1.dl1060642.S775-C5-IP24"
#FLAVOR="p1.dl1060642.S775-C5-IP25"
FLAVOR="p1.dl1060642.S775-C5-IP26"
	
for i in {1..8}; do
	ai-bs     --landb-mainuser ceph-admins \
	          --landb-responsible ceph-admins \
	          --nova-flavor $FLAVOR \
	          --rhel9 \
	          --foreman-environment 'production' \
	          --foreman-hostgroup 'ceph/spare' \
	          --prefix $PREFIX
	done
