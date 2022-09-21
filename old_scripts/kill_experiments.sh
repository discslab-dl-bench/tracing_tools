#!/bin/bash

sudo ./kill_container.sh
sudo ./kill_training.sh
sudo ./kill_traces.sh
# clear previous results
tmux kill-session -t imseg