#!/bin/bash

sudo ./kill_containers.sh
sudo ./kill_training.sh
sudo ./kill_traces.sh
# clear previous results
tmux kill-session -t imseg

sudo rm -rf /dl-bench/ruoyudeng/tracing_tools/trace_results/*
sudo rm -rf /dl-bench/ruoyudeng/mlcomns_imseg/results/*
sudo rm -rf /dl-bench/ruoyudeng/mlcomns_imseg/ckpts/*