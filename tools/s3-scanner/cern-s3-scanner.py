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


def checkBucket(bName, mode='default', triesLeft=2):
    """ Simple check using a request, pretty much like in S3scanner if you ask me
    - bName: bucket name """

    if triesLeft == 0:
        return False

    bUrl = 'https://'+ bName + '.s3.cern.ch'
    r = requests.head(bUrl)
    

    if r.status_code == 200:
        print(bUrl + ' (',r.status_code,')')
        return True
    elif r.status_code == 403:
        if mode == 'listall':
            print(bUrl + ' (',r.status_code,')')
        return False
    elif r.status_code == 404: 
        if mode == 'listall':
            print(bUrl + ' (',r.status_code,')')
        return False
    elif r.status_code == 503:
        return checkBucketWithoutCreds(bucketName, mode, triesLeft-1)
    else:
        print(bUrl + ' (',r.status_code,') --> Unhandled status code')
        return False

def exploreBucket(bName, mode='default'):
    """ Explore bucket (if possible) and show publicly accessible objects 
        - bName: bucket name """

    bUrl = 'https://'+ bName + '.s3.cern.ch'
    r = requests.get(bUrl)
    for content in re.findall('<Contents>(.+?)</Contents>', r.content, re.MULTILINE):
        objString = bUrl + '/' + re.findall('<Key>(.+?)</Key>', content)[0] + ' (' + re.findall('<ID>(.+?)</ID>', content)[0] + ')' #+ ' ' + re.findall('<DisplayName>(.+?)</DisplayName>', content)[0] 
        objR = requests.head(bUrl + '/' + re.findall('<Key>(.+?)</Key>', content)[0])
        if objR.status_code == 200 or mode == 'listopen':   
            print('  [', objR.status_code, '] ' + objString)

parser = argparse.ArgumentParser(description='# CERN s3 Scanner - simple s3 bucket scanner\n'
                                             '#\n'
                                             '# jcollet\n'
                                             '# CERN IT\n'
                                             '# 2019\n',
                                 prog='cern-s3-scanner')

# Declare arguments
#parser.add_argument('-o', '--out-file', dest='outFile', default='./buckets.txt',
#                    help='Output file')
parser.add_argument('-m', '--mode', dest='mode', default='default',
        help='Scan mode: instead of printing only publicly accessible resources:  \n - listall, dump everything\n - listopen, dump open buckets and their contents\n - bucketonly, print only bucket, not their content ')
parser.add_argument('buckets', help='Name of text file containing buckets to check')

args = parser.parse_args()


#mode selection: 

if not path.isfile(args.buckets):
    if checkBucket(args.buckets, args.mode): 
        if args.mode != 'bucketonly': 
            exploreBucket(args.buckets, args.mode)







