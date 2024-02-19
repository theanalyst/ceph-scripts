## 
# This is for NVMe HW delivery in February 2024
#
# See
#   - CEPH-1462 (https://its.cern.ch/jira/browse/CEPH-1462)
#   - DCRUN32023-3124 (https://its.cern.ch/jira/browse/DCRUN32023-3124)
#
#
# ** WARNING **
# These machines came with the following devices:
#   [N:0:6:1]    disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme0n1
#   [N:1:6:1]    disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme1n1
#   [N:2:6:1]    disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme2n1
#   [N:3:6:1]    disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme3n1
#   [N:4:4:1]    disk    SAMSUNG MZ1LB1T9HALS-00007__1              /dev/nvme4n1
#   [N:5:6:1]    disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme5n1
#   [N:6:6:1]    disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme6n1
#   [N:7:6:1]    disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme7n1
#   [N:8:6:1]    disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme8n1
#   [N:9:6:1]    disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme9n1
#   [N:10:6:1]   disk    SAMSUNG MZQL27T6HBLA-00A07__1              /dev/nvme10n1
#
# We use root device hints to install the OS on /dev/nvme4n1
#   ```
#   'root_device': {'model': 'SAMSUNG MZ1LB1T9HALS-00007'}}
#   ```
#
#### # Also, if there is a need to reinstall with a different OS, proceed as follows:
#### # To reinstall with RHEL 9 without killing the instance and re-creating:
#### #   eval $(ai-rc "IT Ceph Ironic")
#### #   ai-foreman updatehost -e production -p 'Ceph (EFI,data22)' --operatingsystem "RHEL 9.2" -m RedHatCERN $HOST
#### #   ai-installhost --mode=uefi $HOST
#### #   openstack server reboot --hard $HOST
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

PREFIX='cephflash24-'
# FLAVOR='p1.dl1060737.S513-A-IP119' # Barn, BA04, 2 nodes
# FLAVOR='p1.dl1060737.S513-A-IP121' # Barn, BA05, 2 nodes
# FLAVOR='p1.dl1060737.S513-A-IP122' # Barn, BA07, 2 nodes
FLAVOR='p1.dl1060737.S513-C-IP200' # Main Room, 16 nodes


ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --rhel9 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX

