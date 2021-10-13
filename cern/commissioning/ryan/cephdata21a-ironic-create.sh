## 
# This is for the HW delivery in January 2021
#
# See:
#  - CEPH-1043 (https://its.cern.ch/jira/browse/CEPH-1043)
#  - CEPH-1230 (https://its.cern.ch/jira/browse/CEPH-1230)
#
# Once created, ai-install with software raid1 on system disk
#    eval $(ai-rc "IT Ceph Ironic")
#    ai-foreman updatehost -e production -p 'Ceph (EFI,SSD+JBOD)' -o 'CentOS Stream 8' -m CentOSStream8 $HOST
#    ai-installhost --mode=uefi $HOST
#    openstack server reboot --hard $HOST
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
FLAVOR='p1.dl8330179.S513-C-IP501'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --c8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX
