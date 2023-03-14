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
declare -a batch_sizes_unet=(5 4 3 2 1)
declare -a batch_sizes_dlrm=(2048 4096 8192 16384 32768 65536 130712 262144)
declare -a batch_sizes_bert=(2 3 4 5 6)


UNET_OUTPUT_DIR="/raid/data/imseg/run_output"
DLRM_OUTPUT_DIR="/raid/data/dlrm/run_output"
BERT_OUTPUT_DIR="/raid/data/bert/run_output"

DLIO_OUTPUT_DIR="/raid/data/dlio/run_output"

rm -f experiments_run
touch experiments_run


rm -r $DLRM_OUTPUT_DIR/*
rm -r $UNET_OUTPUT_DIR/*
rm -r $BERT_OUTPUT_DIR/*


# DLIO - DLRM Experiments
# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_dlrm[@]}"
#     do
#         exp_name="DLIO_DLRM_${num_gpu}GPU_b${batch_size}_instru"
#         if [ ! -d trace_results/$exp_name ]
#         then
#             echo $exp_name | tee -a experiments_run
#             ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:dlrm-instru dlrm $batch_size
#         fi
#     done
# done

# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_unet[@]}"
#     do
#         exp_name="DLIO_UNET_${num_gpu}GPU_b${batch_size}_instru"
#         if [ ! -d trace_results/$exp_name ]
#         then
#             echo $exp_name | tee -a experiments_run
#             ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:unet3d-instru unet3d $batch_size
#         fi
#     done
# done

for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_bert[@]}"
    do
        exp_name="DLIO_BERT_${num_gpu}GPU_b${batch_size}_instru"
        if [ ! -d trace_results/$exp_name ]
        then
            echo $exp_name | tee -a experiments_run
            ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:bert-instru bert $batch_size
        fi
    done
done


# # unet3d:sleep is the real unet3d workload but with a sleep time instead of the real compute
# # I want to check if it affects the dataloading speed
# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_unet[@]}"
#     do
#         exp_name="UNET3D_sleep_${num_gpu}g_${batch_size}b"

#         echo $exp_name | tee -a experiments_run
#         ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:sleep $batch_size

#     done
# done


# unet3d on generated data 1
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}"
    do
        exp_name="UNET3D_gen1_${num_gpu}g_${batch_size}b"
        if [ ! -d trace_results/$exp_name ]
        then
            echo $exp_name | tee -a experiments_run
            ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training_gen.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:loic $batch_size
        fi
    done
done


# unet3d on generated data 2
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}"
    do
        exp_name="UNET3D_gen2_${num_gpu}g_${batch_size}b"
        if [ ! -d trace_results/$exp_name ]
        then
            echo $exp_name | tee -a experiments_run
            ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training_gen2.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:loic $batch_size
        fi
    done
done




exit 0

exp_name="DLIO_DLRM_8GPU_b32k_new_ckpt"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:dlrm dlrm 32768 32768


exp_name="DLIO_DLRM_8GPU_b32k_new_ckpt_2"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:dlrm dlrm 32768 32768




exit 1

exp_name=DLIO_BERT_8GPU_6b_new_ckpt
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert 6


exp_name=DLIO_UNET_8GPU_4b_new_ckpt
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:unet3d unet3d 4

exp_name="DLIO_DLRM_8GPU_b32k_new_ckpt_2"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:dlrm dlrm 32768 32768


exp_name=DLIO_BERT_8GPU_6b_new_ckpt_2
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert 6


exp_name=DLIO_UNET_8GPU_4b_new_ckpt_2
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:unet3d unet3d 4


# regen some insturmented data

exp_name=DLIO_UNET_8GPU_5b_instru
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:unet3d-instru unet3d 5

exp_name=DLIO_BERT_8GPU_3b_instru
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert 3



# Regen UNET instru
rm -rf ${UNET_OUTPUT_DIR}/*

for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}"
    do
        exp_name="UNET_instru_${num_gpu}g_${batch_size}b_1w"

        echo $exp_name | tee -a experiments_run
        ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:loic $batch_size

    done
done



exit 1





# DLRM has a single dataloader process
# exp_name=DLIO_BERT_1thread_48b
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 1 -e $exp_name -- dlio:bert bert_1_comp_thread 48


# exp_name=DLIO_BERT_6b_2
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert 6



exit 1



exp_name="BERT_8GPU_sda"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
rm -r $BERT_OUTPUT_DIR/*

exp_name="BERT_8GPU_sda_2"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
rm -r $BERT_OUTPUT_DIR/*


exp_name=DLRM_8G_32kglobal_32ksteps_noinstru
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:no-instru 32768 16384
rm -r $DLRM_OUTPUT_DIR/*




exp_name=DLIO_UNET_8g4b_npy
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:unet3d unet3d 4

exp_name=UNET_8g4b_noinstru
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:no-instru $batch_size


exit 1
exp_name="BERT_original_8GPU_sda_2"
echo $exp_name | tee -a experiments_run
./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
rm -r $BERT_OUTPUT_DIR/*




# exp_name="BERT_original_8GPU_sda"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
# rm -r $BERT_OUTPUT_DIR/*

# exp_name="BERT_original_8GPU_sda_3"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
# rm -r $BERT_OUTPUT_DIR/*




# exp_name=DLIO_UNET_8g4b_npy
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:unet3d unet3d 4




# # DLIO has PER WORKER batch sizes!!
# exp_name=DLIO_DLRM_8GPU_b16384
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:dlrm dlrm 2048

# exp_name=DLIO_DLRM_8GPU_b32k
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:dlrm dlrm 4096


# exp_name=DLIO_BERT_8GPU_b6_2400s_2
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert 


# exp_name=DLIO_BERT_8GPU_b48_2400s
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert_b48


# exp_name=DLIO_BERT_8GPU_b6_1_comp_thread
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert_1_comp_thread 


# exp_name=UNET_standard_run_log_sda
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w imseg -l /dl-bench/lhovon/mlcomns_imseg/start_training.sh -c unet3d_loic -n 8 -e $exp_name -- unet3d:loic 4







exit 1



# rm -rf ${DLRM_OUTPUT_DIR}/*
# NUM_ELEMENTS=67108864
# declare -a LARGE_BATCH_SIZES_DLRM=(130712 262144 524288 1048576 2097152)
# declare -a NUM_GPUS_LARGE_BATCHES=(4 6)

# for num_gpu in "${NUM_GPUS_LARGE_BATCHES[@]}";
# do  
#     for batch_size in "${LARGE_BATCH_SIZES_DLRM[@]}"
#     do
#         if [ $batch_size -lt 1048576 ]
#         then
#             NUM_STEPS=$(python3 -c "print($NUM_ELEMENTS // $batch_size)")
#         else
#             NUM_STEPS=150
#         fi
#         exp_name="DLRM_LARGE_${num_gpu}g_${batch_size}b_${NUM_STEPS}s"

#         echo $exp_name | tee -a experiments_run
#         ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:loic $batch_size 16384 $NUM_STEPS 1  
#         mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
#         mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
#         rm -rf ${DLRM_OUTPUT_DIR}/*
#     done
# done


# rm -rf ${DLRM_OUTPUT_DIR}/*
# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_dlrm[@]}"
#     do
#         exp_name="DLRM_${num_gpu}g_${batch_size}b_1ks"

#         echo $exp_name | tee -a experiments_run
#         ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:loic $batch_size 16384 1024 1
#         mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
#         mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
#         rm -rf ${DLRM_OUTPUT_DIR}/*
#     done
# done





# rm -rf ${BERT_OUTPUT_DIR}/*






exit 1


# BATCH_SIZE=${4:-2048}
# BATCH_SIZE_EVAL=${5:-16384}
# NUM_BATCHES=${6:-32768}
# NUM_BATCHES_EVAL=${7:-2048}
# NUM_WORKERS=${8:-0}



# DLIO experiments

# exp_name=DLIO_UNET_8GPU_1w_b4_sdbW
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- unet3d

# log_dir=$(ls -d ${DLIO_OUTPUT_DIR}/unet3d/*/ | sort -r | head -n 1)
# mv ${log_dir}/dlio.log trace_results/${exp_name}/
# rm -r ${log_dir}/*

exp_name=DLIO_BERT_8GPU_b6_2400s_sdbW
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- bert

log_dir=$(ls -d ${DLIO_OUTPUT_DIR}/bert/*/ | sort -r | head -n 1)
mv ${log_dir}/dlio.log trace_results/${exp_name}/dlio.log
rm -r ${log_dir}/*


exp_name=DLIO_DLRM_8GPU_b2048_sdbW
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlrm

log_dir=$(ls -d ${DLIO_OUTPUT_DIR}/dlrm/*/ | sort -r | head -n 1)
mv ${log_dir}/dlio.log trace_results/${exp_name}/dlio.log
rm -r ${log_dir}


# Bugfixed UNET3D for step breakdown



# BERT PROFILER TRACES

rm -rf ${BERT_OUTPUT_DIR}/*

for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_bert[@]}"
    do
        exp_name="BERT_horovod_${num_gpu}GPU_batch${batch_size}_profiler"

        echo $exp_name | tee -a experiments_run
        mkdir -p trace_results/$exp_name
        /dl-bench/lhovon/mlcomns_bert/start_training.sh $num_gpu bert_loic $batch_size bert:profiler-horovod
        mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
        mv ${BERT_OUTPUT_DIR}/*.json /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/
        rm -rf ${BERT_OUTPUT_DIR}/*
    done
done


# DLRM - Let's get the all_compute for higher batch sizes!

rm -rf ${DLRM_OUTPUT_DIR}/*
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLRM_${num_gpu}g_${batch_size}b_2ks"

        echo $exp_name | tee -a experiments_run
        ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic $batch_size 16384 2048 1
        mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
        mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
        rm -rf ${DLRM_OUTPUT_DIR}/*
    done
done


# DLRM VERY LARGE BATCH SIZES!!

# 2^26
NUM_ELEMENTS=67108864
declare -a LARGE_BATCH_SIZES_DLRM=(130712 262144 524288 1048576 2097152)
declare -a NUM_GPUS_LARGE_BATCHES=(2)

for num_gpu in "${NUM_GPUS_LARGE_BATCHES[@]}";
do  
    for batch_size in "${LARGE_BATCH_SIZES_DLRM[@]}"
    do
        if [ $batch_size -lt 1048576 ]
        then
            NUM_STEPS=$(python3 -c "print($NUM_ELEMENTS // $batch_size)")
        else
            NUM_STEPS=150
        fi
        exp_name="DLRM_LARGE_${num_gpu}g_${batch_size}b_${NUM_STEPS}s"

        echo $exp_name | tee -a experiments_run
        ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic $batch_size 16384 $NUM_STEPS 1  
        mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
        mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
        rm -rf ${DLRM_OUTPUT_DIR}/*
    done
done




# DLRM - Investigate why every 30sec VFS reads latency spikes up leading to loss of GPU activity



# # Potentially generat emore insight!!!
# exp_name="DLRM_8g2kb0w_eval8k_bc_no_drop"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -s -- dlrm:eval-every-2k 2048 16384 16384 8096
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*


# exp_name="DLRM_8g2kb0w_print-less"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -s -- dlrm:print-less 2048 16384 2048 
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*

# exp_name="DLRM_8g2kb0w_no-tensorboard"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -s -- dlrm:no-tb 2048 16384 2048 
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*


# # First noshuffle some traces looked shifted to the right??
# exp_name="DLRM_8GPU_batch2048_0w_no_shuffle_2"
# echo $exp_name | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic 2048 16384 32768 2048 0 "noshuffle"
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*








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



