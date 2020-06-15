#! /bin/bash
#
# usage: ./master-script.sh <quota treshold>
#

export OS_PROJECT_NAME=Services

OUTFILE="s3-dev-accounting-`date '+%F'`.log"
FDOFILE="s3-dev-accounting-`date '+%F'`.data"
PRVFILE="s3-dev-accounting-`date -d "yesterday" '+%F'`.log"
TRESHOLD=$1
FILENAME="/tmp/s3-dev-accounting-`date '+%F'`.tmp.log"


if [ -z $TRESHOLD ];
then 
  TRESHOLD=85
fi

echo -n "" > $OUTFILE

OS_CLOUD=cern openstack project list --domain default --tags-any s3quota --format json | jq '.[].ID' | tr -d "\"" | ssh cephadm /root/ceph-scripts/tools/s3-accounting/get-s3-user-stats.py > $FILENAME

while read -r line; 
do 
  prid=`echo $line | grep -Eo "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"`; 
  echo -n $line" " >> $OUTFILE; 
  if [ ! -z $prid ]; 
  then 
    userinfo=`/afs/cern.ch/user/j/jcollet/ceph-scripts/tools/s3-accounting/s3-user-to-accounting-unit-v2.py $prid`
    userid=`echo $userinfo | cut -f1 -d" "`
    userac=`echo $userinfo | sed -s "s/$userid//"`
    if [[ -z $userac ]]; 
    then
      userac="chargegroup: IT, chargerole: default"
    fi
    echo -n "$userac, " >> $OUTFILE
    /afs/cern.ch/user/j/jcollet/ceph-scripts/tools/s3-accounting/cern-get-accounting-unit.sh --id $userid -f >> $OUTFILE
  else
    /afs/cern.ch/user/j/jcollet/ceph-scripts/tools/s3-accounting/cern-get-accounting-unit.sh --id `echo $line | grep  -Eo "[a-z0-9\.-]*@.*$" | tr -d ","` -f >> $OUTFILE
  fi;
done < $FILENAME

s3cmd put $OUTFILE s3://s3-accounting-files
s3cmd get --force s3://s3-accounting-files/$PRVFILE  
#s3cmd rm s3://s3-accounting-files/$PRVFILE

while read -r line;
do
  uid=`echo $line | grep -Eo "\(.*\)"`;

  if [ -z $uid ];
  then
    echo "-> $line"
  else
    prv=`grep "$uid" $PRVFILE | grep -Eo ", [0-9.]+ percent full" | tr -d "[a-z ,]"`
    act=`echo $line | grep -E "$uid" | grep -Eo ", [0-9.]+ percent full" | tr -d "[a-z ,]"`

    if (( $(echo "$act > $TRESHOLD" | bc -l) )) && (( $(echo "$prv < $TRESHOLD" | bc -l) ))  ;
    then
      echo "`echo $uid | tr -d "()"` usage is $act (was $prv)"
      echo "User `echo $uid | tr -d "()"` is reaching $act percent of its allowed quota (was $prv)" | mail -s "S3 Account $uid quota treshold reached" julien.collet@cern.ch
    fi
  fi
done < $OUTFILE

echo -n "{\"data\": [" > $FDOFILE

while read -r line; 
do 
  name=`echo $line | grep -Eo "^.*\(" | tr -d "("`
  uid=`echo $line | grep -Eo "\(.*\)" | tr -d "()"`


  chargegroup=`echo $line | grep -Eo "chargegroup: [0-9a-zA-Z-]*," | sed -e 's/chargegroup: //' | tr -d ","`
  chargerole=`echo $line | grep -Eo "chargerole: [0-9a-zA-Z-]*," | sed -e 's/chargerole: //' | tr -d ","`

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

# publish data to cern.ch/storage/accounting
mv $FDOFILE /eos/project/f/fdo/www/accounting/data-dev.s3.json 

# clean
#rm $PRVFILE
#rm $OUTFILE



