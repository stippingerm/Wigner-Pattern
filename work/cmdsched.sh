#!/bin/bash

# Submit jobs given in a list job_list.queue the submit conditions and frequency are controlled in jobb_limits.sh

# log and show last actions
touch allow.run
date >>schedule.log
echo "Scheduling started" >>schedule.log
tail -n 2 schedule.log
# different interpreters may count lines differently (\r needed at last line or not), count lines etalon file oneliner.txt
lstep=$( cat oneliner.txt | wc -l )
while [ -f 'allow.run' ]
do
  
  # head line to be submitted
  CmdLine=$( head -n 1 job_list.queue )
  # note, the newline count is the number of lines - 1
  NQueue=$(( $( cat job_list.queue | wc -l ) - $lstep ))
  
  # stop condition
  if [ "$NQueue" = "-1" ]; then
    echo "Scheduling ended" >>schedule.log
	date >>schedule.log
    exit 0
  fi
  # remove headline
  tail -n +2 job_list.queue > joblist.tmp
  mv joblist.tmp job_list.queue
  # log and show last actions
  date >>schedule.log
  echo NQueue=$NQueue >>schedule.log
  echo $CmdLine >>schedule.log
  echo $CmdLine >>schedule.out
  eval $CmdLine >>schedule.out 2>>schedule.log
  tail -n 4 schedule.log
done

date >>schedule.log
echo "Scheduling stopped" >>schedule.log

