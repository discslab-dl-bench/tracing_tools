#!/bin/bash

workdir="/dl-bench/ruoyudeng/mlcomns_imseg"
resultdir="/dl-bench/ruoyudeng/tracing_tools/trace_results"

# "/data/kits19/preprocessed_data"
numgpus=$1
datadir=$2
experiment_name=$3

if [ $# -lt 3 ]
then
    # example: ./trace_imseg_simple.sh 4 /path/to/preprocessed_data exp_4gpus
	echo "Usage: $0 <numgpus> <data_dir> <experiment_name> "
	exit 1
fi

./trace_imseg.sh $workdir $resultdir $numgpus $datadir $experiment_name
