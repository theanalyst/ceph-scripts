# !/bin/bash 
#
# Print rbd image usage on current osd
# usage: ./rbdtop.sh <osd> <time frame>
# <osd> the id of the osd under scrutiny
# <time_frame> logs gathering period


usage="rbdtop.sh 

where:
    -h show this help text
    -o <id>: the id of the osd under scrutiny  (defaul: all osds)
    -l <length> logs gathering period (default: 30s)
    -q enables quiet mode for logging"

full_osd=0
len=30
host=`hostname -s`;

VERBOSE=1

#Monitoring configuration
MONITORING_SEND=True
MONITORING_HOST="filer-carbon.cern.ch"
MONITORING_PORT="2003"
METRIC_PREFIX="cephtop"

METRIC=`echo "$METRIC_PREFIX"".test""$host"".""bytetotal"`


while getopts 'qho:l:' opt; do
  case "$opt" in
    h) echo "$usage"
       exit
       ;;
    o) osd_id=$OPTARG
       ;;
    l) len=$OPTARG
       ;;
    q) VERBOSE=0
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

function draw(){
  if [[ $VERBOSE -eq 1 ]];
  then 
    echo -e ${1}
  fi
}


start=`date '+%F %T'`;
end=`date -d "$start today + 30 second" +'%F %T'`;

# generate OSD list for the current machine
if [ -z "$osd_id" ];
then
 draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Going full osd mode"
 draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Generate list of OSDs in $host"
 ceph osd tree | awk -v HN=$host 'BEGIN{toggle=0}  { if( $0 ~ HN ) {toggle=1}; if(toggle) { if( ($0 ~ /host/ || $0 ~ /rack/) && !($0 ~ HN)) {toggle=0} else { print $0; }}}' | grep -E "^[0-9]+"
 full_osd=1; 
 osd_id=0;
fi

# collect logs
if [ $full_osd -eq 0 ];
then
  if [ "$end_ws" -ge "$now_ws" ];
  then  
    # activate appropriate debug level 
    draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Adjusting debug level to osd.$osd_id"
    ceph tell osd.$osd_id injectargs --debug_ms 1
   
    draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Gathering logs for $len secs"
    sleep $len;
  
    # deactivate logging before exit
    draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Deactivate logging"
    ceph tell osd.$osd_id injectargs --debug_ms 0
 
  else  # read old logs
    draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Collecting $len secs of logs"
  fi

  # gather some logs
  active_image_count=`cat /var/log/ceph/ceph-osd.$osd_id.log | grep -E "\[[acrsw][a-z-]+" | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | wc -l`;
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Logs collected, parsing"
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m logfile is: " `ls /var/log/ceph/ceph-osd.$osd_id.log`
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m OSD operation summary ($active_image_count active images):"
  grep -Eo "\[[wacrs][rep][a-z-]+" /var/log/ceph/ceph-osd.$osd_id.log | sort -h | uniq -c | tr -d '['
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Image statistics:"
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - write: "
  grep -E "\[write " /var/log/ceph/ceph-osd.$osd_id.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 5 
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - writefull: "
  grep -E "\[writefull" /var/log/ceph/ceph-osd.$osd_id.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 5
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - read: "
  grep -E "\[read" /var/log/ceph/ceph-osd.$osd_id.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 5
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - sparse-read: "
  grep -E "\[sparse-read" /var/log/ceph/ceph-osd.$osd_id.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 5

else
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Adjusting debug level to all osds"
  for f in `ls /var/run/ceph/ceph-osd.*.asok | tr -d '[a-zA-Z/\.\-]'`; 
  do
    touch /var/log/ceph/ceph-osd."$f".log 
    echo -n $f" ";
    ceph tell osd.$f injectargs --debug_ms 1
  done

  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Gathering logs for $len secs"
  sleep $len;

  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Deactivate logging"
  for f in `ls /var/run/ceph/ceph-osd.*.asok | tr -d '[a-zA-Z/\.\-]'`; 
  do
    ceph tell osd.$f injectargs --debug_ms 0
  done
  
  # extract files
  mkdir -p /tmp/rbdtop/ 
  for id in `ls /var/run/ceph/ceph-osd.*.asok | tr -d '[a-zA-Z/\.\-]'`; 
  do
    /root/ceph-scripts/tools/top/logfilter.awk "$start" "$end" /var/log/ceph/ceph-osd.$id.log > /tmp/rbdtop/ceph-osd.$id.log
  done
  
  # gather some logs
  active_image_count=`cat /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -E "\[[acrsw][a-z-]+" | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | wc -l`;
  timestamp_a=`date +%s`;
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Logs collected, parsing"
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m logfile is /tmp/rbdtop/ceph-osd.[0-9]*.log"
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m OSD operation summary ($active_image_count active images):"
  #grep -Eo "\[write " /tmp/rbdtop/ceph-osd.[0-9]*.log | sort -h | uniq -c | tr -d '[' | sed 's/:/ /' | sort -k1gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$2".osd_write "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }'; 
  #grep -Eo "\[writefull" /tmp/rbdtop/ceph-osd.[0-9]*.log | sort -h | uniq -c | tr -d '[' | sed 's/:/ /' | sort -k1gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$2".osd_writefull "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }'; 
  #grep -Eo "\[read" /tmp/rbdtop/ceph-osd.[0-9]*.log | sort -h | uniq -c | tr -d '[' | sed 's/:/ /' | sort -k1gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$2".osd_read "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }'; 
  #grep -Eo "\[sparse-read" /tmp/rbdtop/ceph-osd.[0-9]*.log | sort -h | uniq -c | tr -d '[' | sed 's/:/ /' | sort -k1gr | head -n 50  | awk '{print "echo cephtop.test.'$host'."$2".osd_sparseread "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }'; 
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Image statistics:"
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - write: "
  grep -E "\[write " /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 5 | awk '{print "echo cephtop.test.'$host'."$2".op_write "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }'; 
  grep -E "\[write " /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$2".op_write "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' | sh; 
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - writefull: "
  grep -E "\[writefull" /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 5 | awk '{print "echo cephtop.test.'$host'."$2".op_writefull "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' ; 
  grep -E "\[writefull" /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$2".op_writefull "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' | sh; 
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - read: "
  grep -E "\[read" /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 5 | awk '{print "echo cephtop.test.'$host'."$2".op_read "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }'; 
  grep -E "\[read" /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$2".op_read "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' | sh; 
  
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - sparse-read: "
  grep -E "\[sparse-read" /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 5 | awk '{print "echo cephtop.test.'$host'."$2".op_sparseread "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' ; 
  grep -E "\[sparse-read" /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq -c | sort -k1gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$2".op_sparseread "$1" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' | sh; 

  timestamp=`date '+%F_%T' | sed -e 's/:/-/g'` 
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Computing bytes (output in /tmp/report-rbdtop"
  mkdir -p "/tmp/report-rbdtop/"
  time for i in `cat /tmp/rbdtop/ceph-osd.[0-9]*.log | grep -E "\[[acrsw][a-z-]+" | grep -Eo "rbd_data\.[0-9a-f]+" | sort -h | uniq`; 
  do
    echo -n "$i " >> /tmp/report-rbdtop/"$timestamp".log
    grep $i -R /tmp/rbdtop/ | grep -Eo "\[write.*\]" | tr -d "[]a-z " | grep -Eo "~[0-9]+" | tr -d "~" | awk 'BEGIN { sum = 0} { sum += $1 } END { print sum" " }' | tr -d "\n" >> /tmp/report-rbdtop/"$timestamp".log
    grep $i -R /tmp/rbdtop/ | grep -Eo "\[read.*\]" | tr -d "[]a-z " | grep -Eo "~[0-9]+" | tr -d "~" | awk 'BEGIN { sum = 0} { sum += $1 } END { print sum" " }' | tr -d "\n" >> /tmp/report-rbdtop/"$timestamp".log 
    grep $i -R /tmp/rbdtop/ | grep -Eo "\[writefull.*\]" | tr -d "[]a-z " | grep -Eo "~[0-9]+" | tr -d "~" | awk 'BEGIN { sum = 0} { sum += $1 } END { print sum" " }' | tr -d "\n" >> /tmp/report-rbdtop/"$timestamp".log
    grep $i -R /tmp/rbdtop/ | grep -Eo "\[sparse-read.*\]" | tr -d "[]a-z " | grep -Eo "~[0-9]+" | tr -d "~" | awk 'BEGIN { sum = 0} { sum += $1 } END { print sum" " }' | tr -d "\n" >> /tmp/report-rbdtop/"$timestamp".log
    echo "" >> /tmp/report-rbdtop/"$timestamp".log
  done


  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m Image statistics (byte usage)"
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - write: "
  cat /tmp/report-rbdtop/"$timestamp".log | sort -k2gr | head -n 5  | awk '{print "echo cephtop.test.'$host'."$1".byte_write "$2" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }'; 
  cat /tmp/report-rbdtop/"$timestamp".log | sort -k2gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$1".byte_write "$2" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' | sh; #pipe this to sh 
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - read: "
  cat /tmp/report-rbdtop/"$timestamp".log | sort -k3gr | head -n 5  | awk '{print "echo cephtop.test.'$host'."$1".byte_read  "$3" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }';
  cat /tmp/report-rbdtop/"$timestamp".log | sort -k3gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$1".byte_read  "$3" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' | sh;
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - writefull: "
  cat /tmp/report-rbdtop/"$timestamp".log | sort -k4gr | head -n 5  | awk '{print "echo cephtop.test.'$host'."$1".byte_writefull "$4" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }';
  cat /tmp/report-rbdtop/"$timestamp".log | sort -k4gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$1".byte_writefull "$4" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' | sh;
  draw "\033[1;31m\033[40m[`date '+%F %T'`/rbdtop]\033[0m   - sparse-read: "
  cat /tmp/report-rbdtop/"$timestamp".log | sort -k5gr | head -n 5  | awk '{print "echo cephtop.test.'$host'."$1".byte_sparseread "$5" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }';
  cat /tmp/report-rbdtop/"$timestamp".log | sort -k5gr | head -n 50 | awk '{print "echo cephtop.test.'$host'."$1".byte_sparseread "$5" '$timestamp_a' | nc '$MONITORING_HOST' '$MONITORING_PORT'" }' | sh;
fi


#echo "echo $METRIC 10 | nc $MONITORING_HOST $MONITORING_PORT"


#cleanup
#rm -rf /tmp/rbdtop/


#TODO:
#
# replace grep in the analysis by awk scripts or lexer ?
 
