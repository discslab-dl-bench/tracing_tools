# Tracing Tools for DL Benchmark

This repository contains `bpftrace` traces used to characterize ML workloads as they run. Simply, they record relevant information such as start and end points of various system calls, allowing us to understand what the program we are tracing is doing. 
To learn more about this and install, see https://github.com/iovisor/bpftrace.

Paired with traces of CPU and GPU activity, they can be used to generate timelines such as this:
![image](assets/4gpus_1xRAM.png)

You will find various subdirectories and traces under `traces/`. 
Due to the need for different filtering to trace each workload, all of the subdirectories contain slightly different variants of the following traces:
- `trace_bio.bt` records block level reads and writes 
- `trace_close.bt` records files closing 
- `trace_create_del.bt` records files being created and deleted
- `trace_openat.bt` records file openings
- `trace_read.bt` records calls to read() and pread64() system calls
- `trace_time_align.bt` is a special trace used to map the timestamps given by `bpftrace` to UTC timestamps for plotting.
- `trace_write.bt` records file system writes


In the main directory you will find shell scripts used to launch these traces:
- `trace_v2.sh` starts all the traces, then the workload, then waits until completion to shut off the traces and archive them. It will output the traces under `trace_results/`.

We use `mpstat` to get the CPU trace and `nvidia-smi pmon` to get the GPU trace.

<br>
Should you be tracing for a long time, I recommend running the tracing script from a `tmux` session. To do simply type `tmux` and you will be put in a new session. 

You can also run `tmux new-session -d -s <session-name>` to name your session. While inside a tmux session hit `Ctrl-b` then `d` to detach. Run `tmux ls` to list the active sessions and `tmux attach -t <session-name or id>` to attach.