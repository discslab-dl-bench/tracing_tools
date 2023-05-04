#!/bin/bash

#### Scaffold script to run multiple experiments

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )")

TRACES_DIR=$SCRIPT_DIR/trace_results

# Define the configuration space we will explore for number of GPUs and batch sizes
declare -a num_gpus=(1 2 4 6 8)

declare -a batch_sizes_unet=(1 2 3 4 5)
declare -a batch_sizes_dlrm=(2048 4096 8192 16384 32768 65536 131072)
declare -a batch_sizes_bert=(1 2 3 4 5 6)


# Checkpoint output directories
# We clean up after each run as they take up space
# and because BERT will try to load from an existing checkpoint
UNET_OUTPUT_DIR="/raid/data/unet3d/run_output"
DLRM_OUTPUT_DIR="/raid/data/dlrm/run_output"
BERT_OUTPUT_DIR="/raid/data/bert/run_output"
DLIO_OUTPUT_DIR="/raid/data/dlio/run_output"

rm -r $DLRM_OUTPUT_DIR/*
rm -r $UNET_OUTPUT_DIR/*
rm -r $BERT_OUTPUT_DIR/*
rm -r $DLIO_OUTPUT_DIR/*

# To keep track of which experiments have run
echo "" >> experiments_run
echo "" >> experiments_run



UNET3D_instru_image="unet3d:instrumented"
UNET3D_sleep_image="unet3d:instrumented"
UNET3D_benchmark_image="dlio:instrumented"


################
# UNET3D
################


# UNET3D instrumented runs
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}";
    do
        exp_name="UNET3D_${num_gpu}g_${batch_size}b"
        log_dir=$TRACES_DIR/$exp_name

        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            /dl-bench/lhovon/mlcomns_imseg/start_training.sh $num_gpu unet3d_run $log_dir $UNET3D_instru_image $batch_size 10
        fi
    done
done


# UNET3D generated data runs -- make sure you've updated the launch script to point to your generated dataset!
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}";
    do
        exp_name="UNET3D_gen_${num_gpu}g_${batch_size}b"
        log_dir=$TRACES_DIR/$exp_name

        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            /dl-bench/lhovon/mlcomns_imseg/start_training_on_generated.sh $num_gpu unet3d_run $log_dir $UNET3D_instru_image $batch_size 10
        fi
    done
done


# UNET3D sleep experiments
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}";
    do
        exp_name="UNET3D_sleep_${num_gpu}g_${batch_size}b"
        log_dir=$TRACES_DIR/$exp_name
        
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            /dl-bench/lhovon/mlcomns_imseg/start_training.sh $num_gpu unet3d_run $log_dir unet3d:sleep $batch_size 10
        fi
    done
done


# Benchmark UNET3D runs
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}";
    do
        exp_name="UNET3D_benchmark_${num_gpu}g_${batch_size}b"
        log_dir=$TRACES_DIR/$exp_name

        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            /dl-bench/lhovon/dlio/start_unet3d.sh $num_gpus unet3d_run $log_dir dlio:latest $batch_size 10
        fi
    done
done


################
# BERT
################





# 1 GPU (and more) simulations
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_bert_exp[@]}"
    do
        exp_name="DLIO_BERT_${num_gpu}GPU_${batch_size}b_extra_batches"
        log_dir=$TRACES_DIR/$exp_name

        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            /dl-bench/lhovon/dlio/start_bert.sh $num_gpu dlio_loic $log_dir dlio:test $batch_size 300 False False
        fi
    done
done







################
# DLRM
################


# DLRM SLEEP - Missing
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLRM_sleep_${num_gpu}g_${batch_size}b"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:sleep $batch_size 16384 4096
            rm -r $DLRM_OUTPUT_DIR/*
        fi
    done
done





exit 



declare -a batch_sizes_unet_exp=(6 8 10 12 14 16 18 20 22 24 26 28 30)

# UNET higher gpus Experiments
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet_exp[@]}"
    do
        exp_name="DLIO_UNET_${num_gpu}GPU_${batch_size}_extra_2"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            /dl-bench/lhovon/dlio/start_training.sh $num_gpu dlio_loic dl-bench/lhovon/tracing_tools/trace_results/$exp_name dlio:unet3d-instru unet3d $batch_size 20
        fi
    done
done



# # DLRM on GENERATED
# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_dlrm[@]}"
#     do
#         exp_name="DLRM_validate_${num_gpu}g_${batch_size}b"
#         if [ ! -d trace_results/$exp_name ]
#         then
#             echo "$(date) - $exp_name" | tee -a experiments_run
#             /dl-bench/lhovon/mlcomns_dlrm/start_training.sh $num_gpu dlrm_loic /dl-bench/lhovon/tracing_tools/trace_results/$exp_name dlrm:validate-instru $batch_size 16384 2048
#             rm -r $DLRM_OUTPUT_DIR/*
#         fi
#     done
# done



# # UNET3D loading only - no processing at all!
# # Let's see how this impacts the throughputs
# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_unet[@]}"
#     do
#         exp_name="UNET3D_validate_${num_gpu}g_${batch_size}b"
#         if [ ! -d trace_results/$exp_name ]
#         then
#             echo "$(date) - $exp_name" | tee -a experiments_run
#             /dl-bench/lhovon/mlcomns_unet3d/start_training.sh $num_gpu unet3d_loic /dl-bench/lhovon/tracing_tools/trace_results/$exp_name unet3d:validate-instru $batch_size 1 20
#         fi
#     done
# done




declare -a batch_sizes_unet_exp=(14)
# new lines for higher gpus
declare -a num_gpus_unet_exp=(8 16 24 32 40)

# UNET higher gpus Experiments
for num_gpu in "${num_gpus_unet_exp[@]}";
do  
    for batch_size in "${batch_sizes_unet_exp[@]}"
    do
        exp_name="DLIO_UNET_${num_gpu}GPU_${batch_size}_extra_2"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:unet3d-instru unet3d $batch_size 20
        fi
    done
done


declare -a num_gpus_dlrm_exp=(8 12 16)
declare -a batch_sizes_dlrm_exp=(131072 262144 524288 1048576 2097152 4194304 8388608)

# DLIO - DLRM Experiments
for num_gpu in "${num_gpus_dlrm_exp[@]}";
do      
    for batch_size in "${batch_sizes_dlrm_exp[@]}"
    do
        exp_name="DLIO_DLRM_${num_gpu}GPU_${batch_size}b_extra"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:dlrm-instru dlrm $batch_size 500
        fi
    done
done


exit

# DLIO - DLRM Experiments
for num_gpu in "${num_gpus[@]}";
do      
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLIO_DLRM_${num_gpu}GPU_${batch_size}b_instru_8"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:dlrm-instru dlrm $batch_size 4096
        fi
    done
done







exit 

# DLRM on GENERATED
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLRM_gen_${num_gpu}g_${batch_size}b_gen_4"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training_on_gen.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:instrumented $batch_size 16384 4096
            rm -r $DLRM_OUTPUT_DIR/*
        fi
    done
done





exit















# DLRM 1GPU and more instrumented runs
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLRM_${num_gpu}g_${batch_size}b_sampleload"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:instrumented $batch_size 16384 4096
            rm -r $DLRM_OUTPUT_DIR/*
        fi
    done
done


exit





exp_name=DLIO_BERT_8gpu_6b_2400s_formula
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert 6

rm -r $BERT_OUTPUT_DIR/*

# missing 128k batch size
echo "$(date) - DLIO_DLRM_1GPU_130712b_formula_2" | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 1 -e "DLIO_DLRM_1GPU_130712b_formula_2" -- dlio:dlrm-instru dlrm 130712 4096



# DLRM SLEEP - Missing
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLRM_sleep_${num_gpu}g_${batch_size}b_apr7"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:sleep $batch_size 16384 4096
            rm -r $DLRM_OUTPUT_DIR/*
        fi
    done
done


# BERT - formula!!
# 1 GPU (and more) simulations
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_bert[@]}"
    do
        exp_name="DLIO_BERT_${num_gpu}GPU_${batch_size}b_formula"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:bert-instru bert $batch_size 300
        fi
    done
done



# On data formatted with same max index number!
# DLIO - DLRM Experiments
for num_gpu in "${num_gpus[@]}";
do      
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLIO_DLRM_${num_gpu}GPU_${batch_size}b_formula_3"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:dlrm-instru dlrm $batch_size 4096
        fi
    done
done







exit

# UNET3D loading only - no processing at all!
# Let's see how this impacts the throughputs
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}"
    do
        exp_name="UNET3D_load_only_${num_gpu}g_${batch_size}b"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:load-only $batch_size
        fi
    done
done

# UNET3D no step 7 - let's see the non-obvious effects on data loading 
# I don't think I ever plotted the throughputs for these experiments!
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}"
    do
        exp_name="UNET3D_nostep7_${num_gpu}g_${batch_size}b"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:no-step-7 $batch_size
        fi
    done
done


# For BERT 1 GPU, need to run with profiler on, since we can't instrument
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_bert[@]}"
    do
        # This way of launching is slightly different and doesn't launch the traces since we don't care about them
        exp_name="BERT_${num_gpu}g_${batch_size}b_profiler_prefetch"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            mkdir -p trace_results/$exp_name
            /dl-bench/lhovon/mlcomns_bert/start_training.sh $num_gpu bert_loic /dl-bench/lhovon/tracing_tools/trace_results/$exp_name bert:profiler-prefetch $batch_size 300
            rm -r trace_results/$exp_name/*.tfevents.*
            rm -r $BERT_OUTPUT_DIR/*
        fi
    done
done

exit


# DLRM 1GPU and more instrumented runs
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLRM_${num_gpu}g_${batch_size}b_sampleload"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:instrumented $batch_size 16384 4096
            rm -r $DLRM_OUTPUT_DIR/*
        fi
    done
done












# DLRM on GENERATED
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLRM_gen_${num_gpu}g_${batch_size}b_sampleload"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training_on_gen.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:instrumented $batch_size 16384 4096
            rm -r $DLRM_OUTPUT_DIR/*
        fi
    done
done



# DLRM SLEEP
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLRM_sleep_${num_gpu}g_${batch_size}b_sampleload"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:sleep $batch_size 16384 4096
            rm -r $DLRM_OUTPUT_DIR/*
        fi
    done
done




# WARNING: This one takes FOREVER to complete
# unet3d on generated data 2 with dataloading further instrumentation
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}";
    do
        exp_name="UNET3D_gen_${num_gpu}g_${batch_size}b"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training_gen.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:instrumented $batch_size 1 10
        fi
    done
done



exit 


# 1 GPU (and more) simulations
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}"
    do
        exp_name="DLIO_UNET_${num_gpu}GPU_b${batch_size}b_sampleload"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:unet3d-instru unet3d $batch_size 20
        fi
    done
done








# unet3d:sleep is the real unet3d workload but with a sleep time instead of the real compute
# I want to check if it affects the dataloading speed
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}"
    do
        exp_name="UNET3D_sleep_${num_gpu}g_${batch_size}b_sampleload"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:sleep $batch_size
        fi
    done
done








exit





# BERT on generated
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_bert[@]}"
    do
        exp_name="BERT_generated_${num_gpu}g_${batch_size}b_profile"
        if [ ! -d trace_results/$exp_name ]
        then
            echo "$(date) - $exp_name" | tee -a experiments_run
            ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training_on_gen.sh -c bert_loic -n $num_gpu -e $exp_name -- bert:profiler $batch_size 300
            rm -r $BERT_OUTPUT_DIR/*
        fi
    done
done










#  This one does not make sense
# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_bert[@]}"
#     do
#         exp_name="DLIO_BERT_${num_gpu}GPU_b${batch_size}b_sampleload"
#         if [ ! -d trace_results/$exp_name ]
#         then
#             echo "$(date) - $exp_name" | tee -a experiments_run
#             ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n $num_gpu -e $exp_name -- dlio:bert bert $batch_size 300
#         fi
#     done
# done










# Warning: These generate like 20GB of data each

# For BERT 1 GPU, need to run with profiler on, since we can't instrument
for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_bert[@]}"
    do
        exp_name="BERT_${num_gpu}g_${batch_size}b_profile"
        echo "$(date) - $exp_name" | tee -a experiments_run
        ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n $num_gpu -e $exp_name -- bert:profiler $batch_size 300
        rm -r $BERT_OUTPUT_DIR/*
    done
done





# # Normal instrumented run - want to see if the very large variance in loading times is consitent
# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_unet[@]}"
#     do
#         exp_name="UNET3D_${num_gpu}g_${batch_size}b_instru"
#         if [ ! -d trace_results/$exp_name ]
#         then
#             echo "$(date) - $exp_name" | tee -a experiments_run
#             ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:instrumented $batch_size 1 20
#             rm -r $UNET_OUTPUT_DIR/*
#         fi
#     done
# done


# # Second full run of sleep just to have more data
# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_unet[@]}"
#     do
#         exp_name="UNET3D_sleep_${num_gpu}g_${batch_size}b_2"
#         if [ ! -d trace_results/$exp_name ]
#         then
#             echo "$(date) - $exp_name" | tee -a experiments_run
#             ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:sleep $batch_size 1 20
#         fi
#     done
# done

















for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_bert[@]}"
    do
        exp_name="BERT_${num_gpu}g_${batch_size}b"
        echo "$(date) - $exp_name" | tee -a experiments_run
        ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c bert_loic -n $num_gpu -e $exp_name -- bert:loic $batch_size
    done
done




done




exit 0

exp_name="DLIO_DLRM_8GPU_b32k_new_ckpt"
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:dlrm dlrm 32768 32768


exp_name="DLIO_DLRM_8GPU_b32k_new_ckpt_2"
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:dlrm dlrm 32768 32768








# Regen UNET instru
rm -rf ${UNET_OUTPUT_DIR}/*

for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_unet[@]}"
    do
        exp_name="UNET_instru_${num_gpu}g_${batch_size}b_1w"

        echo "$(date) - $exp_name" | tee -a experiments_run
        ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:loic $batch_size

    done
done



exit 1





# DLRM has a single dataloader process
# exp_name=DLIO_BERT_1thread_48b
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 1 -e $exp_name -- dlio:bert bert_1_comp_thread 48






exit 1



exp_name="BERT_8GPU_sda"
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
rm -r $BERT_OUTPUT_DIR/*

exp_name="BERT_8GPU_sda_2"
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
rm -r $BERT_OUTPUT_DIR/*


exp_name=DLRM_8G_32kglobal_32ksteps_noinstru
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:no-instru 32768 16384
rm -r $DLRM_OUTPUT_DIR/*




exp_name=DLIO_UNET_8g4b_npy
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:unet3d unet3d 4

exp_name=UNET_8g4b_noinstru
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- unet3d:no-instru $batch_size


./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n $num_gpu -e $exp_name -- dlrm:loic $batch_size 16384 $NUM_STEPS 1  

exit 1
exp_name="BERT_original_8GPU_sda_2"
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
rm -r $BERT_OUTPUT_DIR/*




# exp_name="BERT_original_8GPU_sda"
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
# rm -r $BERT_OUTPUT_DIR/*

# exp_name="BERT_original_8GPU_sda_3"
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -- bert:loic 6 2400
# rm -r $BERT_OUTPUT_DIR/*




# exp_name=DLIO_UNET_8g4b_npy
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:unet3d unet3d 4




# # DLIO has PER WORKER batch sizes!!
# exp_name=DLIO_DLRM_8GPU_b16384
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:dlrm dlrm 2048

# exp_name=DLIO_DLRM_8GPU_b32k
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:dlrm dlrm 4096


# exp_name=DLIO_BERT_8GPU_b6_2400s_2
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert 


# exp_name=DLIO_BERT_8GPU_b48_2400s
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert_b48


# exp_name=DLIO_BERT_8GPU_b6_1_comp_thread
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/start_training.sh -c dlio_loic -n 8 -e $exp_name -- dlio:bert bert_1_comp_thread 


# exp_name=UNET_standard_run_log_sda
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_loic -n 8 -e $exp_name -- unet3d:loic 4







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

#         echo "$(date) - $exp_name" | tee -a experiments_run
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

#         echo "$(date) - $exp_name" | tee -a experiments_run
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

        echo "$(date) - $exp_name" | tee -a experiments_run
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

        echo "$(date) - $exp_name" | tee -a experiments_run
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

        echo "$(date) - $exp_name" | tee -a experiments_run
        ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic $batch_size 16384 $NUM_STEPS 1  
        mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
        mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
        rm -rf ${DLRM_OUTPUT_DIR}/*
    done
done




# DLRM - Investigate why every 30sec VFS reads latency spikes up leading to loss of GPU activity



# # Potentially generat emore insight!!!
# exp_name="DLRM_8g2kb0w_eval8k_bc_no_drop"
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -s -- dlrm:eval-every-2k 2048 16384 16384 8096
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*


# exp_name="DLRM_8g2kb0w_print-less"
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -s -- dlrm:print-less 2048 16384 2048 
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*

# exp_name="DLRM_8g2kb0w_no-tensorboard"
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -s -- dlrm:no-tb 2048 16384 2048 
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*


# # First noshuffle some traces looked shifted to the right??
# exp_name="DLRM_8GPU_batch2048_0w_no_shuffle_2"
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic 2048 16384 32768 2048 0 "noshuffle"
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*








# exp_name="BERT_original_1GPU_batch6_strace_writes_and_mmap_analysis"
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 2 -e $exp_name -s -- 6 bert:original 1000
# mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
# rm -rf ${BERT_OUTPUT_DIR}/*

# exp_name="BERT_original_2GPU_batch6_strace_writes_and_mmap_analysis"
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 2 -e $exp_name -s -- 6 bert:original 1000
# mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
# rm -rf ${BERT_OUTPUT_DIR}/*


# exp_name="BERT_original_8GPU_batch6_short_files"
# echo "$(date) - $exp_name" | tee -a experiments_run
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
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_loic -n 8 -e $exp_name -s -- 6 bert:horovod
# mv ${BERT_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/bert.log
# rm -rf ${BERT_OUTPUT_DIR}/*



# exp_name="BERT_horovod_8GPU_batch6_short_files"
# echo "$(date) - $exp_name" | tee -a experiments_run
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
#         echo "$(date) - $exp_name" | tee -a experiments_run
#         ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_loic -n $num_gpu -e $exp_name -- 4 unet3d:loic $num_worker
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
#         echo "$(date) - $exp_name" | tee -a experiments_run
#         ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic 2048 $num_worker
#         mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
#         mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
#         rm -rf ${DLRM_OUTPUT_DIR}/*
#     fi
# done

# exp_name="DLRM_8GPU_batch2048_0w_no_shuffle"
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_loic -n 8 -e $exp_name -- dlrm:loic 2048 16384 32768 2048 0 "noshuffle"
# mv ${DLRM_OUTPUT_DIR}/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
# mv ${DLRM_OUTPUT_DIR}/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log
# rm -rf ${DLRM_OUTPUT_DIR}/*




# # 200GB UNET - 0.4x, 1x, 2x, 5x 

# exp_name=UNET_200GB_1xmem
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training_200gb.sh -c unet3d_loic -n 8 -e $exp_name -- 2 200
# mv ${UNET_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
# rm -rf ${UNET_OUTPUT_DIR}/*

# exp_name=UNET_200GB_2xmem_2
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training_200gb.sh -c unet3d_loic -n 8 -e $exp_name -- 2 100 1
# mv ${UNET_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
# rm -rf ${UNET_OUTPUT_DIR}/*

# exp_name=UNET_200GB_5xmem_2
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training_200gb.sh -c unet3d_loic -n 8 -e $exp_name -- 2 40 1
# mv ${UNET_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
# rm -rf ${UNET_OUTPUT_DIR}/*


# # UNET 30GB synthetic dataset

# exp_name=UNET_30GB_generated2
# echo "$(date) - $exp_name" | tee -a experiments_run
# ./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training_on_generated.sh -c unet3d_loic -n 8 -e $exp_name -- 2
# mv ${UNET_OUTPUT_DIR}/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
# rm -rf ${UNET_OUTPUT_DIR}/*



