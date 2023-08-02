## 
# This is for the HW delivery in February 2023
#
# See
#   - CEPH-1426 (https://its.cern.ch/jira/browse/CEPH-1426)
#   - DCRUN32023-5 (https://its.cern.ch/jira/browse/DCRUN32023-5)
#
#
# ** WARNING **
# These machines came with the following fast devices:
#   [N:0:4:1]    disk    SAMSUNG MZ1LB960HAJQ-00007__1              /dev/nvme0n1
#   [N:1:1:1]    disk    Micron_7300_MTFDHBE1T9TDF__1               /dev/nvme1n1
#   [N:2:1:1]    disk    Micron_7300_MTFDHBE1T9TDF__1               /dev/nvme2n1
#   [N:3:1:1]    disk    Micron_7300_MTFDHBE3T8TDF__1               /dev/nvme3n1
#   [N:4:1:1]    disk    Micron_7300_MTFDHBE3T8TDF__1               /dev/nvme4n1
#
# We use root device hints to install the OS on /dev/nvme0n1
#   ```
#   'root_device': {'model': 'SAMSUNG MZ1LB3T8HMLA-00007'}}
#   ```
#
# Also, if there is a need to reinstall with a different OS, proceed as follows:
# To reinstall with RHEL 9 without killing the instance and re-creating:
#   eval $(ai-rc "IT Ceph Ironic")
#   ai-foreman updatehost -e production -p 'Ceph (EFI,data22)' --operatingsystem "RHEL 9.2" -m RedHatCERN $HOST
#   ai-installhost --mode=uefi $HOST
#   openstack server reboot --hard $HOST
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

PREFIX='cephdata23-'
FLAVOR='p1.dl9262714.S513-C-IP839'  # We have 4 of these
FLAVOR='p1.dl9262616.S513-C-IP839'  # and 8 of these
FLAVOR='p1.dl9262616.S513-C-IP840'  # and other 12 of these

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --rhel9 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX
