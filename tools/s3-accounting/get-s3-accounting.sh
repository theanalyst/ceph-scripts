#! /bin/bash
#
# usage: ./master-script.sh <quota treshold>
#

export OS_PROJECT_NAME=Services

OUTFILE="s3-accounting-`date '+%F'`.log"
PRVFILE="s3-accounting-`date -d "yesterday" '+%F'`.log"
TRESHOLD=$1
FILENAME="/tmp/s3-accounting-`date '+%F'`.tmp.log"


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
    userid=`/afs/cern.ch/user/j/jcollet/ceph-scripts/tools/s3-accounting/s3-user-to-accounting-unit.py $prid`
    /afs/cern.ch/user/j/jcollet/ceph-scripts/tools/s3-accounting/cern-get-accounting-unit.sh $userid >> $OUTFILE
  else
    /afs/cern.ch/user/j/jcollet/ceph-scripts/tools/s3-accounting/cern-get-accounting-unit.sh `echo $line | grep  -Eo "[a-z0-9\.-]*@.*$" | tr -d ","` >> $OUTFILE
  fi;
done < $FILENAME

s3cmd put $OUTFILE s3://s3-accounting-files
s3cmd get --force s3://s3-accounting-files/$PRVFILE  

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
      echo "User `echo $uid | tr -d "()"` is reaching $act percent of its allowed quota (was $prv)" | mail -s "S3 Account $uid quota treshold reached" julien.collet@cern.ch
    fi
  fi
done < $OUTFILE

# clean
rm $PRVFILE
rm $OUTFILE



