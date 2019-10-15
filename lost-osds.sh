#! /bin/bash



#ceph osd tree | grep host | awk '{ printf "%3.0f ", $2; print $4 }'
#ceph osd tree | grep host | awk '{ printf "%3.0f ", $2; }' | uniq


# Identify disk layouts


# Identify which hosts have missing drives
ceph osd tree | awk '{ if( $0 ~ /host/ ) { print c; c = 0; printf $4" "};  if( $0 ~ /osd/) { c = c+1 }  } END { print c }' > /tmp/tmpfile.hostlist.log

echo "done"
for i in `grep -v "24$" /tmpfile.hostlist.log`;
do
    echo "-- $i --"
done
