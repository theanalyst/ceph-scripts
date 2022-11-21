#!/bin/bash

DEFAULT_TENANT="IT Ceph Ironic"
CLUSTERS="barn beesly cta dwight flax gabe jim kelly kopano levinson meredith nethub pam ryan stanleymeyrin stanleynethub toby vault spare"
OUTPUT_FOLDER='ipmi_credentials'

CLUSTERS="spare"

echo "Retrieving credentials..."
for cluster in $CLUSTERS
do
  mkdir -p $OUTPUT_FOLDER/$cluster

  # Build the list of hosts
  hosts=$(mco find -T ceph -F hostgroup_1=$cluster --dt=3 | sed 's/.cern.ch//' | sort)
  for host in $hosts
  do
    echo "  $cluster: $host"

    # If we have a "cern_os_tenant" field, this is an Ironic box (or a VM) living in that OS tenant
    cern_os_tenant=$(ai-dump $host --json 2>/dev/null | jq -r .[].cern_os_tenant)
    if [ x"$cern_os_tenant" != x"null" ];
    then
      OS_PROJECT_NAME="$cern_os_tenant" openstack console url show $host -f json > $OUTPUT_FOLDER/$cluster/$host.json 2>/dev/null

    # Else, we cannot reliably tell if ironic-managed or not
    #   Example:
    #   $ ai-dump p05798818v47100,            Project: (Not Ironic-provisioned)
    #   $ ai-dump cephdata21a-44a12ccb13,     Project: (Ironic-provisioned host but no OS metadata available)
    # They both return null if piping to jq
    else
      ai-ipmi get-creds $host 2>/dev/null > $OUTPUT_FOLDER/$cluster/$host
      if [ $? -ne 0 ];
      then
        rm -f $OUTPUT_FOLDER/$cluster/$host
        OS_PROJECT_NAME="$DEFAULT_TENANT" openstack console url show $host -f json > $OUTPUT_FOLDER/$cluster/$host.json 2>/dev/null       
      fi
    fi
    ## tellme show --hostname $host root > $OUTPUT_FOLDER/$cluster/$host.rootpwd
  done
done
