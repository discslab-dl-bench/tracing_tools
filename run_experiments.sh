#!/bin/bash

if [ "${EUID:-$(id -u)}" -ne 0 ]	
	then
		echo "Run script as root"
		exit -1
fi


# gpus=(8 4 2 1)
# mem_sizes=(-1 256 256 256)
# dataset_sizes=(16 200 256 500)

gpus=(1)
mem_sizes=(256) # put -1 if you DO NOT want to limit the container memory size
dataset_sizes=(500)

# 4 cases: 16GB, 200GB, 256GB and 500GB under each data path
# "/raid/data/unet/augmentation/GaussianBlurring_dataset_500GB"
# "/raid/data/unet/augmentation/Sharpening_dataset_500GB"
data_paths=("/raid/data/unet/original_dataset/Original_dataset_500GB")
workload_dir="/dl-bench/ruoyudeng/mlcomns_imseg"
output_dir="/raid/data/unet/trace_results"


if [[ "${#mem_sizes[@]}" != "${#dataset_sizes[@]}" ]]
then
    echo "For each dataset size, you need to write a matching container memory size!"
    echo "Example: mem_sizes=(-1 256), dataset_sizes=(16 200) means that 16GB dataset has no container memory limit, but the 200GB dataset has a 256GB memory limit"
    exit 1
fi



# time the script run time
start=$(date +%s)
for data_path in ${data_paths[@]}; do
    # access bash array with index
    for i in ${!dataset_sizes[@]}; do
        dataset_size="${dataset_sizes[i]}"
        mem_size="${mem_sizes[i]}"
        data_path=$(realpath -s  --canonicalize-missing $data_path) # make it a real path (add missing / or remove extra one)
        data_name=$(echo ${data_path} | awk -F "/" '{print $NF}' | awk -F "_" '{print $1}')
        size=$(echo ${dir_name} | awk -F "_" '{print $NF}')
        data_name_full="${data_name}_${dataset_size}GB"
        start_loop=$(date +%s)
        for gpu in ${gpus[@]}; do
            start_gpu=$(date +%s)
            # run 1 tracing experiment
            exp_name="${gpu}gpu_${data_name_full}"
            # TODO:Implement customized mem size into trace_imseg.sh
            ./trace_imseg.sh $workload_dir $output_dir $gpu $data_path $dataset_size $mem_size $exp_name &
            training_pid=$!
            while kill -0 "$training_pid"; do
                sleep 120 # check whether 1 tracing experiment is done or not in every 2 minutes
            done
            end_gpu=$(date +%s)
            time_insec_gpu=$(( $end_gpu - $start_gpu ))
            echo -e "GPU_NUM: ${gpu}, DATASET: ${data_name}, DATASET_SIZE: ${dataset_size}GB, MEM_SIZE: ${mem_size}GB, took: $(($time_insec_gpu / 3600))hrs $((($time_insec_gpu / 60) % 60))min $(($time_insec_gpu % 60))sec" >> experiments_time_records
        done
    done

done

# keep a records of how long it took for the script to run
end=$(date +%s)
time_insec=$(( $end - $start ))
exp_count=$((${#gpus[@]} * ${#data_paths[@]}))
# all_gpus=$(echo "${gpus[*]}" | awk '$1=$1' FS=" " OFS=",")
echo -e "Ran ${exp_count} experiments in: $(($time_insec / 3600))hrs $((($time_insec / 60) % 60))min $(($time_insec % 60))sec\n\n" >> experiments_time_records

# storing tar files and rezipping
cd $output_dir
sudo mv ./traces* ../trace_results_tar
cd ../trace_results_tar
./rezip.sh
