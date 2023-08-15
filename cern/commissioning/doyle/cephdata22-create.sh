## 
# This is for the HW delivery in Spring 2022
#
# See
#   - CEPH-1368 (https://its.cern.ch/jira/browse/CEPH-1368)
#   - DCRUN32021-2320 (https://its.cern.ch/jira/browse/DCRUN32021-2320)
#
#
# ** WARNING **
# These machines came with the following fast devices:
#   [N:0:4:1]    disk    SAMSUNG MZ1LB3T8HMLA-00007__1              /dev/nvme0n1
#   [N:1:1:1]    disk    Micron_7300_MTFDHBE3T8TDF__1               /dev/nvme1n1
#   [N:2:1:1]    disk    Micron_7300_MTFDHBE3T8TDF__1               /dev/nvme2n1
#   [N:3:1:1]    disk    KCD6XLUL1T92__1                            /dev/nvme3n1
#   [N:4:1:1]    disk    KCD6XLUL1T92__1                            /dev/nvme4n1
#
# Just by instantiating the machine via Openstack Ironic, the /dev/nvme3n1 will
#   be used for the system disk as it is the first one in alphabetical order.
#
# We use root device hints to install the OS on /dev/nvme0n1
#   ```
#   'root_device': {'model': 'SAMSUNG MZ1LB3T8HMLA-00007'}}
#   ```
#
#
# Also, the hosts used by the doyle cluster were originally instantiated with CentOS Stream 8.
# To reinstall with RHEL 9 without killing the instance and re-creating:
#   eval $(ai-rc "IT Ceph Ironic")                                               
#   ai-foreman updatehost -e production -p 'Ceph (EFI,data22)' --operatingsystem "RHEL 9.2" -m RedHat $HOST
#   ai-installhost --mode=uefi $HOST                                             
#   openstack server reboot --hard $HOST  
#
# If this does not work due to IMPI errors or missing details,
# the only way out is kill + recreate. The original hostnames are:
#   CP18: cephdata22-b74752c595.cern.ch (LJUCY11)
#   CP19: cephdata22-a70d96b04f.cern.ch (LJUCY10)
#   CP21: cephdata22-b712f42a06.cern.ch (LJUCY10)
#   CP22: cephdata22-4af2dbd7d8.cern.ch (LJUCY12)
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

PREFIX='cephdata22-'
FLAVOR='p1.dl8822375.S513-C-IP200'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --rhel9 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX

