#!/usr/bin/python -u

import json, commands, ldap



def sizeof_fmt(num, suffix='B'):
    for unit in ['','Ki','Mi','Gi','Ti','Pi','Ei','Zi']:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, 'Yi', suffix)



users = json.loads(commands.getoutput('radosgw-admin --cluster=gabe user list'))

l = ldap.initialize('ldap://xldap.cern.ch:389')
basedn = "ou=Users,ou=Organic Units,dc=cern,dc=ch"

for uid in users:
    info = json.loads(commands.getoutput('radosgw-admin --cluster=gabe user info --uid=%s' % uid))
    if info['user_quota']['max_size_kb'] > 1:
        try:
            stats = json.loads(commands.getoutput('radosgw-admin --cluster=gabe user stats --uid=%s' % uid))['stats']
        except:
            stats = {}
            stats['total_bytes'] = 0
            stats['total_entries'] = 0

        buckets = json.loads(commands.getoutput('radosgw-admin --cluster=gabe bucket list --uid=%s' % uid))
        # affiliation = commands.getoutput('./get-user-dept-group-info-by-email.sh %s' % info['email'])
        # query = "(mail="+info['email']+")" 
        # result = l.search_s(basedn,ldap.SCOPE_SUBTREE,query);
        # try: 
        #     user_div = result[0][1]['division'][0]
        # except:
        #     user_div = ""

        # try:
        #     user_grp = "-"+result[0][1]['cernGroup'][0]
        # except:
        #     user_grp = ""
 
        # try:
        #     user_sct = "-"+result[0][1]['cernSection'][0]
        # except:
        #     user_sct = ""

        # affiliation = user_div+user_grp+user_sct         

        print '%s (%s): %s quota, %s used, %d buckets, %d objects, %s, %s' % (info['display_name'], uid, sizeof_fmt(info['user_quota']['max_size']), sizeof_fmt(stats['total_bytes']), len(buckets), stats['total_entries'], info['email'], affiliation)

