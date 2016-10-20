#!/bin/bash

# Common functions for scheduling

function wait_gently {
	# TODO: can one combine timeout and wait ?
	wait
}

function stop_gently {
	# remove allow flag, telling to stop to all parallel schedulers
	rm allow.$queue
}

function get_lock {
	# the only real atomic command with error signaling in bash
	mkdir job_list.$queue.lock
	local ret=$?
	# update lock status
	if (( $ret == 0 ))
	then
		has_lock=true
	fi
	return $ret
}

function release_lock {
	# release the lock if it was us who put it there
	if [ ! -z "$has_lock" ]
	then
		rm -fr job_list.$queue.lock
		has_lock=
	fi
}

function clean_up {
	# stop all subprocesses

	# kill echoing
	kill %1
	# wait for the subprocesses to end gently
	wait_gently # SIGKILL won't wait
	# kill cmdline
	if [ ! -z "$jobpid" ]
	then
		kill -SIGTERM $jobpid
	fi
	exit 0
}

function abort_scheduling {
	# indicate abort and stop all subprocesses
	date >>schedule_$messages.log
	echo "Scheduling aborted druring execution of '$CmdLine'" >>schedule_$messages.log
	release_lock
	clean_up
}

# globals for functions
has_lock=

# set action on kill codes
trap abort_scheduling SIGHUP SIGINT SIGTERM

