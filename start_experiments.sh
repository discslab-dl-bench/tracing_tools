#!/bin/bash

# Kill the tmux session from a previous run if it exists
tmux kill-session -t imseg_experiments 2>/dev/null
# Start a new tmux session from which we will run training
tmux new-session -d -s imseg_experiments
tmux send-keys -t imseg_experiments "sudo ./run_experiments.sh" C-m
