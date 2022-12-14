#!/bin/bash

# This script will launch and trace the BERT language model workload
# gathering and zipping the traces at the end.

# Helper function to terminate training and clean up behind us
terminate_traces() {
	# Kill the training process and the traces
	# if using strace, it was stopped when root_pid ended
	docker kill train_bert
	docker rm train_bert
	tmux kill-session -t train_bert

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
		echo "Usage: $0 <workload_dir> <output_dir> <num_gpus> (<experiment_name>)"
		exit 1
	fi

	workload_dir=$1
	output_dir=$2
	num_gpus=$3

	# Get the optional 4th argument
	if [ $# -eq 4 ]
	then	
		exp_name="${4}"
	else
		exp_name="experiment"
	fi

	# Argument validation

	# Fix given paths i.e. remove trailing or extra slashes
	workload_dir=$(realpath -s  --canonicalize-missing $workload_dir)
	output_dir=$(realpath -s  --canonicalize-missing $output_dir)

	# Ensure num_gpus is numeric
	re='^[0-9]+$'
	if ! [[ $num_gpus =~ $re ]] ; then
	echo "Error: '$num_gpus' is not a number. <num_gpus> must be a number." >&2
	echo "Usage: $0 <workload_dir> <output_dir> <num_gpus> (<experiment_name>)"
	exit 1
	fi


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
	tmux kill-session -t train_bert 2>/dev/null

	# Start a new tmux session from which we will run training
	tmux new-session -d -s train_bert

	# Start the bpf traces, storing their pid
	bpftrace traces/bert/trace_bio.bt -o ${output_dir}/trace_bio.out &
	trace_bio_pid=$!

	bpftrace traces/bert/trace_read.bt -o ${output_dir}/trace_read.out &
	trace_read_pid=$!

	bpftrace traces/bert/trace_write.bt -o ${output_dir}/trace_write.out &
	trace_write_pid=$!

	bpftrace traces/bert/trace_create_del.bt -o ${output_dir}/trace_create_del.out &
	trace_create_del_pid=$!

	bpftrace traces/bert/trace_openat.bt -o ${output_dir}/trace_openat.out &
	trace_openat_pid=$!

	bpftrace traces/bert/trace_close.bt -o ${output_dir}/trace_close.out &
	trace_close_pid=$!

	# Start time alignment trace
	bpftrace traces/trace_time_align.bt -o ${output_dir}/trace_time_align.out &
	trace_time_align_pid=$!

	# Start the CPU and GPU traces
	mpstat 1 > ${output_dir}/cpu.out &
	trace_cpu_pid=$!

	#TODO: Explore using Nsight for GPU tracing
	nvidia-smi pmon -s um -o DT -f ${output_dir}/gpu.out &		
	trace_gpu_pid=$!

	echo "Starting training"
	# Start training within the tmux session. 
	tmux send-keys -t train_bert "sudo ${workload_dir}/start_training.sh" C-m

	# Get the system-wide PID of the root process ID in the container (bash)
	root_pid=$(grep -E "NSpid:[[:space:]]+[0-9]+[[:space:]]+1$" /proc/*/status 2> /dev/null | awk '{print $2}')

	# Check if $root_pid contains a newline character, indicating the previous command returned multiple values
	if [[ "$root_pid" =~ $'\n' ]]
	then
		RED='\033[0;31m'
		NC='\033[0m' # No Color
		echo -e "${RED}WARNING:${NC}"
		echo "Multiple docker containers are running at the same time."
		echo "This could interfere with your tracing - or your tracing could interfere with others!"
		echo "Please check the calendar reservations, someone might have reserved the server for experiments."
		echo "Run 'sudo docker ps' to list the other containers. If the server is yours right now, you can kill them with 'sudo docker kill <container id>'" 
		echo -e "Output of 'sudo docker ps' is printed below:\n"
		sudo docker ps

		echo -e "\nShutting down."

		terminate_traces

		exit 0
	fi

	echo "root pid: \"$root_pid\""

	# If the previous command did not work (sometimes we must wait a bit), retry in a loop
	while [ -z "$root_pid" ]
	do
		echo "failed to get training pid, trying again"
		sleep 1
		root_pid=$(grep -E "NSpid:[[:space:]]+[0-9]+[[:space:]]+1$" /proc/*/status 2> /dev/null | awk '{print $2}')
		echo "new try: $root_pid"
	done

	# Attach the syscall trace to the root_process 
	# It will automatically attach to all spawned child processes
	#strace -T -ttt -f -p $root_pid -e 'trace=!ioctl,clock_gettime,sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list' -o ${output_dir}/strace.out &

	# Sleep a bit to let training spawn all workers
	sleep 120

	echo "Slept 120s, collecting PIDs/TIDs and time_alignment trace"

	# # Save PID/TID map for later reference
	# ps aux -T | grep python > ${output_dir}/pids.out

	# Kill the time alignment trace early, 2min should be plenty
	kill $trace_time_align_pid

	echo "Now waiting until training completion"

	# Now wait until training finishes
	while kill -0 "$root_pid"; do
		sleep 5
	done

	# Sleep a bit more once training stops to capture full shutting down
	sleep 10

	terminate_traces

	# # Copy the application log to the results directory
	# cp ${workload_dir}/bert.log $output_dir

	# # Archive the traces
	# output_parent_dir="$(dirname "$output_dir")"
	# tar zcvf "${output_parent_dir}/traces_${exp_name}.tar.gz" $output_dir

	exit 0
}

main $@