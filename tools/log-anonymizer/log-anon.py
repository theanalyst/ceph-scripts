from __future__ import division
from datetime import datetime, timedelta

import re
import argparse
import sys
import dateutil.parser as dp


def totimestamp(dt, epoch=datetime(1970,1,1)):
    td = dt - epoch
    return (td.microseconds + (td.seconds + td.days * 86400) * 10**6) / 10**6 




parser = argparse.ArgumentParser()
parser.add_argument('-f', '--file', dest='infile', default=sys.stdout)
args = parser.parse_args()

ip_list = {};
t0 = 0;

with open(args.infile,'r') as f:
    for line in f:
        if not t0:
            ret = re.findall('[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{6} ', line)
            t0 = totimestamp(dp.parse(ret[0]))

        ret = re.findall('[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}', line)
        r = line.rstrip("\n")
        for ip in ret:
            if ip not in ip_list:
                ip_list[ip] = 'ip_address_'+str(len(ip_list))
            r = re.sub(ip,ip_list[ip],r)

        ret = re.findall('[0-9]{4}[-/][0-9]{2}[-/][0-9]{2}[ -][0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{6}', line)
        for ts in ret:
            t = totimestamp(dp.parse(ts)) - t0
            r = re.sub(ts,str(t),r)

        print(r)
