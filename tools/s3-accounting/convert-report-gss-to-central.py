#! /usr/bin/python3 -u

#
# This script reads the JSON file created for the internal GSS reporting,
#   aggregates the usage numbers by charge_group and charge_role, 
#   and prepares a secon JSON file for the central accounting reporting.
#

import datetime
import json
import os
import sys


# Fields required by central accounting
#   Docs: https://accounting-docs.web.cern.ch/services/v3/accounting/
MessageFormatVersion = 3
FromChargeGroup      = "S3 Object Storage"
TimePeriod           = "day"
TimeStamp            = (datetime.datetime.today() - datetime.timedelta(days=1)).strftime('%Y-%m-%d')
TimeAggregate        = "avg"
AccountingDoc        = "S3 Object Storage users"


# AccountingUnit class
#   To store bytes granted as per quota and used bytes
class AccountingUnit:
    def __init__(self):
        self.quota_bytes    = 0
        self.used_bytes     = 0
    def add_quota(self, quota):
        self.quota_bytes += quota
    def add_used(self, used):
        self.used_bytes += used
    def get_quota(self):
        return self.quota_bytes
    def get_used(self):
        return self.used_bytes


# The source file must be passed as argument
if len (sys.argv) != 2:
    print ("ERROR: No source filename given")
    sys.exit(1)
source_file = sys.argv[1]


# Open and load the source file
try:
    with open(source_file) as fin:
      data = json.load(fin)
except:
    print("ERROR: Unable to load input file %s" % (source_file))
    sys.exit(1)


# Parse the data and make aggregated statistics per charge group/role
charge_groups = {}
for entry in data["data"]:
    # Add charge group and role to the dictionary
    chgroup = entry["charge_group"]
    chrole  = entry["charge_role"]
    if chgroup not in charge_groups.keys():
        charge_groups[chgroup] = {}

    if chrole not in charge_groups[chgroup].keys():
        charge_groups[chgroup][chrole] = AccountingUnit()

    # Update usage statistics for that group/role
    try:
        quota = int(entry["quota_raw"] )
    except ValueError:
        continue
    try:
        usage = int(entry["usage_raw"])
    except ValueError:
        continue
    charge_groups[chgroup][chrole].add_quota(quota)
    charge_groups[chgroup][chrole].add_used(usage)


# Generate JSON output as needed by per central accounting
#   Docs: https://accounting-docs.web.cern.ch/services/v3/accounting/

metadata = {\
            "MessageFormatVersion": MessageFormatVersion, \
            "FromChargeGroup": FromChargeGroup, \
            "TimeStamp": TimeStamp, \
            "TimePeriod": TimePeriod, \
            "TimeAggregate": TimeAggregate, \
            "AccountingDoc": AccountingDoc
            }

quota_list = []
used_list  = []
for group, roles in charge_groups.items():
    for role, data in roles.items():
        quota_list.append({"ToChargeGroup": group, "ToChargeRole": role, "MetricValue": data.get_quota()})
        used_list.append({"ToChargeGroup": group, "ToChargeRole": role, "MetricValue": data.get_used()})

quota_output = {"MetricName": "DiskQuota", "data" : quota_list}
used_output  = {"MetricName": "DiskUsage", "data" : used_list}

quota_file = source_file+'-reporting-central-quota.json'
used_file  = source_file+'-reporting-central-usage.json'
with open(quota_file, 'w') as fout:
    json.dump({**metadata, **quota_output}, fout)
with open(used_file, 'w') as fout:
    json.dump({**metadata, **used_output}, fout)

