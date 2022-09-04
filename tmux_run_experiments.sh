#!/bin/bash

# Kill the tmux session from a previous run if it exists
tmux kill-session -t imseg 2>/dev/null
# Start a new tmux session from which we will run training
tmux new-session -d -s imseg
tmux send-keys -t imseg "sudo ./dl-bench/ruoyudeng/tracing_tools/run_experiments.sh" C-m
