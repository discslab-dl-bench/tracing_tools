#!/bin/bash

# This script will launch and trace the image segmentation workload
# gathering and zipping the traces at the end.  

# CHANGE THIS TO THE ACTUAL LOCATION OF THIS FILE
cd /tracing_tools

# Force running as root -- not the best. Ideally we could use sudo.
if [ "${EUID:-$(id -u)}" -ne 0 ]
then
	echo "Run script as root"
	exit -1
fi

if [ $# -lt 1 ]
then
	echo "Usage: $0 <output_dir> (<experiment_name>)"
	exit 1
fi

output_dir=$1

# Get the optional experiment name
if [ $# -eq 2 ]
then	
	exp_name="${2}"
else
	exp_name="experiment"
fi

# Argument validation

# Fix given paths i.e. remove trailing or extra slashes
output_dir=$(realpath -s  --canonicalize-missing $output_dir)

# Create the output directory
exp_name="${exp_name}_$(date +'%Y%m%d%H%M%S')"
output_dir="${output_dir}/${exp_name}/"

if [ ! -d $output_dir ] 
then
	echo "Creating $output_dir"
	mkdir -p $output_dir
fi

# Flush filesystem caches
sync
echo 3 > /proc/sys/vm/drop_caches

sleep 5

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

bpftrace traces/trace_mmap.bt -o ${output_dir}/trace_mmap.out &
trace_mmap_pid=$!

# Start time alignment trace
bpftrace traces/trace_time_align.bt -o ${output_dir}/trace_time_align.out &
trace_time_align_pid=$!

# Start the CPU trace
mpstat 1 > ${output_dir}/cpu.out &
trace_cpu_pid=$!

# Start the GPU trace
nvidia-smi pmon -s um -o DT -f ${output_dir}/gpu.out &		#TODO: replace with Nsight
trace_gpu_pid=$!

echo "Hit Ctrl-c to stop..."

# idle waiting for ctrl-c from user
read -t 60 -r -d '' _ </dev/tty

echo "60s have passed, killing time_alignment trace"

# Kill the time alignment trace early, 2min should be plenty
kill $trace_time_align_pid

echo "Hit Ctrl-c to stop..."

# idle waiting for ctrl-c from user
read -r -d '' _ </dev/tty

# Kill the traces
kill $trace_bio_pid
kill $trace_read_pid
kill $trace_write_pid
kill $trace_create_del_pid
kill $trace_openat_pid
kill $trace_close_pid
kill $trace_mmap_pid
kill $trace_cpu_pid
kill $trace_gpu_pid

# Kill any remaining traces that didn't get killed above
remaining_traces=$(ps | grep bpf | awk '{print $1}')
for proc in $remaining_traces; 
do	
	kill $proc
done

exit 0
