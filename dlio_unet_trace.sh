#!/bin/bash



# start=$(date +%s)
# sudo ./trace_dlio.sh $workload_dir $output_dir $num_gpu $generate_data
# end=$(date +%s)
# time_insec=$(( $end - $start ))

workload="dlio"
launch_script="/dl-bench/ruoyudeng/dlio_benchmark/start_dlio.sh"
num_gpu=8
output_dir="/raid/data/unet/trace_results"
exp_name="8gpu_200gb"

# Kill the tmux session from a previous run if it exists
tmux kill-session -t dlio_unet 2>/dev/null
# Start a new tmux session from which we will run training
tmux new-session -d -s dlio_unet
tmux send-keys -t dlio_unet "sudo ./trace_v2.sh -w $workload -l $launch_script -n $num_gpu -o $output_dir -e $exp_name" C-m 
