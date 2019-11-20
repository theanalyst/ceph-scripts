#! /bin/bash

#
# Usage: ./get-user-gept-group-info.sh <user>
#
# where <user>: user-id, email
#

for i in `ldapsearch -x -h xldap.cern.ch -p 389 -b "dc=cern,dc=ch" "(mail=$1)"  | grep -E "managedBy" | grep -Eo "CN=[a-z]+" | sed -e 's/.*=//'`;
do 
  for j in `ldapsearch -x -h xldap.cern.ch -p 389 -s base -b "cn=$i,ou=Users,ou=Organic Units,dc=cern,dc=ch"  | grep -E "department|cernSection" | sed -e 's/cern//' | sed -e "s/^.*: //" | sed -e 's/\// /'`;
  do
    echo -n $j" ";
  done;
  echo ""
done;

if [ -z $i ];
then
  userid=`echo -n $1 | sed -e 's/@cern.ch//'`
  cn=`ldapsearch -xLLL -h xldap.cern.ch -p 389 -b "dc=cern,dc=ch" "(|(mail=$1)(cn=$userid))" cn | grep -E "cn: [a-z]+" | sed -e 's/cn: //'`
  for j in `ldapsearch -x -h xldap.cern.ch -p 389 -s base -b "cn=$cn,ou=Users,ou=Organic Units,dc=cern,dc=ch"  | grep -E "department|cernSection" | sed -e 's/cern//' | sed -e "s/^.*: //" | sed -e 's/\// /'`;
  do
    echo -n $j" ";
  done;
  echo ""
fi


