#!/bin/bash

# Submit jobs given in a list job_list.queue$1 the submit conditions and
# frequency (if any) are controlled in execution_limits.sh

source ./libsched.sh


# name of the queue
queue=queue$1
if [ -z "$2" ]
then
	messages=$queue
else
	messages=msg$2
fi
jobpid=

# different interpreters may count lines differently (\r needed at last line
# or not), count lines in the etalon file oneliner.txt produced by command
# echo "this file contains one line break" > oneliner.txt
lstep=$( cat oneliner.txt | wc -l )

# this file controls the execution of a queue
touch allow.$queue
# log and show last actions
date >>schedule_$messages.log
echo "Scheduling started for $queue @ $$" >>schedule_$messages.log
tail -f -n 2 schedule_$messages.log &

# go on with scheduling
while [[ -f "allow.$queue" && -s job_list.$queue ]]
do
	# obtain lock, so parallel execution is possible
	if get_lock
	then
		# head line to be submitted
		CmdLine=$( head -n 1 job_list.$queue )
		# remaining lines; NOTE, the newline count is the number of lines - 1
		# on some systems line count might refer to number of line breaks
		# while on others to the non-empty lines
		# therefore we measure it before removing line content
		NQueue=$(( $( cat job_list.$queue | wc -l ) + 1 - $lstep ))
		# remove one line from the beginning
		tail -n +2 job_list.$queue > job_list.tmp
		mv job_list.tmp job_list.$queue
		# log and show last actions
		echo -e "$(date) NQueue=$NQueue @ $$\n$CmdLine" >>schedule_$messages.log
		echo "##$$## $CmdLine" >>schedule_$messages.out
		# file access done, release the lock
		release_lock
		eval $CmdLine >>schedule_$messages.out 2>>schedule_$messages.log
	else
		# Display warnings on screen only
		echo "Didn't get lock, waiting."
		sleep 0.$RANDOM
	fi
done

# log normal ending and clean up
date >>schedule_$messages.log
echo "Scheduling ended for $queue @ $$" >>schedule_$messages.log
sleep 1s # give some time for tail to echo
clean_up
