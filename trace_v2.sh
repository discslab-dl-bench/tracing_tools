#!/bin/bash

# This script will launch and trace DLIO.


# Helper function to terminate training and clean up behind us
terminate_traces() {
	# Kill the training process and the traces
	# if using strace, it was stopped when root_pid ended
	docker kill dlio_tracing
	docker rm dlio_tracing
	tmux kill-session -t dlio_tracing

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

usage() { 
	echo -e "Usage: $0 [OPTIONS]"
	echo -e "  -h, --help\t\t\tPrint this message"
	echo -e "  -w, --workload=name\tName of the workload. Must be one of bert,dlrm,imseg or dlio"
	echo -e "  -l, --launch-script=path\tPath to the workload launch script"
	echo -e "  -n, --num-gpus=num\t\tNumber of GPUs to launch the workload with, defaults to 1"
	echo -e "  -o, --output-dir=dir\t\tDirectory where to write the traces, defaults to ./trace_results"
	echo -e "  -e, --experiment-name=str\tOptional experiment name, defaults to \"experiment\""
	echo -e "  -s, --strace\t\t\tUse strace to record all system calls made (very intensive)"
	exit 1
}

main() {

	if [ "${EUID:-$(id -u)}" -ne 0 ]
	then
		echo "Run script as root"
		exit -1
	fi

	# See https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options

	TEMP=$(getopt -o hl:n:o:e:sw: --long help,launch-script:,num-gpus:,output-dir:,experiment-name:,strace,workload: \
				-n 'trace_v2' -- "$@")

	if [ $? != 0 ] ; then usage; exit 1 ; fi

	# Note the quotes around '$TEMP': they are essential!
	eval set -- "$TEMP"

	# Default values
	workload=
	launch_script=
	num_gpus=1
	exp_name="experiment"
	output_dir="./trace_results"
	use_strace=false

	while true; do
	case "$1" in
		-h | --help ) usage ;;
		-w | --workload ) workload="$2"; shift 2 ;;
		-l | --launch-script ) launch_script="$2"; shift 2 ;;
		-n | --num-gpus ) num_gpus="$2"; shift 2 ;;
		-o | --output-dir ) output_dir="$2"; shift 2 ;;
		-e | --experiment-name ) exp_name="$2"; shift 2 ;;
		-s | --strace ) use_strace=true; shift ;;
		-- ) shift; break ;;
		* ) usage ;;
	esac
	done

	# Check mandatory parameters were given
	[ !$workload ] && echo -e "Workload is mandatory!\n" && usage
	[ !$launch_script ] && echo -e "Launch script is mandatory!\n" && usage
	[ ! -f $launch_script ] && echo -e "Launch script given does not exist!\n" && usage

	# Argument validation
	case $workload in
		"bert" ) break ;;
		"dlrm" ) break ;;
		"imseg" ) break ;;
		"dlio" ) break ;;
		* ) echo "Invalid workload given. Must be one of bert, dlrm, imseg or dlio"; exit 1 ;;
	esac
	CONTAINER_NAME=train_${workload}

	# Fix given paths i.e. remove trailing or extra slashes
	output_dir=$(realpath -s  --canonicalize-missing $output_dir)

	# Create the output directory
	exp_name="${exp_name}_$(date +'%Y%m%d%H%M%S')"
	output_dir="${output_dir}/${exp_name}"

	if [ ! -d $output_dir ] 
	then
		echo "Creating $output_dir"
		mkdir -p $output_dir
	fi

	# Ensure num_gpus is numeric
	if ! [[ $num_gpus =~ '^[0-9]+$' ]] ; then
		echo "Error: '$num_gpus' is not a number!"
		usage 
	fi


	# Flush filesystem caches
	sync
	echo 3 > /proc/sys/vm/drop_caches

	sleep 5


	echo "Starting traces"
	# Kill the tmux session from a previous run if it exists
	tmux kill-session -t $CONTAINER_NAME 2>/dev/null

	# Start a new tmux session from which we will run training
	tmux new-session -d -s $CONTAINER_NAME

	# Start the bpf traces, storing their pid
	bpftrace ${workload}/trace_bio.bt -o ${output_dir}/trace_bio.out &
	trace_bio_pid=$!

	bpftrace ${workload}/trace_read.bt -o ${output_dir}/trace_read.out &
	trace_read_pid=$!

	bpftrace ${workload}/trace_write.bt -o ${output_dir}/trace_write.out &
	trace_write_pid=$!

	bpftrace ${workload}/trace_create_del.bt -o ${output_dir}/trace_create_del.out &
	trace_create_del_pid=$!

	bpftrace ${workload}/trace_openat.bt -o ${output_dir}/trace_openat.out &
	trace_openat_pid=$!

	bpftrace ${workload}/trace_close.bt -o ${output_dir}/trace_close.out &
	trace_close_pid=$!

	# Start the CPU and GPU traces
	mpstat 1 > ${output_dir}/cpu.out &
	trace_cpu_pid=$!

	#TODO: Explore using Nsight for GPU tracing
	nvidia-smi pmon -s um -o DT -f ${output_dir}/gpu.out &		
	trace_gpu_pid=$!

	echo "Starting training"
	# Start training within the tmux session. 
	tmux send-keys -t $CONTAINER_NAME "sudo ${launch_script}" C-m

	# Get the system-wide PID of the root process ID in the container (bash)
	root_pid=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME)

	echo "root pid: \"$root_pid\""

	# If the previous command did not work (sometimes we must wait a bit), retry in a loop
	while [ -z "$root_pid" ]
	do
		echo "failed to get training pid, trying again"
		sleep 2
		root_pid=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME)
		echo "new try: $root_pid"
	done

	if [ use_strace ]; then
		# Attach the syscall trace to the root_process 
		# It will automatically attach to all spawned child processes
		strace -T -ttt -f -p $root_pid -e 'trace=!ioctl,clock_gettime,clock_nanosleep,sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list,poll,epoll_wait,brk' -o ${output_dir}/strace.out &
	fi

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
