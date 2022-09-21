#!/bin/bash
# number of gpus to use
# gpus=(8 4 2 1)

# new data paths:
# 1. "/data/kits19/preprocessed_data"
# 2. "/raid/data/unet/augmentation/data_Sharpening_preprocess"
# data_paths=("/raid/data/unet/augmentation/data_Sharpening_preprocess" "/raid/data/unet/augmentation/data_Reflection_preprocess" "/data/kits19/preprocessed_data") # edit this for more paths

# time_insec=312311
# exp_count=$((${#gpus[@]} * ${#data_paths[@]}))
# all_datasets=$(echo "${data_paths[*]}" | awk '$1=$1' FS=" " OFS="\n") # replace field seperator from space to AND for clear visualization
# all_gpus=$(echo "${gpus[*]}" | awk '$1=$1' FS=" " OFS=",")
# echo -e "Ran ${exp_count} experiments with gpus:(${all_gpus}) and datasets: \n${all_datasets} \nin: $(($time_insec / 3600))hrs $((($time_insec / 60) % 60))min $(($time_insec % 60))sec\n" >> experiments_time_records


data_path="../data/augmented_datasets/sharpening_datasets/"
data_path=$(realpath -s  --canonicalize-missing $data_path)

for dir_name in "$data_path"/*; do
    data_name=$(echo ${data_path} | awk -F "/" '{print $NF}' | awk -F "_" '{print $1}')
    size=$(echo ${dir_name} | awk -F "_" '{print $NF}')
    data_name="${data_name}_${size}"
    echo $data_name
    echo $size
    echo $dir_name
done

# echo 8gpu_sharpening_16GB | awk -F "_" '{print $NF}'