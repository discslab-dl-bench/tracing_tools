#!/bin/bash

#### Scaffold script to run multiple experiments
#### Uncomment and modify


declare -a num_gpus=(2 4 6 8)
declare -a batch_sizes_dlrm=(2048 4096 8192 16384 32768 65536 262144)
declare -a batch_sizes_unet=(1 2 3 4 5)

declare -a batch_sizes_bert=(2 3 4 5 6)


for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_bert[@]}"
    do
        exp_name="BERT_${num_gpu}gpu_${batch_size}b_1200s"
        global_batch_size=$(expr $batch_size \* $num_gpu)
        ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n $num_gpu -e $exp_name -- -i bert:loic -b $global_batch_size -g $num_gpu
        mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
        # cleanup
        rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

        # ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training.sh -c unet3d_loic -n $num_gpu -e UNET_${num_gpu}GPU_batch${batch_size}_nostep7 -- $batch_size
        # mv /dl-bench/lhovon/mlcomns_imseg/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/UNET_${num_gpu}GPU_batch${batch_size}_nostep7

        # ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/train_dlrm_terabyte_mmap_bin.sh -c dlrm_loic -n $num_gpu -e DLRM_${num_gpu}GPU_batch${batch_size} -- loic $batch_size
        # mv /dl-bench/lhovon/mlcomns_dlrm/output/app.log /dl-bench/lhovon/tracing_tools/trace_results/DLRM_${num_gpu}GPU_batch${batch_size}/app.log
        # mv /dl-bench/lhovon/mlcomns_dlrm/output/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/DLRM_${num_gpu}GPU_batch${batch_size}/dlrm.log
    done
done


for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}"
    do
        exp_name="UNET_${num_gpu}GPU_batch${batch_size}_ins"

        ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- $batch_size
        mv /dl-bench/lhovon/mlcomns_imseg/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name

    done
done


# Batch size 4 (multi worker crashes with larger than that)
./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 4 -e BERT_normal_4gpu_4b_1200steps -- -i bert:loic -g 4 -b 16 
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_normal_4gpu_4b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 8 -e BERT_normal_8gpu_4b_1200steps -- -i bert:loic -g 8 -b 32 
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_normal_8gpu_4b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 4 -e BERT_horovod_4gpu_4b_1200steps -- -i bert:horovod -g 4 -b 16
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_4gpu_4b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e BERT_horovod_8gpu_4b_1200steps -- -i bert:horovod -g 8 -b 32
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_8gpu_4b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 4 -e BERT_horovod_4gpu_4b_1200steps -- -i bert:multi-worker -g 4 -b 16
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_4gpu_4b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e BERT_horovod_8gpu_4b_1200steps -- -i bert:multi-worker -g 8 -b 32
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_8gpu_4b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*


# Batch size 6
./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 4 -e BERT_normal_4gpu_6b_1200steps -- -i bert:loic -g 4 -b 24 
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_normal_4gpu_6b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 8 -e BERT_normal_8gpu_6b_1200steps -- -i bert:loic -g 8 -b 48 
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_normal_8gpu_6b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 4 -e BERT_horovod_4gpu_6b_1200steps -- -i bert:horovod -g 4 -b 24
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_4gpu_6b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e BERT_horovod_8gpu_6b_1200steps -- -i bert:horovod -g 8 -b 48
mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_8gpu_6b_1200steps/
rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 4 -e DLIO_bert_test_4gpu_4b_300steps -s -- 4

# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e DLIO_bert_test_4gpu_8b_300steps -- 4
