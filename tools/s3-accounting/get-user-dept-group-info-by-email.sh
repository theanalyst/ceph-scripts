#! /bin/bash


for i in `ldapsearch -x -h xldap.cern.ch -p 389 -b "dc=cern,dc=ch" "(mail=$1)"  | grep -E "managedBy" | grep -Eo "CN=[a-z]+" | sed -e 's/.*=//'`;
do 
  ./get-user-dept-group-info.sh $i;
done;

if [ -z $i ];
then
  userid=`echo -n $1 | sed -e 's/@cern.ch//'`
  ./get-user-dept-group-info.sh `ldapsearch -xLLL -h xldap.cern.ch -p 389 -b "dc=cern,dc=ch" "(|(mail=$1)(cn=$userid))" cn | grep -E "cn: [a-z]+" | sed -e 's/cn: //'` 
fi


