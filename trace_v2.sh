#!/bin/bash

# This script will launch and trace DLIO.


# Helper function to terminate training and clean up behind us
terminate_traces() {
	# Kill the training process and the traces
	# if using strace, it was stopped when root_pid ended
	docker kill dlio_tracing 2>/dev/null
	docker rm dlio_tracing	2>/dev/null
	tmux kill-session -t dlio_tracing 2>/dev/null

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
	echo -e "Usage: $0 [OPTIONS] [WORKLOAD ARGS]"
	echo -e "\nOptions:"
	echo -e "  -h, --help\t\t\tPrint this message"
	echo -e "  -w, --workload\t\tName of the workload. Must be one of bert, dlrm, imseg, dlio or explore"
	echo -e "                  \t\tWith explore, traces are launched without attaching to a particular workload"
	echo -e "  -l, --launch-script\t\tPath to the workload launch script"
	echo -e "  -c, --container\t\tName to give the docker container running the workload - defaults to train_{workload}"
	echo -e "  -n, --num-gpus\t\tNumber of GPUs to launch the workload with, defaults to 1"
	echo -e "  -o, --output-dir\t\tDirectory where to write the traces, defaults to ./trace_results"
	echo -e "  -e, --experiment-name\t\tOptional experiment name, defaults to \"experiment\""
	echo -e "  -s, --strace\t\t\tUse strace to record all system calls made (very intensive)"
	echo -e "\nWorkload args:"
	echo -e "  Any extra arguments passed after the above options (or after '--') will be passed as is to the workload launch script."
	echo ""
	exit 1
}

main() {

	if [ "${EUID:-$(id -u)}" -ne 0 ]
	then
		echo "Run script as root"
		exit -1
	fi

	# See https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options

	TEMP=$(getopt -o hl:n:o:e:sw:c: --long help,launch-script:,num-gpus:,output-dir:,experiment-name:,strace,workload:,container: \
				-n 'trace_v2' -- "$@")

	if [ $? != 0 ] ; then usage; exit 1 ; fi

	# Note the quotes around '$TEMP': they are essential!
	eval set -- "$TEMP"

	# Default values
	workload=""
	launch_script=
	container_name=
	num_gpus=1
	exp_name="experiment"
	output_dir="./trace_results"
	use_strace=false

	while true; do
	case "$1" in
		-h | --help ) usage ;;
		-w | --workload ) workload="$2"; shift 2 ;;
		-l | --launch-script ) launch_script="$2"; shift 2 ;;
		-c | --container ) container_name="$2"; shift 2 ;;
		-n | --num-gpus ) num_gpus="$2"; shift 2 ;;
		-o | --output-dir ) output_dir="$2"; shift 2 ;;
		-e | --experiment-name ) exp_name="$2"; shift 2 ;;
		-s | --strace ) use_strace=true; shift ;;
		-- ) shift; break ;;
		* ) usage ;;
	esac
	done

	extra_args=$@

	# Check mandatory parameters were given
	[ -z $workload ] && echo -e "Workload is mandatory!\n" && usage

	# Argument validation
	case $workload in
		"bert" ) ;;
		"dlrm" ) ;;
		"imseg" ) ;;
		"dlio" ) ;;
		"explore" ) ;;
		* ) echo "Error: Invalid workload given. Must be one of bert, dlrm, imseg, dlio or explore"; exit 1 ;;
	esac

	[ -z $container_name ] && container_name=train_${workload}

	if [ "$(docker ps -a | grep $container_name)" ]
	then 
		echo "Container name '$container_name' is already used by an existing container."
		echo "Remove the container or choose a different name."
		exit 1
	fi

	# In expore mode, the launch script is optional, but mandatory in other cases
	if [[ $workload != "explore" ]]; then
		[ -z $launch_script ] && echo -e "Launch script is mandatory!\n" && usage
	fi
	# If given, ensure the launch script exists
	[ ! -z $launch_script ] && [ ! -f $launch_script ] && echo -e "Launch script given does not exist!\n" && usage

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
	if ! [[ $num_gpus =~ ^[0-9]+$ ]] ; then
		echo "Error: '$num_gpus' is not a number!"
		usage 
	fi


	# Flush filesystem caches to ensure all files are read from disk
	sync
	echo 3 > /proc/sys/vm/drop_caches
	sleep 2

	echo "Starting traces"
	# Kill the tmux session from a previous run if it exists
	tmux kill-session -t $container_name 2>/dev/null

	# Start a new tmux session from which we will run training
	tmux new-session -d -s $container_name

	# Start the bpf traces, storing their pid
	bpftrace traces/${workload}/trace_bio.bt -o ${output_dir}/trace_bio.out &
	trace_bio_pid=$!

	bpftrace traces/${workload}/trace_read.bt -o ${output_dir}/trace_read.out &
	trace_read_pid=$!

	bpftrace traces/${workload}/trace_write.bt -o ${output_dir}/trace_write.out &
	trace_write_pid=$!

	bpftrace traces/${workload}/trace_create_del.bt -o ${output_dir}/trace_create_del.out &
	trace_create_del_pid=$!

	bpftrace traces/${workload}/trace_openat.bt -o ${output_dir}/trace_openat.out &
	trace_openat_pid=$!

	bpftrace traces/${workload}/trace_close.bt -o ${output_dir}/trace_close.out &
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

	echo "All traces launched"

	# Launch training in a tmux session, and wait until completion. 
	# At this point, if we don't have a launch script, we are in pure exploration mode
	# which is handled in the else clause: we just launch the traces and wait for Ctrl-C
	if [[ ! -z $launch_script ]]; then
		echo "Starting training"
		# Start training within the tmux session, passing any extra arguments
		tmux send-keys -t $container_name "${launch_script} $num_gpus $container_name ${extra_args}" C-m

		# Get the system-wide PID of the root process ID in the container (bash)
		root_pid=$(docker inspect -f '{{.State.Pid}}' $container_name)

		max_retries=100
		# If the previous command did not work (sometimes we must wait a bit), retry in a loop
		while [ -z "$root_pid" ]
		do
			if [ $max_retries == 0 ]; then
				echo "ERROR: Could not get root PID. Exiting."
				terminate_traces
				exit 1
			fi
			max_retries=$(( $max_retries-1 ))
			sleep 0.05
			root_pid=$(docker inspect -f '{{.State.Pid}}' $container_name)
		done

		echo "root pid: \"$root_pid\""

		if [ use_strace ]; then
			# Attach the syscall trace to the root_process 
			# It will automatically attach to all spawned child processes (-f flag)
			strace -T -ttt -f -p $root_pid -e 'trace=!ioctl,clock_gettime,clock_nanosleep,sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list,poll,epoll_wait,brk' -o ${output_dir}/strace.out &
		fi

		# Save PID/TID map for later reference
		docker top $container_name -efT > ${output_dir}/pids_$(date +'%m%d%H%M%S').out

		# Sleep a bit to let training spawn all workers
		sleep 120 && echo "Slept 120s, collecting PIDs/TIDs again and ending time_alignment trace"
		# Capture PIDs/TIDs again now that workload should be in steady state
		docker top $container_name -efT > ${output_dir}/pids_$(date +'%m%d%H%M%S').out

		# Kill the time alignment trace early, 2min should be plenty
		kill $trace_time_align_pid

		echo "Now waiting until training completion"

		while kill -0 "$root_pid"; do
			sleep 5
		done
	else
		# In exploraiton mode, we stop the time alignment trace after 60s 
		# then keep running until Ctrl-C is received
		ps aux -T > ${output_dir}/pids_$(date +'%m%d%H%M%S').out
	
		echo "Hit Ctrl-C to stop... the time alignment trace will stop in 60s"

		# idle waiting for ctrl-c from user for 60s
		read -t 60 -r -d '' _ </dev/tty

		echo "60s have passed, killing time_alignment trace"
		# Kill the time alignment trace early, 2min should be plenty
		kill $trace_time_align_pid

		echo "Hit Ctrl-C to stop..."

		# idle waiting for ctrl-c from user
		read -r -d '' _ </dev/tty

		echo "Ctrl-C received. Stopping trace"
	fi

	# Sleep a bit more once training stops to capture full shutting down
	sleep 5

	terminate_traces

	echo "All done. Don't forget to copy the application log if you need it for plotting."

	exit 0
}

main $@
