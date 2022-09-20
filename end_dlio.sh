#!/bin/bash

sudo docker kill train_dlio
sudo docker rm train_dlio
sudo tmux kill-session -t dlio_tracing
tmux kill-session -t dlio_unet
sudo ./kill_traces.sh