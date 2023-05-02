#!/bin/bash

# Convenience script to archive and send the traces to a remote server for storage
# Uncomment and modify

# Archive and zip all directories matching pattern

pushd trace_results

for d in $(ls | grep -E 'UNET3D_sleep')
do
    echo $d

    if [ ! -f ../archive/${d}.tar.gz ]
    then
        tar cvzf ../archive/${d}.tar.gz $d
        [ $? != 0 ] && exit 1
        ssh lhovon@discslab-server1 "mkdir -p /data/lhovon/traces/UNET3D_sleep_3"
        scp ../archive/${d}.tar.gz lhovon@discslab-server1:/data/lhovon/traces/UNET3D_sleep_3
        
        ssh lhovon@discslab-server1 "mkdir -p /data/lhovon/trace_visuals/data/mar18/UNET3D_sleep_3"
        scp -r $d lhovon@discslab-server1:/data/lhovon/trace_visuals/data/mar18/UNET3D_sleep_3

        ssh lhovon@discslab-server1 "/data/lhovon/trace_visuals/.venv/bin/python3 /data/lhovon/trace_visuals/preprocess_traces.py /data/lhovon/trace_visuals/data/mar18/UNET3D_sleep_3/$d unet3d"
    fi
done

popd

