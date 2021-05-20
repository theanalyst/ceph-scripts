#! /bin/bash
#
# usage: ./get-s3-accounting.sh
#

DATE=`date '+%F'`
THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Thanks to https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel

SUBDIR="s3accounting-$DATE"

USERS_OPENSTACK="$SUBDIR/s3accounting-$DATE-users-openstack.log"
USERS_RADOSGW="$SUBDIR/s3accounting-$DATE-users-radosgw.log"
USERS_LOCAL="$SUBDIR/s3accounting-$DATE-users-local.log"
QUOTA_LOCAL="$SUBDIR/s3accounting-$DATE-quota-local.log"
QUOTA_OPENSTACK="$SUBDIR/s3accounting-$DATE-quota-openstack.log"
ACCOUNTING_LOCAL="$SUBDIR/s3accounting-$DATE-accounting-local.log"
ACCOUNTING_OPENSTACK="$SUBDIR/s3accounting-$DATE-accounting-openstack.log"
ACCOUNTING_ALL="$SUBDIR/s3accounting-$DATE-accounting-all.log"
REPORTING_LOCAL_GSS="$SUBDIR/s3accounting-$DATE-reporting-local-gss.json"
REPORTING_OPENSTACK_GSS="$SUBDIR/s3accounting-$DATE-reporting-openstack-gss.json"
REPORTING_ALL_GSS="$SUBDIR/s3accounting-$DATE-reporting-all-gss.json"
REPORTING_CENTRAL="$SUBDIR/s3accounting-$DATE-reporting-central.json"

MAPPING_LOCAL_S3="s3://s3-accounting-files/local_rgw_users/mapping-2021-05-05"
MAPPING_LOCAL_FILE="$SUBDIR/s3accounting-$DATE-mapping-local_rgw_users.json"
MAPPING_OPENSTACK_GAR="https://gar.cern.ch/public/list_full"
MAPPING_OPENSTACK_FILE="$SUBDIR/s3accounting-$DATE-mapping-openstack.json"

TARGET_ACCOUNTING_GSS="/eos/project/f/fdo/www/accounting/data.s3.json"
TARGET_ACCOUNTING_CENTRAL="https://accounting-receiver.cern.ch/v3/fe"
# Development and testing endpoint
# TARGET_ACCOUNTING_CENTRAL="https://acc-receiver-dev.cern.ch/v3/fe"

ARCHIVE="s3accounting-$DATE.tar.gz"
ARCHIVE_S3="s3://s3-accounting-files/data/$ARCHIVE"


###
### -send_to_accounting_receiver-
### Function to send JSON file for central reporting to accounting receiver
###
send_to_accounting_receiver () {
  JSON="$1"

  #curl --silent \
   curl \
    -H "Content-Type: application/json" \
    -H "API-key:$(cat /afs/cern.ch/project/ceph/private/s3-accounting.key)" \
    -d "@$JSON"  \
    -X POST \
    $TARGET_ACCOUNTING_CENTRAL
}



###
### -create_json_for_gss_reporting-
### Function to create a file good for GSS reporting using the accounting file as source
###
create_json_for_gss_reporting () {
  INPUT="$1"
  OUTPUT="$2"

  ## Generate JSON file to ship to eos
  echo -n "" > $OUTPUT
  
  # Scope JSON content into "data" key
  echo -n "{\"data\": [" >> $OUTPUT
  
  # Crunch the accounting file and convert relevant fields to JSON
  while read -r line; 
  do
    name=$(echo $line | grep -Eo "^.*\(" | tr -d '(' | sed 's/ *$//g')
    uid=$(echo $line | grep -Eo "\(.*\):" | tr -d '():')
    data=$(echo $line | cut -d ':' -f 2-)
  
    # Create JSON entry for each known project/user on S3
    echo -n "{" >> $OUTPUT
    echo -n "\"display_name\": \"$name\"," >> $OUTPUT
    echo -n "\"uid\": \"$uid\","  >> $OUTPUT
    echo -n $data | tr -d "," | awk '{ printf \
      "\"quota\":\""$1"\","\
      "\"quota_raw\":"$12","\
      "\"usage\":\""$3"\"," \
      "\"usage_raw\":"$14"," \
      "\"usage_human\":"$5"," \
      "\"num_bucket\":"$8"," \
      "\"num_objects\":"$10"," \
      }' >> $OUTPUT
  
    charge_group=$(echo $data | cut -d ',' -f 8 | sed 's/ chargegroup: //')
    charge_role=$(echo $data | cut -d ',' -f 9 | sed 's/ chargerole: //')
    echo -n "\"charge_group\":\""$charge_group"\"," >> $OUTPUT
    echo -n "\"charge_role\":\""$charge_role"\"," >> $OUTPUT
  
    owner=$(echo $data | cut -d ',' -f 10 | sed 's/ //' )
    email=$(echo $data | cut -d ',' -f 11 | sed 's/ //')
    echo -n "\"owner\":\""$owner"\"," >> $OUTPUT
    echo -n "\"mail\":\""$email"\"," >> $OUTPUT
  
    echo -n "\"division\":\"\"," >> $OUTPUT
    echo -n "\"group\":\"\"," >> $OUTPUT
    echo -n "\"section\":\"\"," >> $OUTPUT
  
    echo -n "\"FE\":\"S3 Object Storage\"," >> $OUTPUT
    echo -n "\"date\":\"`date -d "yesterday" '+%F'`\"" >> $OUTPUT
    echo -n "}," >> $OUTPUT
  done < $INPUT
  
  # Close JSON properly
  echo -n "{}]}" >> $OUTPUT
  
  # Trim empty elements in list
  sed -e 's/,{}]/]/' -i $OUTPUT
}

### Set the environment variables to have access to the OpenStack APIs
#   Alternatively, use a `clouds.yaml file`
#   Docs: https://docs.openstack.org/python-openstackclient/pike/configuration/index.html
#export OS_CLOUD=cern
export OS_AUTH_TYPE=v3fedkerb
export OS_AUTH_URL=https://keystone.cern.ch/v3
export OS_IDENTITY_API_VERSION=3
export OS_IDENTITY_PROVIDER=sssd
export OS_MUTUAL_AUTH=disabled
export OS_PROJECT_DOMAIN_ID=default
export OS_PROJECT_NAME=services
export OS_PROTOCOL=kerberos
export OS_REGION_NAME=cern
# export OS_VOLUME_API_VERSION=2



### Create subdir for temporary working files
mkdir $SUBDIR



### Fetch the list of users and their quotas

## Radosgw local users
#   Get the list of all known users by radosgws
ssh -l root cephadm radosgw-admin --cluster=gabe user list | jq -r '.[]' > $USERS_RADOSGW

#   Filter out users with UUID format as they are the OpenStack ones (handled later)
#     Only the users created locally on the radosgws remain
cat $USERS_RADOSGW | grep -Ev "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}" | sort > $USERS_LOCAL

#   Get the quota details for the local users
cat $USERS_LOCAL | ssh -l root cephadm /root/ceph-scripts/tools/s3-accounting/get-s3-user-stats.py > $QUOTA_LOCAL


## OpenStack projects
#   Ask OpenStack the list of projects known to have S3 quota
openstack project list --domain default --tags-any s3quota --format json | jq -r '.[].ID' > $USERS_OPENSTACK

#   Get the quota details for the OpenStack projects
cat $USERS_OPENSTACK | ssh -l root cephadm /root/ceph-scripts/tools/s3-accounting/get-s3-user-stats.py > $QUOTA_OPENSTACK



### Handle accounting 

## Radosw local users
#   Get the mapping file (manual, human) between local users and chargegroup
s3cmd --quiet --force get $MAPPING_LOCAL_S3 $MAPPING_LOCAL_FILE

#   Crunch the quota file for local users
echo -n "" > $ACCOUNTING_LOCAL
while read -r line;
do
  user_id=$(echo $line | grep -Eo "\(.*\):" | tr -d '():')
  if [ ! -z "$user_id" ];
  then
    chargegroup=$(cat $MAPPING_LOCAL_FILE | jq -r ".\""$user_id\"".chargegroup")        # Get the charge group from the mapping file
    chargerole=$(cat $MAPPING_LOCAL_FILE | jq -r ".\""$user_id\"".user_id")             # Get the charge role (using the user_id on the rgw)
    usergroup="unknown, ,"                              # Simulate unknown usergroup (hard to query xldap for these users)

    # If the mapping is found, generate output
    if [ "$chargegroup" != "null" ];
    then
      echo $line" chargegroup: "$chargegroup", chargerole: "$chargerole", "$usergroup >> $ACCOUNTING_LOCAL
    else
      # Or print a warning otherwise
      echo "WARNING: userid $user_id not found in the mapping file for local radosgw users"
    fi 
  fi
done < $QUOTA_LOCAL


## OpenStack projects
#   Get the file with all valid charge groups
curl --silent $MAPPING_OPENSTACK_GAR --output $MAPPING_OPENSTACK_FILE


#   Crunch the quota file for OpenStack projects
echo -n "" > $ACCOUNTING_OPENSTACK
while read -r line;
do
  project_id=$(echo $line | grep -Eo "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}")
  if [ ! -z $project_id ];
  then
    userinfo=$($THISDIR/s3-user-to-accounting-unit.py $project_id)      # Format: <username> chargegroup: <chargegroup>, chargerole: <chargerole>
    userid=$(echo $userinfo | cut -d ' ' -f 1)                          # Keep the <username> only
    chargegroup=$(echo $userinfo | grep -Eo " chargegroup: [a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}, " | cut -d ':' -f 2- | tr -d ', ')
    chargerole=$(echo $userinfo | grep -Eo ", chargerole: .*" | cut -d ':' -f 2- | tr -d ' ')
    usergroup=$($THISDIR/cern-get-accounting-unit.sh --id $userid -f)   # (Try to) Get userid, email address, and group/section information

    # If there is no accounting information, charge IT
    if [ -z $chargegroup ]; then
      chargegroup_name='IT'
      chargerole='default'
    # Or match with the accounting information otherwise
    else
      chargegroup_name=$(jq -r --arg chgroup $chargegroup '.data | map(select(.uuid | contains($chgroup))) | .[].name' $MAPPING_OPENSTACK_FILE)
    fi
    userac="chargegroup: $chargegroup_name, chargerole: $chargerole"
    echo $line" "$userac", "$usergroup >> $ACCOUNTING_OPENSTACK
  fi;
done < $QUOTA_OPENSTACK



### Create reporting for GSS internal accounting
#    https://storage.web.cern.ch/storage/accounting/

## Create JSON for GSS reporting out of accounting for local users
create_json_for_gss_reporting "$ACCOUNTING_LOCAL" "$REPORTING_LOCAL_GSS"

## Create JSON for GSS reporting out of accounting for OpenStack projects
create_json_for_gss_reporting "$ACCOUNTING_OPENSTACK" "$REPORTING_OPENSTACK_GSS"

## Create overall reporting for GSS by flattening the two JSONs above
jq -c -s 'map(.data) | flatten | {data: .}' $REPORTING_LOCAL_GSS $REPORTING_OPENSTACK_GSS > $REPORTING_ALL_GSS

## Publish the overall reporting to to FDO project on EOS
cp -v $REPORTING_ALL_GSS $TARGET_ACCOUNTING_GSS



### Create reporting for central accounting
#
# Note: For the time being we (IT-ST) do the reporting for all accounts existing in S3
#       IT-CM should do the reporting for projects existing in OpenStack.
#       When this is effective, we (IT-ST) will need to do the reporting only for local rgw users
#
#       To do so, instead of using "$REPORTING_ALL_GSS" as source file,
#         simply use "$REPORTING_LOCAL_GSS" as input for the python script
#         generating the JSON for the central accounting
$THISDIR/convert-report-gss-to-central.py $REPORTING_ALL_GSS

## Publish reporting to central accounting receiver
send_to_accounting_receiver $REPORTING_ALL_GSS-reporting-central-quota.json
#send_to_accounting_receiver $REPORTING_ALL_GSS-reporting-central-usage.json    # Do no ship actual usage as suggested by Jan



### Archive collected data

# Make archive
tar -czf $ARCHIVE $SUBDIR

# Push to s3://s3-accounting-files
s3cmd put $ARCHIVE $ARCHIVE_S3

# Clean up local temporary files
rm -rf $SUBDIR
rm -f $ARCHIVE

