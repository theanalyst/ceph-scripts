#! /bin/bash


#
# Usage: ./convert=accounting-file.sh <input file> 
#   - input_file: outout file generated by ./get-s3-accounting.sh
#


cat data.s3.json | jq -c .data | jq -c '.[]' | head -n 3 | while read -r line; 

do
  #resolve chargegroup/role
  dataowner=`echo $line | jq -r .owner`
  accrecdata=`curl -s -XGET https://accounting-receiver.cern.ch/v2/$dataowner`
  charge_group=`echo $accrecdata | jq .[].charge_group -r`
  echo "$line" | jq --arg DATE `date "+%d-%m-%Y"` --arg CHARGEGRP "$charge_group" -c '. | { name: .display_name, DiskUsage: .usage, DiskQuota: .quota, Date: $DATE, Owner: .owner, ChargeGroup: $CHARGEGRP, ChargeRole: "string", WallClockHours: 0, CPUHours: 0, FE: "S3 Object Storage" }'
done




