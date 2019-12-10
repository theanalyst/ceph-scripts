#! /bin/bash

#
# Usage: ./get-user-gept-group-info.sh <user>
#
# where <user>: user-id, email
#


userid=`echo $1 | sed -e 's/@.*//'`

reply=`ldapsearch -xLLL -h xldap.cern.ch -p 389 -b "dc=cern,dc=ch" "(|(mail=$1)(cn=$userid))"`

serviceowner=`echo $reply | grep -Eo "managedBy: CN=[a-z0-9\-\+]*," | sed -e 's/.*CN=//' | tr -d ","`

mail=`echo $reply | grep -Eo "mail: [a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+" | sed -e 's/.*: //'`

if [ -z $serviceowner ];
then
  userdepgrp=`echo $reply | grep -Eo "department: [A-Z]+[/A-Z]?+" | sed -e 's/.*: //'`;
  userSection=`echo $reply | grep -Eo "cernSection: [A-Z]+" | sed -e 's/.*: /\//'`;
  echo -n "$userid, "
else
  replytoso=`ldapsearch -x -h xldap.cern.ch -p 389 -s base -b "cn=$serviceowner,ou=Users,ou=Organic Units,dc=cern,dc=ch"`
  userdepgrp=`echo $replytoso|  grep -Eo "department: [A-Z]+[/A-Z]?+" | sed -e 's/.*: //'`
  userSection=`echo $replytoso | grep -Eo "cernSection: [A-Z]+" | sed -e 's/.*: /\//'`;
  echo -n "$serviceowner, "
fi

echo $mail
