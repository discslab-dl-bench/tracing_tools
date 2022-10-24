#!/bin/bash

# A driver script which runs the trace_dlrm.sh

workload_dir=/dl-bench/zhongjie/dlio_benchmark
output_dir=/raid/data/dlio_dlrm/dlrm_tracing
num_gpus=8
data_path=TODO
dataset_size=TODO
mem_constraints=TODO

sudo ./trace_dlio.sh $workload_dir $output_dir dlio_dlrm_tracing