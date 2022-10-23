#!/bin/bash

# A driver script which runs the trace_dlrm.sh

workload_dir=/dl-bench/zhongjie/mlcomns_dlrm
output_dir=/raid/data/dlrm/dlrm_tracing
num_gpus=8
data_path=TODO
dataset_size=TODO
mem_constraints=TODO

sudo ./trace_dlrm.sh $workload_dir $output_dir $num_gpus $data_path $dataset_size $mem_constraints terabyte_tracing