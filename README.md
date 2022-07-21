# Tracing Tools for DL Benchmark

This repository contains `bpftrace` traces used to characterize ML workloads as they run. Simply, they record relevant information such as start and end points of various system calls, allowing us to understand what the program we are tracing is doing. 

Paired with traces of CPU and GPU activity, they can be used to generate timelines such as this:
![image](assets/4gpus_1xRAM.png)

There are a few traces under `traces/`:
- `trace_bio.bt` records block level reads and writes 
- `trace_close.bt` records files closing 
- `trace_create_del.bt` records files being created and deleted
- `trace_mmap.bt` records mmap-ing activity
- `trace_openat.bt` records file openings
- `trace_read.bt` records file system reads - when programs issue read() system calls
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