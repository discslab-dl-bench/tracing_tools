#!/bin/bash

SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )")


TRACES_DIR=$SCRIPT_DIR/trace_results


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


UNET3D_original_image="unet3d:original"
BERT_original_image="bert:original"
DLRM_original_image="dlrm:original"
Benchmark_original_image="dlio:original"


################
# UNET3D
################

exp_name=UNET3D_8g4b_noinstru
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w unet3d -l /dl-bench/lhovon/mlcomns_unet3d/start_training.sh -c unet3d_original -n $num_gpu -e $exp_name -- $UNET3D_original_image
rm -r $UNET_OUTPUT_DIR/*


# Equivalent Benchmark run
exp_name=UNET3D_benchmark_8GPU_4b
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/benchmark_unet3d.sh -c dlio_unet3d -n 8 -e $exp_name -- $Benchmark_original_image
rm -r $DLIO_OUTPUT_DIR/*



################
# BERT
################

exp_name="BERT_8gb6"
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c bert_original -n 8 -e $exp_name -- $BERT_original_image
rm -r $BERT_OUTPUT_DIR/*

exp_name=BERT_benchmark_8g_b6
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/benchmark_bert.sh -c dlio_bert -n 8 -e $exp_name -- $Benchmark_original_image
rm -r $DLIO_OUTPUT_DIR/*



################
# DLRM
################

exp_name=DLRM_8G_32kglobal
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/start_training.sh -c dlrm_original -n 8 -e $exp_name -- $DLRM_original_image
rm -r $DLRM_OUTPUT_DIR/*


exp_name=DLRM_benchmark_8GPU_b32k
echo "$(date) - $exp_name" | tee -a experiments_run
./trace_v2.sh -w dlio -l /dl-bench/lhovon/dlio/benchmark_dlrm.sh -c dlio_dlrm -n 8 -e $exp_name -- $Benchmark_original_image 32768
rm -r $DLIO_OUTPUT_DIR/*
