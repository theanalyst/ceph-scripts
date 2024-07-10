#!/bin/bash


UserID=$1

if [ x"$UserID" == x"" ];
then
  echo "Error: User ID not provided."
  echo "  Usage: ./check_bucket_quota.sh <UserID>"
  exit 1
fi


# Get the user quota, if set
user_info=$(radosgw-admin user info --uid=$UserID)
if $(echo $user_info | jq '.user_quota.enabled');
then
  user_quota_b=$(echo $user_info | jq '.user_quota.max_size')
  echo "  User quota: $user_quota_b"
else
  user_quota_b=-1
  echo "  User quota is not set."
fi


# Get the buckets quota
bucket_total_b=0
for bucket in $(radosgw-admin bucket list --uid=$UserID | jq -r .[] | sort)
do
  bucket_stats=$(radosgw-admin bucket stats --bucket=$bucket)
  if $(echo $bucket_stats | jq '.bucket_quota.enabled');
  then
    bucket_quota_b=$(echo $bucket_stats | jq '.bucket_quota.max_size')
    bucket_quota_gb=$((bucket_quota_b / 1073741824))
    bucket_total_b=$((bucket_total_b + bucket_quota_b))
    echo "    Bucket $bucket: $bucket_quota_b ($bucket_quota_gb GB)"
  else
    echo "    Bucket $bucket: Quota not set"
fi
done

echo
echo "Summary:"
user_quota_gbytes=$((user_quota_b / 1073741824))
bucket_total_gb=$((bucket_total_b / 1073741824))
echo "  User quota: $user_quota_b ($user_quota_gbytes GB)"
echo "  Buckets cumulative: $bucket_total_b ($bucket_total_gb GB)"

if [ $bucket_total_b -gt $user_quota_b ];
then
  echo
  echo "  Warning: Cumulative bucket quota is higher than user quota ($bucket_total_gb VS $user_quota_gbytes GB)"
fi
