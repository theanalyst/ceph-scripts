## 
# This is for the Ceph quads recommissioned for the IT-CS-NE Network Lab
#
# See:
#   - RQF2068297: Recommissioning of 2 quads for the Network lab
#   - RQF2096819: Request for shared Cloud Service Project - name: IT-CS-NE-DC-NETWORK-LAB - Physical
#   - RQF2097817: Request change of resource quota for the Cloud Project IT-CS-NE-DC-NETWORK-LAB - Physical
#   - RQF2003193: "ceph" quad for IT/CS network lab
#   - RQF2167637: Quota change following new flavor
#
# Following the installation, we need to re-install to host to use only /dev/sda as system disk.
#   - This is due to the fact we are using batch nodes, which have only 2 disks
#   - We abuse of 'Ceph HWRaid System', which uses /dev/sda only
#   ``` 
#   ai-foreman updatehost -p 'Ceph HWRaid System' -o 'CentOS Stream 8' -m CentOSStream <hostname>
#   ai-installhost <hostname>
#   ``` 
#
##

#!/bin/bash -x

unset OS_PROJECT_ID;
unset OS_TENANT_ID;
unset OS_TENANT_NAME;
export OS_PROJECT_NAME="IT-CS-NE-DC-NETWORK-LAB - Physical";

openstack server list  > /dev/null 2>&1
if [ $? != "0" ] ; then
  echo "openstack server list not working"
  exit
fi

PREFIX='cephcslab-'
FLAVOR='p1.cd6428773.S513-C-IP997'

ai-bs     --landb-mainuser ceph-admins \
          --landb-responsible ceph-admins \
          --nova-flavor $FLAVOR \
          --cs8 \
          --foreman-environment 'production' \
          --foreman-hostgroup 'ceph/spare' \
          --prefix $PREFIX
