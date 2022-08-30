#!/bin/bash
workload_dir="/dl-bench/ruoyudeng/mlcomns_imseg"
output_dir="/dl-bench/ruoyudeng/tracing_tools/trace_results"

# number of gpus to use
# gpus=(8)
gpus=(8 4 2 1)


# 4 cases: 16GB, 200GB, 256GB and 500GB under each data path
# "/dl-bench/ruoyudeng/data/augmented_datasets/sharpening_datasets/"
# data_paths=("/dl-bench/ruoyudeng/data/original_datasets/"  "/dl-bench/ruoyudeng/data/augmented_datasets/sharpening_datasets/")
data_paths=("/dl-bench/ruoyudeng/data/original_datasets/")


# time the script run time
start=$(date +%s)
for data_path in ${data_paths[@]}; do
    echo $data_path
    for dir_name in "$data_path"/*; do
        data_path=$(realpath -s  --canonicalize-missing $data_path) # make it a real path (add missing / or remove extra one)
        data_name=$(echo ${data_path} | awk -F "/" '{print $NF}' | awk -F "_" '{print $1}')
        size=$(echo ${dir_name} | awk -F "_" '{print $NF}')
        data_name="${data_name}_${size}"
        # echo $data_name
        # echo $size
        # echo $dir_name
        start_loop=$(date +%s)
        for gpu in ${gpus[@]}; do
            # run 1 tracing experiment
            exp_name="${gpu}gpu_${data_name}"
            echo $exp_name        
            # ./trace_imseg.sh $workload_dir $output_dir $gpu $data_path $exp_name &
            # training_pid=$!
            # while kill -0 "$training_pid"; do
            #     sleep 120 # check whether 1 tracing experiment is done or not in every 2 minutes
            # done
        done
        # all_gpus=$(echo "${gpus[*]}" | awk '$1=$1' FS=" " OFS=",")
        # end_loop=$(date +%s)
        # time_insec=$(( $end_loop - $start_loop ))
        # echo -e "Experiments using GPUs: (${all_gpus}) with ${data_path} took: $(($time_insec / 3600))hrs $((($time_insec / 60) % 60))min $(($time_insec % 60))sec" >> experiments_time_records
    done
    
    
    
done

# keep a records of how long it took for the script to run
# end=$(date +%s)
# time_insec=$(( $end - $start ))
# exp_count=$((${#gpus[@]} * ${#data_paths[@]}))
# all_datasets=$(echo "${data_paths[*]}" | awk '$1=$1' FS=" " OFS="\n") # replace field seperator from space to AND for clear visualization
# all_gpus=$(echo "${gpus[*]}" | awk '$1=$1' FS=" " OFS=",")
# echo -e "Ran ${exp_count} experiments with gpus:(${all_gpus}) and datasets: \n${all_datasets} \nin: $(($time_insec / 3600))hrs $((($time_insec / 60) % 60))min $(($time_insec % 60))sec\n\n" >> experiments_time_records

