#!/bin/bash

# Convenience script to archive and send the traces to a remote server for storage
# Uncomment and modify

# Archive and zip all directories matching pattern
pushd trace_results
for d in $(ls | grep _1200steps)
do 
    tar cvzf ../archive/${d}.tar.gz $d
    [ $? != 0 ] && exit 1
done

popd

scp archive/*_1200steps.tar.gz lhovon@discslab-server1:/data/lhovon/traces/BERT_multi_proc_analysis
