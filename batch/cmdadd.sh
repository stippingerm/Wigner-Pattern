#!/bin/bash

# Add jobs given on stdin to the list job_list.queue$1

source ./libsched.sh


# name of the queue
queue=queue$1
if [ -z "$2" ]
then
	messages=$queue
else
	messages=msg$2
fi

# this file controls the execution of a queue
touch allow.$queue
# log and show last actions
date >>schedule_$messages.log
echo "Adding started for $queue @ $$" >>schedule_$messages.log
tail -f -n 2 schedule_$messages.log &

# go on with scheduling
while read line
do
	while [ ! -z "$line" ]
	do
		# obtain lock, so parallel execution is possible
		if get_lock
		then
			# add line to queue (some escaping might be needed)
			echo "$line" >> job_list.$queue
			echo "Added: $line"
			line=
			# file access done, release the lock
			release_lock
			eval $CmdLine >>schedule_$messages.out 2>>schedule_$messages.log
		else
			# Display warnings on screen only
			echo "Didn't get lock, waiting."
			sleep 0.$RANDOM
		fi
	done
done

