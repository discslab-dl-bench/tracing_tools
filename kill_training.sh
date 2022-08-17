#!/bin/bash

sudo docker kill training
sudo docker rm training

sudo tmux kill-session -t training

