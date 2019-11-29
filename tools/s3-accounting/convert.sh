#!/bin/bash



echo -n "{\"data\": ["

while read -r line; 
do 
  name=`echo $line | grep -Eo "^.*\(" | tr -d "("`
  uid=`echo $line | grep -Eo "\(.*\)" | tr -d "()"`

  data=`echo $line | grep -Eo ":.*$" | tr -d ":"`

  echo -n "{\"name\": \"$name\",\"uid\":\"$uid\"," 
  echo -n $data | tr -d "," | awk '{ printf \
   "\""$2"\":\""$1"\","\
   "\"usage\":\""$3"\"," \
   "\"usage_human\":\""$5"\"," \
   "\"num_bucket\":\""$8"\"," \
   "\"num_objects\":\""$10"\"," \
   "\"mail\":\""$12"\"" \
  }'
  echo -n "},"
done < $1



echo -n "{}]}"
