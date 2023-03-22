#!/bin/bash
MAX_NUM_GPUS=8

workload=""
launch_script=
container_name=
num_gpus=1
num_jobs=1
exp_name="experiment"
output_dir="./trace_results"
use_strace=false
extra_args=

trace_bio_pid=
trace_read_pid=
trace_write_pid=
trace_create_del_pid=
trace_openat_pid=
trace_close_pid=
trace_time_align_pid=
trace_syscalls_pid=
trace_gpu_pid=
iostat_pid=

jobs_pids=()

main() {
	checkPermissionAndExit
	getVars	$@
	validateArguments
	setupVars
	clearCache
	flushSystem
	startAllTmuxes
	launchAllTraces
	launchTraining
	waitAFewSeconds
	getLaunchedJobsPIDs
	performStrace
	waitAllTrainingFinished
	flushSystem
	terminateTraces $container_name
	echo "All done. Don't forget to copy the application log if you need it for plotting."
	exit 0
}

checkPermissionAndExit() {
	if [ "${EUID:-$(id -u)}" -ne 0 ]
	then
		echo "Run script as root"
		exit -1
	fi
}

getVars() {
	TEMP=$(getopt -o hl:n:j:o:e:sw:c: --long help,launch-script:,num-gpus:,num-jobs:,output-dir:,experiment-name:,strace,workload:,container: -n 'trace_v2' -- "$@")
	if [ $? != 0 ] ; then usage; exit 1 ; fi
	eval set -- "$TEMP"

	while true; do
	case "$1" in
		-h | --help ) usage ;;
		-w | --workload ) workload="$2"; shift 2 ;;
		-l | --launch-script ) launch_script="$2"; shift 2 ;;
		-c | --container ) container_name="$2"; shift 2 ;;
		-n | --num-gpus ) num_gpus="$2"; shift 2 ;;
		-j | --num-jobs ) num_jobs="$2"; shift 2 ;;
		-o | --output-dir ) output_dir="$2"; shift 2 ;;
		-e | --experiment-name ) exp_name="$2"; shift 2 ;;
		-s | --strace ) use_strace=true; shift ;;
		-- ) shift; break ;;
		* ) usage ;;
	esac
	done

	extra_args=$@
}

validateArguments() {
	checkWorkloadIsOfEnumeration
	checkLaunchScriptExist
	checkGPUNumeric
	checkNumJobsGpusGood
}

checkWorkloadIsOfEnumeration() {
	[ -z "$workload" ] && echo -e "Workload is mandatory!\n" && usage
	
	case $workload in
		"bert" ) ;;
		"dlrm" ) ;;
		"imseg" ) ;;
		"dlio" ) ;;
		"explore" ) ;;
		* ) echo "Error: Invalid workload given. Must be one of bert, dlrm, imseg, dlio or explore"; exit 1 ;;
	esac
}

checkLaunchScriptExist() {
	if [[ "$workload" != "explore" ]]; then
		[ -z $launch_script ] && echo -e "Launch script is mandatory!\n" && usage
	fi

	[ ! -z $launch_script ] && [ ! -f $launch_script ] && echo -e "Launch script given does not exist!\n" && usage
}

checkGPUNumeric() {
	if ! [[ $num_gpus =~ ^[0-9]+$ ]] ; then
		echo "Error: '$num_gpus' is not a number!"
		usage 
	fi
}

checkNumJobsGpusGood() {
	if [ $(($num_gpus * $num_jobs)) -gt $MAX_NUM_GPUS ]; then
		echo "Error: there exists not enough GPUs for the given parameters"
		exit 1
	fi
}

setupVars() {
	setupOutputDirectory
	setupContainerName
	ensureContainerNameNotTakenErrOtherwise
}

setupOutputDirectory() {
	output_dir=$(realpath -s  --canonicalize-missing $output_dir)
	output_dir="${output_dir}/${exp_name}"

	if [ ! -d $output_dir ] 
	then
		echo "Creating $output_dir"
		mkdir -p $output_dir
	fi
}

setupContainerName() {
	[ -z "$container_name" ] && container_name=train_${workload}
}

ensureContainerNameNotTakenErrOtherwise() {
	if [ "$(docker ps -a | grep $container_name)" ]
	then 
		echo "Container name '$container_name' is already used by an existing container."
		echo "Remove the container or choose a different name."
		exit 1
	fi
}

clearCache() {
	echo 3 > "/proc/sys/vm/drop_caches"
}

flushSystem() {
	sync
	waitAFewSeconds
}

startAllTmuxes() {
	if [ $num_jobs -eq 1 ]; then 
		startTmux $container_name
	else
		for ((i=0; i<$num_jobs; i++)); do
			echo "Starting tmux ${container_name}-${i}"
			startTmux "${container_name}-${i}"
		done
	fi
}

startTmux() {	
	killPreviousTmuxFromContainerNameIfExists $1
	startNewTmuxSessionFromContainerName $1
}

killPreviousTmuxFromContainerNameIfExists() {
	tmux kill-session -t $1 2>/dev/null
}

startNewTmuxSessionFromContainerName() {
	tmux new-session -d -s $1
}

launchAllTraces() {
	echo "Starting traces"
	startBpfTraces
	startGpuCpuTrace
	startMonitoringGpuMemoryUse
	startIOStat
	echo "All traces launched"
}

startBpfTraces() {
  trace_bio_pid=$(launchBpfTraceFromWorkload "trace_bio")
  trace_read_pid=$(launchBpfTraceFromWorkload "trace_read")
  trace_write_pid=$(launchBpfTraceFromWorkload "trace_write")
  trace_create_del_pid=$(launchBpfTraceFromWorkload "trace_create_del")
  trace_openat_pid=$(launchBpfTraceFromWorkload "trace_openat")
  trace_close_pid=$(launchBpfTraceFromWorkload "trace_close")
  trace_time_align_pid=$(launchBpfTraceFromTraceDirectory "trace_time_align")
  trace_syscalls_pid=$(launchBpfTraceFromTraceDirectory "syscalls")
}

launchBpfTraceFromWorkload() {
	echo $(launchBpfTrace "traces/${workload}/${1}.bt" "${output_dir}/${1}.out")
}

launchBpfTraceFromTraceDirectory() {
	echo $(launchBpfTrace "traces/${1}.bt" "${output_dir}/${1}.out")
}

launchBpfTrace() {
	bpftrace $1 -o $2 &> /dev/null &
	echo $!
}

startGpuCpuTrace() {
	mpstat 1 > ${output_dir}/cpu.out &
	trace_cpu_pid=$!
}

startMonitoringGpuMemoryUse() {
	nvidia-smi pmon -s um -o DT -f ${output_dir}/gpu.out &		
	trace_gpu_pid=$!
}

startIOStat() {
	iostat -mdxty sda sdb 1 -o JSON	> ${output_dir}/iostat.json &
	iostat_pid=$!
}

launchTraining() {
	if [[ ! -z $launch_script ]]; then
		launchAsWorkload
	else
		launchAsExploration
	fi
}

launchAsWorkload() {
	if [ $num_jobs -eq 1 ]; then 
		launchJob $container_name $launch_script "-o ${output_dir}"
	else 
		for ((i=0; i<$num_jobs; i++)); do 
			mkdir "${output_dir}/job${i}"
			launchJob "$container_name-$i" $launch_script "-x $(getGpuNum $i) -o ${output_dir}/job${i}"
		done
	fi
}

getGpuNum() {
	output=""
	for ((i=0; i<$num_gpus; i++)); do
		output+="$(($i + $num_gpus * $1)),"
	done
	echo ${output%,}
}

launchJob() {
	echo "Starting training with command: $2 $num_gpus $1 $3 $extra_args"
	tmux send-keys -t $1 "$2 $num_gpus $1 $3 $extra_args" C-m
}

getLaunchedJobsPIDs() {
	if [ $num_jobs -eq 1 ]; then
		pid=$(getPIDOfLaunchedWorkload $container_name)
		jobs_pid+=($pid)
		echo "root pid: \"$pid\""
	else 
		for ((i=0; i<$num_jobs; i++)); do 
			pid=$(getPIDOfLaunchedWorkload "$container_name-$i")
			jobs_pids+=($pid)
			echo "root of job $i pid: \"$pid\""
		done
	fi
}

getPIDOfLaunchedWorkload() {
	maxAttempts=100
	pid=$(getPIDOfRootOfContainer $1)
	while [ -z "$pid" ]
	do
		if [ $maxAttempts == 0 ]; then
			echo "ERROR: Could not get root PID. Exiting." > /dev/tty
			terminate_traces $1
			exit 1
		fi
		echo "Attempt: $maxAttempts, PID: $pid" > /dev/tty
		maxAttempts=$(( $maxAttempts - 1 ))
		sleep 0.05
		pid=$(getPIDOfRootOfContainer $1)
	done
	echo $pid
}

getPIDOfRootOfContainer() {
	pid=$(docker inspect -f '{{.State.Pid}}' $1) 2>/dev/null
	echo $pid
}


attachStraceToPid() {
	strace -T -tt -f -p $1 -e 'trace=!ioctl,clock_gettime,clock_nanosleep,sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list,poll,epoll_wait,brk' -o ${output_dir}/strace.out &
}

launchAsExploration() {
	ps aux -T > ${output_dir}/pids_$(date +'%m%d%H%M%S').out
	echo "Hit Ctrl-C to stop... the time alignment trace will stop in 60s"
	read -t 60 -r -d '' _ </dev/tty
	echo "60s have passed, killing time_alignment trace"
	kill $trace_time_align_pid
	echo "Hit Ctrl-C to stop..."
	read -r -d '' _ </dev/tty
	echo "Ctrl-C received. Stopping trace"
}

performStrace() {
	if $use_strace; then
		attachStraceToPid $root_pid_launched_workload
	fi
	sleep 120 && echo "Slept 120s, collecting PIDs/TIDs again and ending time_alignment trace"
	for ((i=0; i<$num_jobs; i++)); do
		docker top "${container_name}-${i}" -efT >> ${output_dir}/pids_$(date +'%m%d%H%M%S').out
	done
	
	kill $trace_time_align_pid
	echo "Now waiting until training completion"
}

waitAllTrainingFinished() {
	for pid in "${jobs_pids[@]}"; do
		while kill -0 "$pid"; do
			sleep 5
		done
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
	echo -e "  -n, --num-gpus\t\tNumber of GPUs to launch a single instance of the workload with, defaults to 1"
	echo -e "  -j, --num-jobs\t\tNumber of instances to run the workload, dividing available GPUs evenly"
	echo -e "  -o, --output-dir\t\tDirectory where to write the traces, defaults to ./trace_results"
	echo -e "  -e, --experiment-name\t\tOptional experiment name, defaults to \"experiment\""
	echo -e "  -s, --strace\t\t\tUse strace to record all system calls made (very intensive)"
	echo -e "\nWorkload args:"
	echo -e "  Any extra arguments passed after the above options (or after '--') will be passed as is to the workload launch script."
	echo ""
	exit 1
}

terminateTraces() {
	if [ $num_jobs -eq 1 ]; then 
		docker kill $1 2>/dev/null
	else 
		for ((i=0; i<$num_jobs; i++)); do 
			docker kill "${1}-${i}" 2>/dev/null
		done
	fi
	killAllTraces
	killRemainingTraces
}

killAllTraces() {
	kill $trace_bio_pid
	kill $trace_read_pid
	kill $trace_write_pid
	kill $trace_create_del_pid
	kill $trace_openat_pid
	kill $trace_close_pid
	kill $trace_cpu_pid
	kill $trace_gpu_pid
	kill $trace_syscalls_pid
	kill -SIGINT $iostat_pid 	# Kill iostat nicely to keep json structured	
}

killRemainingTraces() {
	remaining_traces=$(ps | grep bpftrace | awk '{print $1}')
	for proc in $remaining_traces; 
	do	
		kill $proc
	done
}

waitAFewSeconds() {
	sleep 10
}

main $@
