#!/bin/bash
workload_dir="/dl-bench/ruoyudeng/mlcomns_imseg"
output_dir="/dl-bench/ruoyudeng/tracing_tools/trace_results"

# number of gpus to use
# gpus=(8)
gpus=(8 4 2 1)

# new data paths:
# 1. "/data/kits19/preprocessed_data"
# 2. "/raid/data/unet/augmentation/data_Sharpening_preprocess"
data_paths=("/raid/data/unet/augmentation/data_Sharpening_preprocess" "/data/kits19/preprocessed_data") # edit this for more paths

# time the script run time
start=$(date +%s)
for data_path in ${data_paths[@]}; do
    data_name=$(echo ${data_path} | awk -F "/" '{print $NF}')
    if [[ "$data_name" == "preprocessed_data" ]]; then
        data_name="data_Baseline_preprocess"
    fi
    data_name=$(echo ${data_name} | awk -F "_" '{print $2}')
    start_loop=$(date +%s)
    for gpu in ${gpus[@]}; do
        # run 1 tracing experiment
        exp_name="${gpu}gpu_${data_name}"
        echo $exp_name        
        ./trace_imseg.sh $workload_dir $output_dir $gpu $data_path $exp_name &
        training_pid=$!
        while kill -0 "$training_pid"; do
            sleep 120 # check whether 1 tracing experiment is done or not in every 2 minutes
        done
    done
    all_gpus=$(echo "${gpus[*]}" | awk '$1=$1' FS=" " OFS=",")
    end_loop=$(date +%s)
    time_insec=$(( $end_loop - $start_loop ))
    echo -e "Experiments using GPUs: (${all_gpus}) with ${data_path} took: $(($time_insec / 3600))hrs $((($time_insec / 60) % 60))min $(($time_insec % 60))sec" >> experiments_time_records
done

# keep a records of how long it took for the script to run
end=$(date +%s)
time_insec=$(( $end - $start ))
exp_count=$((${#gpus[@]} * ${#data_paths[@]}))
all_datasets=$(echo "${data_paths[*]}" | awk '$1=$1' FS=" " OFS="\n") # replace field seperator from space to AND for clear visualization
all_gpus=$(echo "${gpus[*]}" | awk '$1=$1' FS=" " OFS=",")
echo -e "Ran ${exp_count} experiments with gpus:(${all_gpus}) and datasets: \n${all_datasets} \nin: $(($time_insec / 3600))hrs $((($time_insec / 60) % 60))min $(($time_insec % 60))sec\n\n" >> experiments_time_records

