# Tracing Tools for DL Benchmark

This repository contains `bpftrace` traces used to characterize ML workloads as they run. Simply, they record relevant information such as start and end points of various system calls, allowing us to understand what the program we are tracing is doing. 

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

As previously mentionned, these traces are developed for `bpftrace` which is a tracing framework using EBPF. To learn more about this check out https://github.com/iovisor/bpftrace and the links therein.

In the main directory you will find shell scripts used to launch these traces:
- `trace_imseg.sh` is used to trace the image segmentation workload specifically. It starts all the traces, then the workload, then waits until completion to shut off the traces and archive them. I recommend creating a similar script to trace other workloads, use it as inspiration.
- `launch_traces.sh` launches all the traces, oddly enough :p. It automatically kills the time alignment trace after 60s (it's a pretty heavy trace and 60s is good enough to get a good alignment. Change it to a higher value to for more precision. More details in the plotting repo) then waits for the user to hit `Ctrl-c` before closing the traces.

We use `mpstat` to get the CPU trace and `nvidia-smi pmon` to get the GPU trace.

<br>
Should you be tracing for a long time, I recommend running the tracing script from a `tmux` session. To do simply type `tmux` and you will be put in a new session. 

You can also run `tmux new-session -d -s <session-name>` to name your session. While inside a tmux session hit `Ctrl-b` then `d` to detach. Run `tmux ls` to list the active sessions and `tmux attach -t <session-name or id>` to attach.

# More Tracing Tools (Added by Ruoyu)
- `trace_imseg_simple.sh` is a simpler version of `trace_imseg.sh` to use. It is identical to `trace_imseg.sh` but with less argument to type (not that meaningful).
- `run_experiments.sh` is a script which runs all experiment combinations. Need to edit the content to run experiments.
    - Ex) If we edit `gpus = (1 2 4 8)`, `data_paths = (path1, path2)`, then `run_experiments.sh` will run 8 experiements in total.
- `start_experiments.sh` is a small script that runs `run_experiments.sh` in a tmux session called `imseg_experiments`.