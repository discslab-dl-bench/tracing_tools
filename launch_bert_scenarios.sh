#!/bin/bash

# Check if launched as root
if [ "${EUID:-$(id -u)}" -ne 0 ]
then
	echo "Run script as root"
	exit -1
fi

root_dir=/home/2020/zdouce/COMP396
tracing_dir=$root_dir/tracing_tools
output_dir=$tracing_dir/trace_results

# Go over each gpu vary amount
for GPU_NUM in 1 2 4 8
do
	# Go over each desired dataset size for each gpu
	for DATA_SIZE in 16 200 256 500
	do
		MEMORY_CONSTRAINT=-1

		# Only constraint if dataset size bigger than 16gb
		if [[ $DATA_SIZE -ne 16 ]]
		then
			MEMORY_CONSTRAINT=256
		fi

		# Simply to keep track of latest file and to know how many runs have been engaged
		RUN_NUMBER=$(< $output_dir/run_number.txt)
		((RUN_NUMBER++))
		echo $RUN_NUMBER > $output_dir/run_number.txt 

		mkdir $output_dir/run_number_$RUN_NUMBER

		echo "Running trace on ${GPU_NUM} gpus, with dataset ${DATA_SIZE}gb, and a memory restriction of ${MEMORY_CONSTRAINT}"
		$tracing_dir/trace_bert.sh $root_dir/mlcomns_bert/ $output_dir/run_number_$RUN_NUMBER ${GPU_NUM} ${MEMORY_CONSTRAINT} ${DATA_SIZE}	
		echo "Finished running scenario"
	done
done

echo "Finished running all scenarios"
exit 0
