#! /bin/bash
#
# usage: ./master-script.sh <quota treshold>
#

export OS_PROJECT_NAME=Services

OUTFILE="s3-accounting-`date '+%Y-%m-%d'`.log"
PRVFILE="s3-accounting-`date -d "yesterday" '+%Y-%m-%d'`.log"
TRESHOLD=$1
FILENAME="/tmp/s3accounting.tmp.log"


if [ -z $TRESHOLD ];
then 
  TRESHOLD=85
fi

echo -n "" > $OUTFILE

ssh cephadm /root/ceph-scripts/tools/s3-accounting/get-s3-user-stats.py > $FILENAME

while read -r line; 
do 
  prid=`echo $line | grep -Eo "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"`; 
  echo -n $line" " >> $OUTFILE; 
  if [ ! -z $prid ]; 
  then 
    ./s3-user-to-accounting-unit.py $prid >> $OUTFILE
  else
    ./cern-get-accounting-unit.sh `echo $line | grep  -Eo "[a-z0-9\.-]*@.*$" | tr -d ","` >> $OUTFILE
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
    echo ""
  fi
done < $OUTFILE

# clean
rm $PRVFILE
rm $OUTFILE



