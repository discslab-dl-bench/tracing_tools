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
	echo -e "Attach strace and bpf traces to a running container root PID."
    echo -e "Can be useful if you're modifying code within the container and want to test something."
	echo -e "\nOptions:"
	echo -e "  -h, --help\t\t\tPrint this message"
	echo -e "  -w, --workload\t\tName of the workload. Must be one of bert, dlrm, imseg, dlio or explore"
	echo -e "  -c, --container\t\tName to give the docker container running the workload - defaults to train_{workload}"
	echo -e "  -o, --output-dir\t\tDirectory where to write the traces, defaults to ./trace_results"
	echo -e "  -e, --experiment-name\t\tOptional experiment name, defaults to \"experiment\""
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

	TEMP=$(getopt -o ho:e:w:c: --long help,output-dir:,experiment-name:,workload:,container: \
				-n 'trace_v2' -- "$@")

	if [ $? != 0 ] ; then usage; exit 1 ; fi

	# Note the quotes around '$TEMP': they are essential!
	eval set -- "$TEMP"

	# Default values
	workload=
	container_name=
	exp_name="experiment"
	output_dir="./trace_results"

	while true; do
	case "$1" in
		-h | --help ) usage ;;
		-w | --workload ) workload="$2"; shift 2 ;;
		-c | --container ) container_name="$2"; shift 2 ;;
		-o | --output-dir ) output_dir="$2"; shift 2 ;;
		-e | --experiment-name ) exp_name="$2"; shift 2 ;;
		-- ) shift; break ;;
		* ) usage ;;
	esac
	done

    # Check mandatory parameters were given
	[ -z $container_name ] && echo -e "Container name is mandatory!\n" && usage
	[ -z $workload ] && echo -e "workload name is mandatory!\n" && usage

    # container_name=$1

	# # Default values
	# workload="bert"
	# exp_name="experiment"
	# output_dir="./trace_results"

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

	# Flush filesystem caches to ensure all files are read from disk
	sync
	echo 3 > /proc/sys/vm/drop_caches
	sleep 2

	echo "Starting traces"

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

    # Attach the syscall trace to the root_process 
    # It will automatically attach to all spawned child processes (-f flag)
    strace -T -ttt -f -p $root_pid -e 'trace=!ioctl,clock_gettime,clock_nanosleep,sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list,poll,epoll_wait,brk' -o ${output_dir}/strace.out &

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


	# Sleep a bit more once training stops to capture full shutting down
	sleep 5

	terminate_traces

	echo "All done. Don't forget to copy the application log if you need it for plotting."

	exit 0
}

main $@
