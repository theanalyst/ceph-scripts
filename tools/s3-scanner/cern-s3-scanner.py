#
# CERN s3 Scanner
# Julien Collet <julien.collet@cern.ch>
# 2020
#

# Imports
import argparse
import json
import os
import re
import requests
import sys
import subprocess


# Global variables
scriptsDir = '/afs/cern.ch/user/c/cephacc/private/ceph-scripts/tools/s3-accounting/'
userDict = {}


# Functions
def checkBucket(bName, mode='default', outFile=sys.stdout, triesLeft=2):
    """ Simple check using a request, pretty much like in S3scanner if you ask me
    - bName: bucket name """

    if triesLeft == 0:
        return False

    # TODO: Do we really want https?
    bUrl = 'https://'+ bName + '.s3.cern.ch'
    try:
        r = requests.head(bUrl)
    except:
        print('Error requesting url: ',bUrl,file=outFile)
        return False

    if r.status_code == 200:
        bOwnerName = getBucketOwner(bName)
        ## print(bOwnerName,': ',bUrl + ' (',r.status_code,')',file=outFile)
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
        info = json.loads(subprocess.getoutput('ssh root@cephadm radosgw-admin --cluster=gabe metadata get bucket:'+bName))
        owner = json.loads(subprocess.getoutput('ssh root@cephadm radosgw-admin --cluster=gabe metadata get user:'+info['data']['owner']))
        email = subprocess.getoutput(scriptsDir+'cern-get-accounting-unit.sh --id '+owner['data']['email'])
        if email != "":
          return email
        else:
          ret=subprocess.getoutput(scriptsDir+'cern-get-accounting-unit.sh --id `'+scriptsDir+'s3-user-to-accounting-unit.py '+info['data']['owner']+'`')  
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

'''
def dumpInfo(userList,outFile=sys.stdout):
  if outFile == sys.stdout:
    for bOwner in userList.keys():
      buckets=[]
      for bName in userList[bOwner]:
        if bName.startswith(': '):
          buckets.append(bName[2:])
        else:
          buckets.append(bName)
      print("%s: %s" % (bOwner, ','.join(buckets)))
  else:
    output="{"
    for bOwner in list(userList):
      output+=str("\""+bOwner.strip()+"\": "+json.dumps(userList[bOwner])+',');
    output=output[:-1]
    output+="}"
    print(output,file=outFile)
'''
def dumpInfo(userList,outFile=sys.stdout):
  output="{"
  for bOwner in list(userList):
    output+=str("\""+bOwner.strip()+"\": "+json.dumps(userList[bOwner])+',');
  output=output[:-1]
  output+="}"
  print(output,file=outFile)

def checkBlackListing(bucket, whiteList):
  if whiteList:
    with open(whiteList, 'r') as b:
        for l in b:
          ret = re.search (l.rstrip(), bucket)
          if ret:
            return False
  return True 



# ---MAIN---
# Arg parser
parser = argparse.ArgumentParser(description='# CERN s3 Scanner - simple s3 bucket scanner\n'
                                             '#\n'
                                             '# jcollet\n'
                                             '# CERN IT\n'
                                             '# 2019\n',
                                 prog='cern-s3-scanner', formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('-m', '--mode', dest='mode', default='default',
  help='Scan mode:\n \
    - \'listall\', print everything\n \
    - \'listopen\', print open buckets and their content\n \
    - \'bucketonly\', print only bucket name')
parser.add_argument('-i', '--input', dest='buckets', default='',
  help='Name of text file containing buckets to check.\n \
    If unset, will contact cephgabe for the list of all buckets')
parser.add_argument('-o', '--out-file', dest='outFile', default=sys.stdout,
  help='Output file. If unset, will print to stdout')
parser.add_argument('-w', '--white-list', dest='whiteList', default='s3://s3-scanner/blacklist',
  help='File containing a list of patterns that will whitelist matching bucket names')
args = parser.parse_args()

# If needed, get the whitelist from s3
if args.whiteList.startswith('s3://'):
  localWhiteList = os.getcwd()+'/whitelist.tmp'
  print("Downloading whitelist from %s..." % args.whiteList)
  print(subprocess.getoutput("s3cmd --quiet get %s %s --force" % (args.whiteList, localWhiteList)))
  args.whiteList = localWhiteList

# Crunch the buckets
if args.buckets == '':
  print("Loading bucket list from cephgabe...")
  bucketsGabe = json.loads(subprocess.getoutput('ssh root@cephadm radosgw-admin --cluster=gabe bucket list'))
  print("Processing buckets...")
  for line in bucketsGabe:
    if checkBlackListing(line, args.whiteList):
      if checkBucket(line, args.mode): 
        if args.mode != 'bucketonly':
          exploreBucket(line, args.mode)
elif os.path.isfile(args.buckets):
  print("Processing buckets list from %s..." % args.buckets)
  with open(args.buckets, 'r') as f:
    for line in f:
      line = line.rstrip()
      if checkBlackListing(line, args.whiteList):
        if checkBucket(line, args.mode): 
          if args.mode != 'bucketonly':
            exploreBucket(line, args.mode)
else:
  print("Processing bucket %s" % args.buckets)
  if checkBucket(args.buckets, args.mode): 
    if args.mode != 'bucketonly': 
      exploreBucket(args.buckets, args.mode)

# Report output
if args.outFile != sys.stdout:
  print(subprocess.getoutput("rm -fv "+args.outFile))
  with open(args.outFile,'x') as f:
    dumpInfo(userDict,f)
  print(subprocess.getoutput("s3cmd put "+args.outFile+" s3://s3-scanner/scan-output"))
  print(subprocess.getoutput("rm -fv "+args.outFile))
else:
  dumpInfo(userDict,args.outFile)

