#!/bin/bash

sudo docker kill dlio_training
sudo docker rm dlio_training
tmux kill-session -t dlio_tracing

