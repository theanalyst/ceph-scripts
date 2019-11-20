#! /bin/bash


export OS_PROJECT_NAME=Services

OUTFILE="s3-accounting-`date '+%Y-%m-%d'`.log"
PRVFILE="s3-accounting-`date -d "yesterday" '+%Y-%m-%d'`.log"
TRESHOLD=$1
FILENAME="/tmp/s3accounting.tmp.log"

echo -n "" > $OUTFILE

ssh cephadm /root/ceph-scripts/tools/s3-accounting/s3-accounting-full.py > $FILENAME

while read -r line; 
do 
  prid=`echo $line | grep -Eo "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"`; 
  if [ ! -z $prid ]; 
  then 
    echo -n $line" " >> $OUTFILE; 
  ./s3-user-to-accounting-unit.py $prid >> $OUTFILE
  fi;
done < $FILENAME

while read -r line; 
do 
  prid=`echo $line | grep -Eo "[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}"`; 
  if [ -z  $prid ]; 
  then 
    id=`echo $line | grep -Eo "\(.*\)" | tr -d "()"`;
    echo -n $line >> $OUTFILE
    ./get-user-dept-group-info-by-email.sh `echo $line | grep  -Eo "[a-z0-9\.-]*@.*$" | tr -d ","` | awk '{print " "$1"/"$2}' >> $OUTFILE
  fi;
done < $FILENAME

s3cmd put $OUTFILE s3://s3-accounting-files
s3cmd get s3://s3-accounting-files/$PRVFILE  

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
      echo "`echo $uid | tr -d "()"`: is $act, was $prv -> generate email"
    fi
  fi
done < $OUTFILE

# clean
rm $PRVFILE
rm $OUTFILE



