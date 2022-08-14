#!/bin/bash

# This script will launch and trace the BERT language model workload
# gathering and zipping the traces at the end.  


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

echo "Starting traces"
# Kill the tmux session from a previous run if it exists
tmux kill-session -t dlio_tracing 2>/dev/null

# Start a new tmux session from which we will run training
tmux new-session -d -s dlio_tracing

# Start the bpf traces, storing their pid
bpftrace traces/trace_bio.bt -o ${output_dir}/trace_bio.out &
trace_bio_pid=$!

bpftrace traces/trace_read.bt -o ${output_dir}/trace_read.out &
trace_read_pid=$!

bpftrace traces/trace_write.bt -o ${output_dir}/trace_write.out &
trace_write_pid=$!

bpftrace traces/trace_create_del.bt -o ${output_dir}/trace_create_del.out &
trace_create_del_pid=$!

bpftrace traces/trace_openat.bt -o ${output_dir}/trace_openat.out &
trace_openat_pid=$!

bpftrace traces/trace_close.bt -o ${output_dir}/trace_close.out &
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

echo "Starting DLIO in the dlio_training tmux session"
# Start training within the tmux session. 
tmux send-keys -t dlio_tracing "sudo ${workload_dir}/start_dlio.sh" C-m

# Get the system-wide PID of the root process ID in the container (bash)
root_pid=$(grep -E "NSpid:[[:space:]]+[0-9]+[[:space:]]+1$" /proc/*/status 2> /dev/null | awk '{print $2}')
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
strace -T -ttt -f -p $root_pid -e 'trace=!ioctl,clock_gettime,sched_yield,nanosleep,sched_getaffinity,sched_setaffinity,futex,set_robust_list' -o ${output_dir}/strace.out &

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

# Kill the training process and the traces
# if using strace, it was stopped when root_pid ended
./kill_training.sh
kill $trace_bio_pid
kill $trace_read_pid
kill $trace_write_pid
kill $trace_create_del_pid
kill $trace_openat_pid
kill $trace_close_pid
kill $trace_cpu_pid
kill $trace_gpu_pid

# Kill any remaining traces that didn't get killed above
remaining_traces=$(ps | grep bpf | awk '{print $1}')
for proc in $remaining_traces; 
do	
	kill $proc
done

# # Copy the application log to the results directory
# cp ${workload_dir}/bert.log $output_dir

# # Archive the traces
# output_parent_dir="$(dirname "$output_dir")"
# tar zcvf "${output_parent_dir}/traces_${exp_name}.tar.gz" $output_dir

exit 0
