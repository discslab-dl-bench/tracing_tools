#!/bin/bash

#### Scaffold script to run multiple experiments
#### Uncomment and modify

if [ $# = 1 ]
then
    DRY_RUN=true
else
    DRY_RUN=false
fi


declare -a num_gpus=(2 4 8)

declare -a batch_sizes_dlrm=(2048 4096)
declare -a batch_sizes_bert=()

# # per worker batch sizes
declare -a batch_sizes_unet=(1 2 3 4 5)

declare -a num_workers=(1)

rm -f experiments_run
touch experiments_run


for num_gpu in "${num_gpus[@]}";
do  
    for batch_size in "${batch_sizes_dlrm[@]}"
    do
        exp_name="DLRM_${num_gpu}GPU_batch${batch_size}"

        if [ $DRY_RUN = true ]
        then
            echo $exp_name
        else

            # This DLRM run should be relatively long, eval twice at the middle and at the end
            echo $exp_name | tee -a experiments_run
            ./trace_v2.sh -w dlrm -l /dl-bench/lhovon/mlcomns_dlrm/train_dlrm_terabyte_mmap_bin.sh -c dlrm_loic -n $num_gpu -e $exp_name -- loic $batch_size
            mv /dl-bench/lhovon/mlcomns_dlrm/output/app.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/app.log
            mv /dl-bench/lhovon/mlcomns_dlrm/output/dlrm_tera.log /dl-bench/lhovon/tracing_tools/trace_results/${exp_name}/dlrm.log

        fi
    done
done


BERT_OUTPUT_DIR="/raid/data/bert/run_output"

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 4 -e BERT_horovod_6gpu_6b_2400steps -- -i bert:horovod -g 4 -b 24
mv ${BERT_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_6gpu_6b_2400steps/
rm -rf ${BERT_OUTPUT_DIR}/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 6 -e BERT_horovod_6gpu_6b_2400steps -- -i bert:horovod -g 6 -b 36
mv ${BERT_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_6gpu_6b_2400steps/
rm -rf ${BERT_OUTPUT_DIR}/*

./trace_v2.sh -w bert -l /dl-bench/lhovon/mlcomns_bert/start_training.sh -c train_bert -n 8 -e BERT_horovod_8gpu_6b_2400steps -- -i bert:horovod -g 8 -b 48
mv ${BERT_OUTPUT_DIR}/*.log /dl-bench/lhovon/tracing_tools/trace_results/BERT_horovod_8gpu_6b_2400steps/
rm -rf ${BERT_OUTPUT_DIR}/*

# for num_gpu in "${num_gpus[@]}";
# do  
#     for batch_size in "${batch_sizes_unet[@]}"
#     do
#         for num_worker in "${num_workers[@]}"
#         do
#             exp_name="UNET_huihuo_mpi_${num_gpu}GPU_${batch_size}b_${num_worker}w"
#             echo $exp_name | tee -a experiments_run
#             mkdir -p /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
#             /dl-bench/lhovon/MLPerf_training/image_segmentation/pytorch/start_training.sh $num_gpu unet3d_loic $batch_size unet:all-instr-mpi $num_worker
#             mv /dl-bench/lhovon/MLPerf_training/image_segmentation/pytorch/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name

#             exp_name="UNET_huihuo_mpi_${num_gpu}GPU_${batch_size}b_${num_worker}w_nostep7"
#             echo $exp_name | tee -a experiments_run
#             mkdir -p /dl-bench/lhovon/tracing_tools/trace_results/$exp_name
#             /dl-bench/lhovon/MLPerf_training/image_segmentation/pytorch/start_training.sh $num_gpu unet3d_loic $batch_size unet:all-instr-mpi $num_worker nostep7
#             mv /dl-bench/lhovon/MLPerf_training/image_segmentation/pytorch/output/unet3d.log /dl-bench/lhovon/tracing_tools/trace_results/$exp_name


#         done
#     done
# done

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
