#! /bin/bash
#
# usage: ./get-s3-accounting.sh
#

OUTFILE="s3-accounting-`date '+%F'`.log"
FDOFILE="s3-accounting-`date '+%F'`.data"
FILENAME="s3-accounting-`date '+%F'`.tmp.log"

THISDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# Thanks to https://stackoverflow.com/questions/59895/how-can-i-get-the-source-directory-of-a-bash-script-from-within-the-script-itsel

echo -n "" > $OUTFILE

# Alternatively, use a `clouds.yaml file`
# Docs: https://docs.openstack.org/python-openstackclient/pike/configuration/index.html
export OS_CLOUD=cern
export OS_PROJECT_NAME=services
openstack project list --domain default --tags-any s3quota --format json | jq '.[].ID' | tr -d "\"" | ssh -l root cephadm /root/ceph-scripts/tools/s3-accounting/get-s3-user-stats.py > $FILENAME

while read -r line; 
do 
  prid=`echo $line | grep -Eo "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"`; 
  echo -n $line" " >> $OUTFILE; 
  if [ ! -z $prid ]; 
  then 
    userinfo=`$THISDIR/s3-user-to-accounting-unit.py $prid`
    userid=`echo $userinfo | cut -f1 -d" "`
    userac=`echo $userinfo | sed -s "s/$userid//"`
    if [[ -z $userac ]]; 
    then
      userac="chargegroup: IT, chargerole: default"
    fi
    echo -n "$userac, " >> $OUTFILE
    $THISDIR/cern-get-accounting-unit.sh --id $userid -f >> $OUTFILE
  else
    $THISDIR/cern-get-accounting-unit.sh --id `echo $line | grep  -Eo "[a-z0-9\.-]*@.*$" | tr -d ","` -f >> $OUTFILE
  fi;
done < $FILENAME

s3cmd --quiet put $OUTFILE s3://s3-accounting-files

echo -n "{\"data\": [" > $FDOFILE

#Download 
curl --silent -XGET --negotiate -u : https://haggis.cern.ch:8204/chargegroup --output listofchargegroup

while read -r line; 
do 
  name=`echo $line | grep -Eo "^.*\(" | tr -d "("`
  uid=`echo $line | grep -Eo "\(.*\)" | tr -d "()"`


  tmpchargegroup=`echo $line | grep -Eo "chargegroup: [0-9a-zA-Z-]*," | sed -e 's/chargegroup: //' | tr -d ","`
  chargerole=`echo $line | grep -Eo "chargerole: [0-9a-zA-Z-]*," | sed -e 's/chargerole: //' | tr -d ","`

  if [[ $tmpchargegroup != "IT" ]]; then
    chargegroup=`jq --arg tmpchargegroup "$tmpchargegroup" '. | map(select(.UUID | contains($tmpchargegroup))) | .[].Name ' listofchargegroup | tr -d "\""`
  else
    chargegroup="IT"
  fi

  data=`echo $line | grep -Eo ":.*$" | tr -d ":"`

  affiliation=`echo $line | grep -Eo ", [A-Za-z/]+$" | tr -d " ,"`
  if [ `echo $affiliation | sed 's/[^/]//g' | awk '{ print length }'` -eq 2 ]
  then
    sec=`echo $affiliation | sed 's/\// /g' | awk '{print $3}'`
    grp=`echo $affiliation | sed 's/\// /g' | awk '{print $2}'` 
    dep=`echo $affiliation | sed 's/\// /g' | awk '{print $1}'`
  elif [ `echo $affiliation | sed 's/[^/]//g' | awk '{ print length }'` -eq 1 ]
  then
    sec="" 
    grp=`echo $affiliation | sed 's/\// /g' | awk '{print $2}'`
    dep=`echo $affiliation | sed 's/\// /g' | awk '{print $1}'`
  else
    sec=""
    grp=""
    dep=$affiliation
  fi

  echo -n "{\"display_name\": \"$name\",\"uid\":\"$uid\","  >> $FDOFILE
  echo -n $data | tr -d "," | awk '{ printf \
   "\"quota\":\""$1"\","\
   "\"quota_raw\":"$12","\
   "\"usage\":\""$3"\"," \
   "\"usage_raw\":"$14"," \
   "\"usage_human\":"$5"," \
   "\"num_bucket\":"$8"," \
   "\"num_objects\":"$10"," \
   "\"owner\":\""$20"\"," \
   "\"mail\":\""$21"\"," \
  }' >> $FDOFILE
  echo -n  "\"MessageFormatVersion\":2," >> $FDOFILE
  echo -n  "\"charge_group\":\"$chargegroup\"," >> $FDOFILE
  echo -n  "\"charge_role\":\"$chargerole\"," >> $FDOFILE
  echo -n "\"FE\":\"S3 Object Storage\"," >> $FDOFILE
  echo -n "\"date\":\"`date -d "yesterday" '+%F'`\"," >> $FDOFILE
  echo -n "\"division\":\"$dep\"," >> $FDOFILE
  echo -n "\"group\":\"$grp\"," >> $FDOFILE
  echo -n "\"section\":\"$sec\"" >> $FDOFILE
  echo -n "}," >> $FDOFILE
done < $OUTFILE

echo -n "{}]}" >> $FDOFILE
sed -e 's/,{}]/]/' -i $FDOFILE

$THISDIR/convert-accounting-file.sh $FDOFILE > general-accounting.s3.json

# Publish data to FDO (now GSS)
mv $FDOFILE /eos/project/f/fdo/www/accounting/data.s3.json 

# Publish data to general accountingcern.ch/storage/accounting
curl --silent -X POST -H "Content-Type: application/json" -H "API-key:`cat /afs/cern.ch/project/ceph/private/s3-accounting.key`"  https://acc-receiver-dev.cern.ch/v2/fe/S3%20Object%20Storage -d "@general-accounting.s3.json" 

# clean
rm $OUTFILE
rm $FILENAME
rm general-accounting.s3.json
rm listofchargegroup
