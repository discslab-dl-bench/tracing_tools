#!/bin/bash

if [ $# -eq 1 ]
then
    clean="${1}"
else
    clean="no"
fi

sudo ./kill_containers.sh
sudo ./kill_training.sh
sudo ./kill_traces.sh
# clear previous results
tmux kill-session -t imseg

if [[ "$clean" == "clean" ]]
then
    # sudo rm -rf /dl-bench/ruoyudeng/tracing_tools/trace_results/*
    sudo rm -rf /dl-bench/ruoyudeng/mlcomns_imseg/results/*
    # sudo rm -rf /dl-bench/ruoyudeng/mlcomns_imseg/ckpts/*
fi

