#!/bin/bash

# Submit jobs given in a list job_list.queue$1 the submit conditions and frequency are controlled in jobb_limits.sh

queue=queue$1

# log and show last actions
touch allow.$queue
date >>schedule_$queue.log
echo "Scheduling started" >>schedule_$queue.log
tail -n 2 schedule_$queue.log
# different interpreters may count lines differently (\r needed at last line or not), count lines etalon file oneliner.txt
lstep=$( cat oneliner.txt | wc -l )
while [ -f 'allow.run' ]
do
  
  # head line to be submitted
  CmdLine=$( head -n 1 job_list.$queue )
  # note, the newline count is the number of lines - 1
  NQueue=$(( $( cat job_list.$queue | wc -l ) - $lstep ))
  
  # stop condition
  if [ "$NQueue" = "-1" ]; then
    echo "Scheduling ended" >>schedule_$queue.log
	date >>schedule_$queue.log
    exit 0
  fi
  # remove headline
  tail -n +2 job_list.$queue > joblist.tmp
  mv joblist.tmp job_list.$queue
  # log and show last actions
  date >>schedule_$queue.log
  echo NQueue=$NQueue >>schedule_$queue.log
  echo $CmdLine >>schedule_$queue.log
  echo $CmdLine >>schedule_$queue.out
  eval $CmdLine >>schedule_$queue.out 2>>schedule_$queue.log
  tail -n 4 schedule_$queue.log
done

date >>schedule_$queue.log
echo "Scheduling stopped" >>schedule_$queue.log

