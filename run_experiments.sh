#!/bin/bash
workload_dir="/dl-bench/ruoyudeng/mlcomns_imseg"
output_dir="/dl-bench/ruoyudeng/tracing_tools/trace_results"
gpus=(8 4 2 1)
data_paths=("/data/kits19/preprocessed_data/") # edit this for more paths

for data_path in ${data_paths[@]}; do
    for gpu in ${gpus[@]}; do
        # run 1 tracing experiment
        exp_name="${gpu}gpu"        
        ./trace_imseg.sh $workload_dir $output_dir $gpu $data_path $exp_name &
        training_pid=$!
        while kill -0 "$training_pid"; do
            sleep 120 # check whether 1 tracing experiment is done or not in every 2 minutes
        done
        echo "GPU: $gpu, Data: $data_path done"
    done
done
