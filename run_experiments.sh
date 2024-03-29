#!/bin/bash

#### Scaffold script to run multiple experiments
#### Uncomment and modify

if [ $# = 1 ]
then
    DRY_RUN=true
else
    DRY_RUN=false
fi


declare -a num_gpus=(8 6 4 2)
declare -a num_workers=(1 2 4 6 8)


# # per worker batch sizes
declare -a batch_sizes_unet=(2 3 4 5)
declare -a batch_sizes_dlrm=(2048 4096 8192 16384)
declare -a batch_sizes_bert=(3 4 5 6)


UNET_OUTPUT_DIR="/raid/data/imseg/run_output"
DLRM_OUTPUT_DIR="/raid/data/dlrm/run_output"
BERT_OUTPUT_DIR="/raid/data/bert/run_output"

DLIO_OUTPUT_DIR="/raid/data/dlio/run_output"

rm -f experiments_run
touch experiments_run


# BATCH_SIZE=${4:-2048}
# BATCH_SIZE_EVAL=${5:-16384}
# NUM_BATCHES=${6:-32768}
# NUM_BATCHES_EVAL=${7:-2048}
# NUM_WORKERS=${8:-0}


# DLRM - Investigate why every 30sec VFS reads latency spikes up leading to loss of GPU activity

rm -rf ${DLRM_OUTPUT_DIR}/*

# Potentially generat emore insight!!!
exp_name="DLRM_8g2kb0w_eval8k_bc_no_drop"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -s -- dlrm:eval-every-2k 2048 16384 16384 8096
mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
rm -rf ${DLRM_OUTPUT_DIR}/*


exp_name="DLRM_8g2kb0w_print-less"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -s -- dlrm:print-less 2048 16384 2048 
mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
rm -rf ${DLRM_OUTPUT_DIR}/*

exp_name="DLRM_8g2kb0w_no-tensorboard"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -s -- dlrm:no-tb 2048 16384 2048 
mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
rm -rf ${DLRM_OUTPUT_DIR}/*


# First noshuffle some traces looked shifted to the right??
exp_name="DLRM_8GPU_batch2048_0w_no_shuffle_2"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic 2048 16384 32768 2048 0 "noshuffle"
mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
rm -rf ${DLRM_OUTPUT_DIR}/*



# UNET3D - With the seed bug fix, for comparison with DLIO, same config.
exp_name="UNET_bugfix_8gb4e50_1w"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training.sh -c unet3d_loic -n 8 -e $exp_name -- 4 unet3d:loic 1
mv ${UNET_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
rm -rf ${UNET_OUTPUT_DIR}/*


exp_name=DLIO_UNET_8GPU_1w_b4
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- unet3d

log_dir=$(ls -d ${DLIO_OUTPUT_DIR}/unet3d/*/ | sort -r | head -n 1)
mv ${log_dir}/dlio.log trace_results/${exp_name}/
rm -r ${log_dir}/*

exp_name=DLIO_BERT_8GPU_b6_2400s
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- bert

log_dir=$(ls -d ${DLIO_OUTPUT_DIR}/bert/*/ | sort -r | head -n 1)
mv ${log_dir}/dlio.log trace_results/${exp_name}/dlio.log
rm -r ${log_dir}/*

log_dir=$(ls -d ${DLIO_OUTPUT_DIR}/bert_eval/*/ | sort -r | head -n 1)
mv ${log_dir}/dlio.log trace_results/${exp_name}/dlio_eval.log
rm -r ${log_dir}/*










# exp_name="BERT_original_1GPU_batch6_strace_writes_and_mmap_analysis"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 2 -e $exp_name -s -- 6 bert:original 1000
# mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
# rm -rf ${BERT_OUTPUT_DIR}/*

# exp_name="BERT_original_2GPU_batch6_strace_writes_and_mmap_analysis"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 2 -e $exp_name -s -- 6 bert:original 1000
# mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
# rm -rf ${BERT_OUTPUT_DIR}/*


# exp_name="BERT_original_8GPU_batch6_short_files"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training_short_files.sh -c bert_loic -n 8 -e $exp_name -s -- 6 bert:original
# mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
# rm -rf ${BERT_OUTPUT_DIR}/*






# #############################################
# # DLIO experiments
# #############################################




# #############################################
# # BERT experiments
# #############################################


# exp_name="BERT_horovod_8GPU_batch6_strace_writes_and_mmap_analysis"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -s -- 6 bert:horovod
# mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
# rm -rf ${BERT_OUTPUT_DIR}/*



# exp_name="BERT_horovod_8GPU_batch6_short_files"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training_short_files.sh -c bert_loic -n 8 -e $exp_name -s -- 6 bert:horovod
# mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
# rm -rf ${BERT_OUTPUT_DIR}/*






# num_gpu=8

# for num_worker in "${num_workers[@]}"
# do
#     exp_name="UNET_original_${num_gpu}GPU_batch4_${num_worker}workers"

#     if [ $DRY_RUN = true ]
#     then
#         echo $exp_name
#     else
#         echo $exp_name | tee -a experiments_run
#         ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- 4 unet3d:loic $num_worker
#         mv ${UNET_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
#         rm -rf ${UNET_OUTPUT_DIR}/*
#     fi
# done


# for num_worker in "${num_workers[@]}"
# do
#     exp_name="DLRM_8GPU_batch2048_${num_worker}workers"

#     if [ $DRY_RUN = true ]
#     then
#         echo $exp_name
#     else
#         echo $exp_name | tee -a experiments_run
#         ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic 2048 $num_worker
#         mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
#         mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
#         rm -rf ${DLRM_OUTPUT_DIR}/*
#     fi
# done

# exp_name="DLRM_8GPU_batch2048_0w_no_shuffle"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic 2048 16384 32768 2048 0 "noshuffle"
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*




# # 200GB UNET - 0.4x, 1x, 2x, 5x 

# exp_name=UNET_200GB_1xmem
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training_200gb.sh -c unet3d_loic -n 8 -e $exp_name -- 2 200
# mv ${UNET_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
# rm -rf ${UNET_OUTPUT_DIR}/*

# exp_name=UNET_200GB_2xmem_2
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training_200gb.sh -c unet3d_loic -n 8 -e $exp_name -- 2 100 1
# mv ${UNET_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
# rm -rf ${UNET_OUTPUT_DIR}/*

# exp_name=UNET_200GB_5xmem_2
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training_200gb.sh -c unet3d_loic -n 8 -e $exp_name -- 2 40 1
# mv ${UNET_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
# rm -rf ${UNET_OUTPUT_DIR}/*


# # UNET 30GB synthetic dataset

# exp_name=UNET_30GB_generated2
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training_on_generated.sh -c unet3d_loic -n 8 -e $exp_name -- 2
# mv ${UNET_OUTPUT_DIR}/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
# rm -rf ${UNET_OUTPUT_DIR}/*







# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_dlrm[@]}"
#     do
#         exp_name="DLRM_${num_gpu}GPU_batch${batch_size}_32ksteps_ckpt"

#         if [ $DRY_RUN = true ]
#         then
#             echo $exp_name
#         else
#             # This DLRM run should be relatively long, eval twice at the middle and at the end
#             echo $exp_name | tee -a experiments_run
#             ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:loic $batch_size
#             mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
#             mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
#             rm -rf ${DLRM_OUTPUT_DIR}/*
#         fi
#     done
# done



# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_bert[@]}"
#     do
#         exp_name="BERT_horovod_${num_gpu}GPU_batch${batch_size}_2400s_eval_1500s"

#         if [ $DRY_RUN = true ]
#         then
#             echo $exp_name
#         else
#             echo $exp_name | tee -a experiments_run
#             ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n $num_gpu -e $exp_name -- $batch_size bert:loic
#             mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
#             rm -rf ${BERT_OUTPUT_DIR}/*
#         fi
#     done
# done




# exit 1


# declare -a num_gpus=(6 8)
# declare -a batch_sizes_unet=(1 2 3 4 5)
# declare -a num_workers=(0 1)

# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_unet[@]}"
#     do
#         for num_worker in "${num_workers[@]}"
#         do
#             exp_name="UNET_huihuo_mpi_${num_gpu}GPU_${batch_size}b_${num_worker}w_nostep7"
#             echo $exp_name | tee -a experiments_run
#             mkdir -p /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
#             /dl-bench/lhovon/MLPerf_training/image_segmentation/pytorch/start_training.sh $num_gpu unet3d_loic $batch_size unet:all-instr-mpi $num_workers nostep7
#             mv /dl-bench/lhovon/MLPerf_training/image_segmentation/pytorch/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name

#             exp_name="UNET_huihuo_ddp_${num_gpu}GPU_${batch_size}b_${num_worker}w_nostep7"
#             echo $exp_name | tee -a experiments_run
#             mkdir -p /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
#             /dl-bench/lhovon/MLPerf_training/image_segmentation/pytorch/start_training.sh $num_gpu unet3d_loic $batch_size unet:all-instr-ddp $num_workers nostep7
#             mv /dl-bench/lhovon/MLPerf_training/image_segmentation/pytorch/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
#         done
#     done
# done



# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_unet[@]}"
#     do
#         exp_name="UNET_${num_gpu}gpu_${batch_size}b_original"

#         ## BERT
#         # global_batch_size=$(expr $batch_size \* $num_gpu)
#         # ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n $num_gpu -e $exp_name -- -i bert:loic -b $global_batch_size -g $num_gpu
#         # mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
#         # # cleanup
#         # rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

#         # # UNET
#         # ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- $batch_size
#         # mv /dl-bench/lhovon/mlcomns_imseg/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
#         # rm -f /dl-bench/lhovon/mlcomns_imseg/ckpts/*

#         ## DLRM
#         # ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/train_dlrm_terabyte_mmap_bin.sh -c dlrm_loic -n $num_gpu -e DLRM_${num_gpu}GPU_batch${batch_size} -- loic $batch_size
#         # mv /dl-bench/lhovon/mlcomns_dlrm/output/app.log /dl-bench/lhovon/tracing_tools/trace_results/DLRM_${num_gpu}GPU_batch${batch_size}/app.log
#         # mv /dl-bench/lhovon/mlcomns_dlrm/output/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/DLRM_${num_gpu}GPU_batch${batch_size}/dlrm.log
#     done
# done




# # Batch size 4 (multi worker crashes with larger than that)
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 4 -e BERT_normal_4gpu_4b_1200steps -- -i bert:loic -g 4 -b 16 
# mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_normal_4gpu_4b_1200steps/
# rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 8 -e BERT_normal_8gpu_4b_1200steps -- -i bert:loic -g 8 -b 32 
# mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_normal_8gpu_4b_1200steps/
# rm -rf /dl-bench/lhovon/mlcomns_bert/output/*




## UNET 3D


# # with 200G dataset
# exp_name="UNET_8GPU_batch2_200gb"
# ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training_200gb.sh -c unet3d_loic -n 8 -e $exp_name -- 2
# mv /dl-bench/lhovon/mlcomns_imseg/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name

# exp_name="UNET_8GPU_batch2_200gb_200gmem"
# ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training_200gb.sh -c unet3d_loic -n 8 -e $exp_name -- 2 200
# mv /dl-bench/lhovon/mlcomns_imseg/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name

# exp_name="UNET_8GPU_batch2_200gb_100gmem"
# ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training_200gb.sh -c unet3d_loic -n 8 -e $exp_name -- 2 100
# mv /dl-bench/lhovon/mlcomns_imseg/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name


# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 8 -e BERT_horovod_8gpu_4b_1200steps -- -i bert:horovod -g 8 -b 32
# mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_8gpu_4b_1200steps/
# rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 4 -e BERT_multiworker_4gpu_4b_1200steps -- -i bert:multi-worker -g 4 -b 16
# mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_multiworker_4gpu_4b_1200steps/
# rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 8 -e BERT_multiworker_8gpu_4b_1200steps -- -i bert:multi-worker -g 8 -b 32
# mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_multiworker_8gpu_4b_1200steps/
# rm -rf /dl-bench/lhovon/mlcomns_bert/output/*


# # Batch size 6
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 4 -e BERT_normal_4gpu_6b_1200steps -- -i bert:loic -g 4 -b 24 
# mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_normal_4gpu_6b_1200steps/
# rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 8 -e BERT_normal_8gpu_6b_1200steps -- -i bert:loic -g 8 -b 48 
# mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_normal_8gpu_6b_1200steps/
# rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 4 -e BERT_horovod_4gpu_6b_1200steps -- -i bert:horovod -g 4 -b 24
# mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_4gpu_6b_1200steps/
# rm -rf /dl-bench/lhovon/mlcomns_bert/output/*

# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 8 -e BERT_horovod_8gpu_6b_1200steps -- -i bert:horovod -g 8 -b 48
# mv /dl-bench/lhovon/mlcomns_bert/output/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_8gpu_6b_1200steps/
# rm -rf /dl-bench/lhovon/mlcomns_bert/output/*


# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 4 -e DLIO_bert_test_4gpu_4b_300steps -s -- 4

# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e DLIO_bert_test_4gpu_8b_300steps -- 4
