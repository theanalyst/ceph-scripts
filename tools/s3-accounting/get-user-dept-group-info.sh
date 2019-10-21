#! /bin/bash


for i in `ldapsearch -x -h xldap.cern.ch -p 389 -s base -b "cn=$1,ou=Users,ou=Organic Units,dc=cern,dc=ch"  | grep -E "department|cernSection" | sed -e 's/cern//' | sed -e "s/^.*: //" | sed -e 's/\// /'`;
do 
  echo -n $i" "; 
done;
echo ""
