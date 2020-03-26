#
# CERN s3 Scanner
# Julien Collet <julien.collet@cern.ch>
# 2020
#


from os import path

import argparse
import sys
import requests
import re
import json
import subprocess


userDict = {} 



def checkBucket(bName, mode='default', outFile=sys.stdout, triesLeft=2):
    """ Simple check using a request, pretty much like in S3scanner if you ask me
    - bName: bucket name """

    if triesLeft == 0:
        return False

    bUrl = 'https://'+ bName + '.s3.cern.ch'

    try:
        r = requests.head(bUrl)
    except:
        print('Error requesting the following Url: ',bUrl,file=outFile)
        return False

    if r.status_code == 200:
        bOwnerName = getBucketOwner(bName)
        #print(bOwnerName,': ',bUrl + ' (',r.status_code,')',file=outFile)
        if bOwnerName.split(',')[0] in userDict:
          userDict[bOwnerName.split(',')[0]].append(str(bOwnerName.split(',')[1]+": "+bName).strip())
        else:
          userDict[bOwnerName.split(',')[0]]     = [str(bOwnerName.split(',')[1]+": "+bName).strip()]
        return True

    elif r.status_code == 403:
        if mode == 'listall':
            print(bUrl + ' (',r.status_code,')',file=outFile)
        return False

    elif r.status_code == 404: 
        if mode == 'listall':
            print(bUrl + ' (',r.status_code,')',file=outFile)
        return False

    elif r.status_code == 503:
        return checkBucketWithoutCreds(bucketName, mode, outFile, triesLeft-1)

    else:
        print(bUrl + ' (',r.status_code,') --> Unhandled status code',file=sys.stderr)
        return False

def getBucketOwner(bName):
    try:
        info = json.loads(subprocess.getoutput('ssh cephadm radosgw-admin --cluster=gabe metadata get bucket:'+bName))
        owner = json.loads(subprocess.getoutput('ssh cephadm radosgw-admin --cluster=gabe metadata get user:'+info['data']['owner']))
        email = subprocess.getoutput('/afs/cern.ch/user/j/jcollet/ceph-scripts/tools/s3-accounting/cern-get-accounting-unit.sh --id '+owner['data']['email'])
        if email != "":
          return email
        else:
          ret=subprocess.getoutput('/afs/cern.ch/user/j/jcollet/ceph-scripts/tools/s3-accounting/cern-get-accounting-unit.sh --id `/afs/cern.ch/user/j/jcollet/ceph-scripts/tools/s3-accounting/s3-user-to-accounting-unit.py '+info['data']['owner']+'`')  
          if ret != "unknown, ":
            return ret
          else:  
            return "Unknown, "+owner['data']['email']

    except:
        print('Couldn\'t reach cephgabe',file=sys.stdout)
        return 'OwnerNotFound'

def exploreBucket(bName, mode='default', outFile=sys.stdout):
    """ Explore bucket (if possible) and show publicly accessible objects 
        - bName: bucket name """

    bUrl = 'https://'+ bName + '.s3.cern.ch'
    r = requests.get(bUrl)
    for content in re.findall('<Contents>(.+?)</Contents>', str(r.content), re.MULTILINE):
        objString = bUrl + '/' + re.findall('<Key>(.+?)</Key>', content)[0] + ' (' + re.findall('<ID>(.+?)</ID>', content)[0] + ')' #+ ' ' + re.findall('<DisplayName>(.+?)</DisplayName>', content)[0] 
        objR = requests.head(bUrl + '/' + re.findall('<Key>(.+?)</Key>', content)[0])
        if objR.status_code == 200 or mode == 'listopen':   
            print('  [', objR.status_code, '] ' + objString,file=outFile)

def dumpInfo(userList,outFile=sys.stdout):
  output="{"
  for bOwner in list(userList):
    output+=str("\""+bOwner.strip()+"\": "+json.dumps(userList[bOwner])+',');
  output=output[:-1]
  output+="}"
  print(output,file=outFile)

parser = argparse.ArgumentParser(description='# CERN s3 Scanner - simple s3 bucket scanner\n'
                                             '#\n'
                                             '# jcollet\n'
                                             '# CERN IT\n'
                                             '# 2019\n',
                                 prog='cern-s3-scanner')

def checkBlackListing(bucket, blackList):
  if blackList:
    with open(blackList, 'r') as b:
        for l in b:
          ret = re.search (l.rstrip(), bucket)
          if ret:
            return False
  return True 
# Declare arguments
parser.add_argument('-o', '--out-file', dest='outFile', default=sys.stdout,
                    help='Output file. If unset, will print to terminal')
parser.add_argument('-b', '--black-list', dest='blackList', default='',
                    help='File containing a list of pattern to black list entries in the list')
parser.add_argument('-m', '--mode', dest='mode', default='default',
                    help='Scan mode: instead of printing only publicly accessible resources:  \n - listall, dump everything\n - listopen, dump open buckets and their contents\n - bucketonly, print only bucket, not their content ')
parser.add_argument('-i', '--input', dest='buckets', default='',
                    help='Name of text file containing buckets to check, if unset, will contact cephgabe for the list of all buckets')


args = parser.parse_args()


if args.blackList == 's3://s3-scanner/blacklist':
  print("Downloading blacklist from ",args.blackList)
  print(subprocess.getoutput("s3cmd get s3://s3-scanner/blacklist /tmp/blacklist --force"))
  args.blackList = "/tmp/blacklist"

if args.buckets == '':
  print("Getting bucket list from gabe")
  for line in json.loads(subprocess.getoutput('ssh cephadm radosgw-admin --cluster=gabe bucket list')):
    if checkBlackListing(line, args.blackList):
      if checkBucket(line, args.mode): 
        if args.mode != 'bucketonly':
          exploreBucket(line, args.mode)

elif path.isfile(args.buckets):
  with open(args.buckets, 'r') as f:
    for line in f:
      line = line.rstrip()            # Remove any extra whitespace
      if checkBlackListing(line, args.blackList):
        if checkBucket(line, args.mode): 
          if args.mode != 'bucketonly':
            exploreBucket(line, args.mode)

else:
  if checkBucket(args.buckets, args.mode): 
    if args.mode != 'bucketonly': 
      exploreBucket(args.buckets, args.mode)
    
if args.outFile != sys.stdout:
  print(subprocess.getoutput("rm -fv "+args.outFile))
  with open(args.outFile,'x') as f:
    dumpInfo(userDict,f)
  print(subprocess.getoutput("s3cmd put "+args.outFile+" s3://s3-scanner/scan-output"))
  print(subprocess.getoutput("rm -fv "+args.outFile))
else:
  dumpInfo(userDict,args.outFile)



