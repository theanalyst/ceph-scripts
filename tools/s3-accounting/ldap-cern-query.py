#!/usr/bin/python

import ldap 

l = ldap.initialize('ldap://xldap.cern.ch:389')
basedn = "ou=Users,ou=Organic Units,dc=cern,dc=ch"
query = "(mail=wen.guan@cern.ch)"

result = l.search_s(basedn,ldap.SCOPE_SUBTREE,query)

print result[0][1]['displayName'][0]+": "+result[0][1]['division'][0]+"-"+result[0][1]['cernGroup'][0]+"-"

