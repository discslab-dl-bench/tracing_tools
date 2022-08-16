#!/bin/bash

remaining_traces=$(ps aux | grep bpftrace | awk '{print $2}')
for proc in $remaining_traces; 
do	
	kill $proc
done