#!/bin/bash

workload_dir="/dl-bench/ruoyudeng/dlio_benchmark"
output_dir="/dl-bench/ruoyudeng/tracing_tools/trace_results"
num_gpu=8
generate_data=no

start=$(date +%s)
sudo ./trace_dlio.sh $workload_dir $output_dir $num_gpu $generate_data
end=$(date +%s)
time_insec=$(( $end - $start ))

echo -e "8gpu_500gb DLIO_unet simulation ran in: $(($time_insec / 3600))hrs $((($time_insec / 60) % 60))min $(($time_insec % 60))sec\n\n" >> experiments_time_records