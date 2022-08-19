#!/bin/bash

./kill_container.sh
./kill_training.sh
./kill_traces.sh
tmux kill-session -t imseg_experiments