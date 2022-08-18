#!/bin/bash

workdir="/dl-bench/ruoyudeng/mlcomns_imseg"
resultdir="/dl-bench/ruoyudeng/tracing_tools/trace_results"


numgpus=$1

if [ $# -lt 1 ]
then
	echo "Usage: $0 <numgpus>"
	exit 1
fi

./trace_imseg.sh $workdir $resultdir $numgpus
