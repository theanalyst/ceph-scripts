#! /bin/bash


export OS_PROJECT_NAME=Services

OUTFILE="s3-accounting-`date '+%Y-%m-%d'`.log"
rm $OUTFILE


FILENAME="/tmp/s3accounting.tmp.log"
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
    ./get-user-dept-group-info-by-email.sh `echo $line | grep  -Eo "[a-z0-9\.-]*@.*$"` | awk '{print ", "$1"/"$2}' >> $OUTFILE
  fi;
done < $FILENAME

s3cmd put $OUTFILE s3://s3-accounting-files
