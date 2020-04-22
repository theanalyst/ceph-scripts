
import re
import argparse
import sys

parser = argparse.ArgumentParser()

parser.add_argument('-f', '--file', dest='infile', default=sys.stdout)

args = parser.parse_args()

ip_list = {};

with open(args.infile,'r') as f:
    for line in f:
        ret = re.findall('[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}',line)
        r = line.rstrip("\n")
        for ip in ret:
            if ip not in ip_list:
                ip_list[ip] = 'ip_address_'+str(len(ip_list))
            r=re.sub(ip,ip_list[ip],r)

        print(r)
