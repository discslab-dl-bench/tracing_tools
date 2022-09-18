#!/bin/bash

# This script will launch and trace the BERT language model workload
# gathering and zipping the traces at the end.

CONTAINER_NAME="train_dlio"

# Helper function to terminate training and clean up behind us
terminate_traces() {
	# Kill the training process and the traces
	# if using strace, it was stopped when root_pid ended
	docker kill $CONTAINER_NAME
	docker rm $CONTAINER_NAME
	tmux kill-session -t $CONTAINER_NAME

	kill $trace_bio_pid
	kill $trace_read_pid
	kill $trace_write_pid
	kill $trace_create_del_pid
	kill $trace_openat_pid
	kill $trace_close_pid
	kill $trace_cpu_pid
	kill $trace_gpu_pid

	# Kill any remaining traces that didn't get killed above
	remaining_traces=$(ps | grep bpftrace | awk '{print $1}')
	for proc in $remaining_traces; 
	do	
		kill $proc
	done
}

main() {

	if [ "${EUID:-$(id -u)}" -ne 0 ]
	then
		echo "Run script as root"
		exit -1
	fi

	if [ $# -lt 3 ]
	then
		echo "Usage: $0 <workload_dir> <output_dir> (<experiment_name>)"
		exit 1
	fi

	workload_dir=$1
	output_dir=$2

	# Get the optional 4th argument
	if [ $# -eq 3 ]
	then
		exp_name="${3}"
	else
		exp_name="experiment"
	fi

	# Argument validation

	# Fix given paths i.e. remove trailing or extra slashes
	workload_dir=$(realpath -s  --canonicalize-missing $workload_dir)
	output_dir=$(realpath -s  --canonicalize-missing $output_dir)

	# Create the output directory
	exp_name="${exp_name}_$(date +'%Y%m%d%H%M%S')"
	output_dir="${output_dir}/${exp_name}"

	if [ ! -d $output_dir ] 
	then
		echo "Creating $output_dir"
		mkdir -p $output_dir
	fi

	# Flush filesystem caches
	sync
	echo 3 > /proc/sys/vm/drop_caches

	sleep 5

	# Delete previous app log if it exists
	if [ "$(ls ${output_dir}/results)" ]
	then
		echo "Deleting old app log and casefile logs"
		rm ${output_dir}/results/*
	fi

	echo "Starting traces"
	# Kill the tmux session from a previous run if it exists
	tmux kill-session -t $CONTAINER_NAME 2>/dev/null

	# Start a new tmux session from which we will run training
	tmux new-session -d -s $CONTAINER_NAME

	# Start the bpf traces, storing their pid
	bpftrace traces/explore/trace_bio.bt -o ${output_dir}/trace_bio.out &
	trace_bio_pid=$!

	bpftrace traces/explore/trace_read.bt -o ${output_dir}/trace_read.out &
	trace_read_pid=$!

	bpftrace traces/explore/trace_write.bt -o ${output_dir}/trace_write.out &
	trace_write_pid=$!

	bpftrace traces/explore/trace_create_del.bt -o ${output_dir}/trace_create_del.out &
	trace_create_del_pid=$!

	bpftrace traces/explore/trace_openat.bt -o ${output_dir}/trace_openat.out &
	trace_openat_pid=$!

	bpftrace traces/explore/trace_close.bt -o ${output_dir}/trace_close.out &
	trace_close_pid=$!

	# Start the CPU and GPU traces
	mpstat 1 > ${output_dir}/cpu.out &
	trace_cpu_pid=$!

	#TODO: Explore using Nsight for GPU tracing
	nvidia-smi pmon -s um -o DT -f ${output_dir}/gpu.out &		
	trace_gpu_pid=$!

	echo "Starting training"
	# Start training within the tmux session. 
	tmux send-keys -t $CONTAINER_NAME "sudo ${workload_dir}/start_dlio.sh" C-m

	# Get the system-wide PID of the root process ID in the container (bash)
	root_pid=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME)

	echo "root pid: \"$root_pid\""

	max_retries=100
	# If the previous command did not work (sometimes we must wait a bit), retry in a loop
	while [ -z "$root_pid" ]
	do
		[ $max_retries == 0 ]; then
			echo "ERROR: Could not get root PID. Exiting."
			terminate_traces
			exit 1
		fi
		max_retries=$(( $max_retries-1 ))
		sleep 0.25
		root_pid=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME)
	done

	# Attach the syscall trace to the root_process 
	# It will automatically attach to all spawned child processes
	strace -T -ttt -f -p $root_pid -e 'trace=!ioctl,clock_gettime,clock_nanosleep,sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list,poll,epoll_wait,brk' -o ${output_dir}/strace.out &

	# Save PID/TID map for later reference
	docker top $CONTAINER_NAME -o user,pid,tid,spid,args e > ${output_dir}/pids_$(date +'%m%d%H%M%S').out

	echo "Now waiting until training completion"

	# Now wait until training finishes
	while kill -0 "$root_pid"; do
		sleep 2
		# Save PID/TID map 
		docker top $CONTAINER_NAME -o user,pid,tid,spid,args e > ${output_dir}/pids_$(date +'%m%d%H%M%S').out
	done

	# Sleep a bit more once training stops to capture full shutting down
	sleep 5

	terminate_traces

	exit 0
}

main $@