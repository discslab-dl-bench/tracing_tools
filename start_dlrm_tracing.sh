#!/bin/bash

# A driver script which runs the trace_dlrm.sh

workload_dir=/dl-bench/zhongjie/mlcomns_dlrm
output_dir=/dl-bench/zhongjie/dlrm_log
num_gpus=8
data_path=TODO
dataset_size=TODO
mem_constraints=TODO

sudo ./trace_dlrm workload output num_gpus data_path dataset_size mem_constraints