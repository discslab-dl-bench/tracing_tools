#!/bin/bash
workload_dir="/dl-bench/ruoyudeng/mlcomns_imseg"
output_dir="/dl-bench/ruoyudeng/tracing_tools/trace_results"
gpus=(8 4 2 1)

# new data paths:
# 1. "/data/kits19/preprocessed_data"
# 2. "/raid/data/unet/augmentation/data_Sharpening_preprocess"
data_paths=("/raid/data/unet/augmentation/data_Sharpening_preprocess") # edit this for more paths

for data_path in ${data_paths[@]}; do
    data_name=$(echo ${data_path} | awk -F "/" '{print $NF}')
    if [[ "$data_name" == "preprocessed_data" ]]; then
        data_name="data_Baseline_preprocess"
    fi
    data_name=$(echo ${data_name} | awk -F "_" '{print $2}')
    for gpu in ${gpus[@]}; do
        # run 1 tracing experiment
        exp_name="${gpu}gpu_${data_name}"
        echo $exp_name        
        ./trace_imseg.sh $workload_dir $output_dir $gpu $data_path $exp_name &
        training_pid=$!
        while kill -0 "$training_pid"; do
            sleep 120 # check whether 1 tracing experiment is done or not in every 2 minutes
        done
        echo "GPU: $gpu, Data: $data_path done"
    done
done
