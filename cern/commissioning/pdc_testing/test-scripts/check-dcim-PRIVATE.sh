#!/bin/bash 
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

HOSTS=$(openstack server list | awk '{print $4}' | grep 'ceph' | xargs)
TOTAL=0
uname='<USER-ID>'
api_key='<DCIM-REST-API-KEY>'

for host in $HOSTS; do
	TOTAL=$(($TOTAL+1))
        mem=$(ssh root@"$host" "grep MemTotal /proc/meminfo | awk '{print \$2}'")
        memgb=$(echo "$mem*10^(-06)" | bc -l)
	
	dump_rack=$(ai-dump $host | grep -E 'LanDB|Flavour')
	
	dcim_ram=$(curl -s -H UserID:$uname -H APIKey:$api_key -H 'Content-Type: application/json' \
		-X GET "https://opendcim.cern.ch/api/keyauth_v1/device?PrimaryIP=$host.cern.ch" \
		| jq '.device[] |  "\(.RAM)"')
	
	dcim_fqdn=$(curl -s -H UserID:$uname -H APIKey:$api_key  -H 'Content-Type: application/json' \
	        -X GET "https://opendcim.cern.ch/api/keyauth_v1/device?PrimaryIP=$host.cern.ch" \
		| jq '.device[] | "\(.PrimaryIP)"')
	
	dcim_cabinet_id=$(curl -s  -H UserID:$uname -H APIKey:$api_key  -H 'Content-Type: application/json' \
	        -X GET "https://opendcim.cern.ch/api/keyauth_v1/device?PrimaryIP=$host.cern.ch" \
		| jq '.device[] | "\(.Cabinet)"' | tr -d '"')
	
	dcim_cabinet=$(curl -s -H UserID:$uname -H APIKey:$api_key -H 'Content-Type: application/json' \
	        -X GET "https://opendcim.cern.ch/api/keyauth_v1/cabinet?CabinetID=$dcim_cabinet_id" | jq .cabinet[].Location)

        dcim_cabinet_rack=$(curl -s -H UserID:$uname -H APIKey:$api_key  -H 'Content-Type: application/json' \
                -X GET "https://opendcim.cern.ch/api/keyauth_v1/device?PrimaryIP=$host.cern.ch" \
                | jq '.device[] | "\(.Position)"' | tr -d '"')
        
	echo $host $dcim_fqdn
	echo "KB:$mem GB:$memgb DCIM:$dcim_ram"
	echo "$dump_rack"     
	echo "DCIM-CABINET:$dcim_cabinet DCIM-RACK:$dcim_cabinet_rack"
	echo ""
	echo ""

done
echo "$TOTAL hosts"~                                                                                                                                                                                                                                             
