#!/bin/bash

# Convenience script to archive and send the traces to a remote server for storage
# Uncomment and modify

# Archive and zip all directories matching pattern
pushd trace_results
for d in $(ls | grep DLIO_)
do
    echo $d
    tar cvzf ../archive/${d}.tar.gz $d
    [ $? != 0 ] && exit 1
    scp ../archive/${d}.tar.gz lhovon@discslab-server1:/data/lhovon/traces/DLIO_new
done
popd

# pushd trace_results
# for d in $(ls | grep -E 'BERT_horovod')
# do
#     echo $d
#     tar cvzf ../archive/${d}.tar.gz $d
#     [ $? != 0 ] && exit 1
#     scp ../archive/${d}.tar.gz lhovon@discslab-server1:/data/lhovon/traces/BERT_horovod_2
# done
# popd


# pushd trace_results
# for d in $(ls | grep ins_original)
# do 
#     tar cvzf ../archive/${d}.tar.gz $d
#     [ $? != 0 ] && exit 1
#     scp ../archive/${d}.tar.gz lhovon@discslab-server1:/data/lhovon/traces/UNET_instrumented_original
# done
# popd


# scp archive/*_1200steps.tar.gz lhovon@discslab-server1:/data/lhovon/traces/BERT_multi_proc_analysis