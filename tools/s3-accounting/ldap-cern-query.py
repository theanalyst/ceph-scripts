#!/usr/bin/python -u

from ldap3 import Server, Connection, ALL, ALL_ATTRIBUTES

username = "jcollet"

server = Server("xldap.cern.ch")
print "server instantiated"

base_dn = "OU=Users,OU=Organic Units,DC=cern,DC=ch"
conn = Connection(server, auto_bind=True)
print "connection is secured"

search_filter = "(CN=" + username + ")"
conn.search(search_base=base_dn, search_filter=search_filter, attributes=ALL_ATTRIBUTES)
print "Sending query"

print(conn.entries[0])

