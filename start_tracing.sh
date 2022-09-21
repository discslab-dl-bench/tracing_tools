#!/bin/bash


# Kill the tmux session from a previous run if it exists
tmux kill-session -t dlio_unet 2>/dev/null
# Start a new tmux session from which we will run training
tmux new-session -d -s dlio_unet
tmux send-keys -t dlio_unet "sudo ./trace_v2.sh -w dlio -l /dl-bench/ruoyudeng/dlio_benchmark/start_dlio.sh -n 8 -o /raid/data/unet/trace_results -e 8gpu_500gb" C-m 
