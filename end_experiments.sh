#!/bin/bash

./kill_container.sh
./kill_training.sh
./kill_traces.sh
# clear previous results
tmux kill-session -t imseg

rm -rf /dl-bench/ruoyudeng/tracing_tools/trace_results/*
rm -rf /dl-bench/ruoyudeng/mlcomns_imseg/results/*
rm -rf /dl-bench/ruoyudeng/mlcomns_imseg/ckpts/*