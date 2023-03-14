#!/bin/bash

pushd trace_results
for d in $(ls | grep DLRM_LARGE)
do
    echo $d
    tar cvzf ../archive/${d}.tar.gz $d
    [ $? != 0 ] && exit 1
    scp ../archive/${d}.tar.gz lhovon@discslab-server1:/data/lhovon/traces/DLRM_LARGE_BATCHES
done
popd