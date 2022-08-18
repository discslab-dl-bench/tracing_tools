#!/bin/bash

workdir="/dl-bench/ruoyudeng/mlcomns_imseg"
resultdir="/dl-bench/ruoyudeng/tracing_tools/trace_results"


numgpus=$1
experiment_name=$2

if [ $# -lt 2 ]
then
    # example: ./trace_imseg_simple.sh 4 exp_4gpus
	echo "Usage: $0 <numgpus> <experiment_name>"
	exit 1
fi

./trace_imseg.sh $workdir $resultdir $numgpus
