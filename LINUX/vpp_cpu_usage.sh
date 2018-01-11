#!/bin/bash

trap cleanup EXIT

cleanup()
{
    echo "bye"
}

OUTFILE=".pkt-gen.top"
pid=`pgrep pkt-gen`
[[ "$pid" == "" ]] && echo "pkt-gen process not found" && exit
rm -f $OUTFILE
top -b -p $pid | stdbuf -o0 -e0 grep pkt-gen > $OUTFILE &

cnt=0
tot=0
tot_sqsum=0
init_cnt=0
./vpp_show_status.sh

while [ 1 ]; do
   sleep 1
   str=`cat $OUTFILE | tail -1`
   [[ "$str" == "" ]] && continue

   ((init_cnt++))
   [[ $init_cnt -lt 5 ]] && continue    #ignore first 5 samples

   cur_cpu=`echo $str | awk '{print $9}'`
   ((cnt++))
   tot=`echo "scale=2; $cur_cpu+$tot" | bc -q`
   avg=`echo "scale=2; $tot/$cnt" | bc -q`
   tot_sqsum=`echo "scale=2; $tot_sqsum + (($cur_cpu - $avg)*($cur_cpu - $avg))" | bc -q`
   var=`echo "scale=2; $tot_sqsum/$cnt" | bc -q`
   stddev=`echo "scale=2; sqrt($var)" | bc -q`
   [[ $cnt -eq 1 ]] && min=$cur_cpu && max=$cur_cpu
   if (( $(echo "$cur_cpu < $min" | bc -l) )); then
       min=$cur_cpu
   fi
   if (( $(echo "$cur_cpu > $max" | bc -l) )); then
       max=$cur_cpu
   fi
   echo "$cnt cur=$cur_cpu, avg=$avg, min=$min, max=$max, var=$var, stddev=$stddev"
done
