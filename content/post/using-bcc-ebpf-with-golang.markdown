---
title: Using BCC/eBPF for Tracing Superpowers with Golang
---

Recently a technology called [eBPF](http://prototype-kernel.readthedocs.io/en/latest/bpf/), popularized by Netflix performance
engineer [Brendan Gregg](http://www.brendangregg.com/ebpf.html), has been gaining popularity due to a large amount
of promise for its potential to provide performant tracing (partially by doing
aggregations of calculations and events in-kernel without needing to ship
boatloads of information to userspace). Linux tracing and performance analysis
in its current form is a patchwork quilt of various tools, explained well in
[b0rk's article here](https://jvns.ca/blog/2017/07/05/linux-tracing-systems/).

I won't cover too much eBPF/Linux Tracing 101 since they're well detailed in
other places. Instead I want to focus on explaining some insights and practical
advice for being productive with BCC (the layer on top of eBPF which makes it
actually usable for us mere mortals) and Golang.

## Getting Started

Go bindings for BCC exist at https://github.com/iovisor/gobpf, and they seem to
mostly be contributed by PLUMGrid and Cilium folks. Like many tools just
compiling and basic usage of BCC and its bindings can be tricky, and nothing
kills momentum quite like that, so I'll say a few words on it.

First, check your versions carefully:

- Kernel version
- BCC version
- `gobpf` version

Download both https://github.com/iovisor/bcc and
https://github.com/iovisor/gobpf and compile and install BCC first. You _must_
have a recent kernel (in the 4.x range, preferably >=4.9) and I wouldn't even
bother looking in your package managers (it's too new and development moves too
fast), just go straight to the source and get the latest versions. Luckily,
most of the deps are clearly outlined in the [BCC repo](), and there are some
Dockerfiles in that repo which should be able to give you a general idea of how
to install it too.

I recommend figuring out which version of BCC gobpf master is using, and `git
checkout` that tag in the BCC repo. Otherwise, errors complaining about not
passing the right arg count for a BCC method to C and so on might cramp your
style when you go to play with gobpf.

Then, compile/package BCC, and then the examples in gobpf should work. For
instance, I'm on Debian, so I did `sudo debuild -b -uc -us`, which dropped all
of the associated `.deb` files into `..` relative to the source repo, so then I
needed only to `sudo dpkg -i` them. It's worth noting that in order to get the
build to finish I did have to comment out [this
line](https://github.com/iovisor/bcc/blob/master/debian/rules#L16).

You'll need to run programs with `sudo`, so you'll likely need to do something
like:

```
$ cd examples/bcc/bash_readline
$ go build -i
$ sudo ./bash_readline
```

## Learning to use BCC

In my opinion, the best way to learn BCC hands-down is to spend lots of time
poring over the scripts in `tools` in the top level of that repo, reading them,
running them, and making your own modifications to see what happens. `tools` is
a wonderfully comprehensive suite of performance analysis tools contributed by
Brendan, Sascha Goldstein, and others and you can think of it similar to a
"cookbook" full of recipes for you to either use verbatim or draw inspiration
from. Each one is documented with a `.txt` file and a lot can be learned simply
by running them and reading their code.

Now, it's possible that your first reaction upon cracking open these scripts is
"LOL C?" since you might be coming to BCC in order to use a higher level tool
that allows you to use a language like Python or Go to do this type of
analysis. That's exactly what BCC is, _but_ the actual bits which run in-kernel
are usually first written in C and passed off to BCC to compile down to eBPF
bytecode. Partially you need to do this so you can actually import and work
with the relevant kernel data structures. So, you'll need to read and write
some C, but don't worry, [#CIsFun]().

One thing to keep in mind: The BCC programs make use of [macros]() and a bit of
BCC magic that generates C code from, e.g., things that _look_ like method
calls. In a lot of cases you can simply abstract away your thinking about
things like `BPF_HASH(...)`, which will declare a hash table to be used to
track information during traces, but it's helpful to realize that It's Just C
in the end, and the magic looking bits are all just expanding eventually to
considerably less magic (but less readable) bits.

That's the explanation for things you see like `histogram.increment(key)`. C
didn't get methods, the code just gets transformed to actual C before it gets
to the C compiler. As always, if you seek ultimate BCC enlightenment, read the
source code.  (You might find that, just like most things have Buddha nature,
many things have `BPF_HASH` nature in BCC land).

You'll also want to be careful not to get things like `FILTER` and `STORAGE`,
which are essentially templated Python parameters in the script itself that are
transformed into a BCC trace _before_ submitting the trace for compilation,
confused with these C macros or transformations which are part of BCC itself.

I recommend having the [BCC reference guide]() open at all times. It's full of
invaluable details about the various data types and BCC constructs.

## Anatomy of a BCC program

In order to read them, it's helpful to understand that the majority of the
scripts in `tools` have a similar structure, and what the individual components
are each after. Due to some Python/BCC magic (e.g., `print_log2_hist`), it's
not always immediately obvious what's going on, especially in the step where
userspace handles the results of the trace.

1. Command line arguments which might alter the resulting trace are parsed.
2. The BCC program, which eventually gets compiled down to eBPF bytecode, is
   declared (as a string in the language of choice) in C.  This defines which
   data structures will be written to during the trace to track (since the big
   selling point of BCC/eBPF is in-kernel aggregation to avoid costly userspace
   shipping and handling).
3. With the BCC program now declared, it is attached to the relevant "hooks"
   (probes) in the kernel or in userspace. This allows tracing to begin. Traces are
   event-driven, so all of the programs you'll see written will store
   information based on _something happening_ (e.g., a function was called in the
   kernel).
4. The trace runs until a user interrupt (or whatever), and either prints out a
   summary of the collected information, or simply stops because it's already
   been printing information.

Let's take a look at an example program, `biolatency.py`, which tracks block IO
latency on system devices and presents the results to the user as an ASCII
histogram.

<!--
<div class="container">
<div class="row">
<div class="col-one-quarter">
At the top we start with your classic script she-bang as well as script credits
as well and usage notes.
</div>
<div class="col-three-quarters">
<pre><code>
</code></pre>
</div>
</div>
</div>
-->

<div class="container">
<div class="row">
<div class="col-one-quarter">
<p>
At the top we start with your classic script she-bang as well as script credits
and usage notes.
</p>
</div>
<div class="col-three-quarters">
<pre><code>#!/usr/bin/python
# @lint-avoid-python-3-compatibility-imports
#
# biolatency    Summarize block device I/O latency as a histogram.
#       For Linux, uses BCC, eBPF.
#
# USAGE: biolatency [-h] [-T] [-Q] [-m] [-D] [interval] [count]
#
# Copyright (c) 2015 Brendan Gregg.
# Licensed under the Apache License, Version 2.0 (the "License")
#
# 20-Sep-2015   Brendan Gregg   Created this.
</code></pre>
</div>
</div>
</div>

<div class="container">
<div class="row">
<div class="col-one-quarter">
<p>
Next, we have Python imports, followed by arguments you can pass into the
script to modify the default behavior. More on that in a second.
</p>
</div>
<div class="col-three-quarters">
<pre><code>from __future__ import print_function
from bcc import BPF
from time import sleep, strftime
import argparse

# arguments
examples = """examples:
    ./biolatency            # summarize block I/O latency as a histogram
    ./biolatency 1 10       # print 1 second summaries, 10 times
    ./biolatency -mT 1      # 1s summaries, milliseconds, and timestamps
    ./biolatency -Q         # include OS queued time in I/O time
    ./biolatency -D         # show each disk device separately
"""
parser = argparse.ArgumentParser(
    description="Summarize block device I/O latency as a histogram",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=examples)
parser.add_argument("-T", "--timestamp", action="store_true",
    help="include timestamp on output")
parser.add_argument("-Q", "--queued", action="store_true",
    help="include OS queued time in I/O time")
parser.add_argument("-m", "--milliseconds", action="store_true",
    help="millisecond histogram")
parser.add_argument("-D", "--disks", action="store_true",
    help="print a histogram per disk device")
parser.add_argument("interval", nargs="?", default=99999999,
    help="output interval, in seconds")
parser.add_argument("count", nargs="?", default=99999999,
    help="number of outputs")

args = parser.parse_args()
countdown = int(args.count)
debug = 0
</code></pre>
</div>
</div>
</div>

<div class="container">
<div class="row"> <div class="col-one-quarter">
<p>Ah, now we get the good stuff.  This is where the BPF program I was talking
about above is defined. First we start off with some imports. These are needed
because we are going to hooking into a <a href="#">[FIXME]trace event</a>
provided to us by the kernel and reading some of its properties.</p>
</div>
<div class="col-three-quarters">
<pre><code># define BPF program
bpf_text = """
#include &lt;uapi/linux/ptrace.h&gt;
#include &lt;linux/blkdev.h&gt;
</code></pre>
<p style="margin:12px;">
<code>ptrace.h</code> gives us access to <code>pt_regs</code>, a kernel struct
related to tracing processes. We need to use this as part of the function
signature when we define our traces. <code>blkdev.h</code> gives us access to
<code>struct request</code>, which represents a request to read from or write
to a disk.
</p>

<p style="margin:12px;">
We use this to get the disk name via <code>req->rq_disk->disk_name</code>.
</p>
</p>
</div>
</div>
</div>

<div class="container">
<div class="row">
<div class="col-one-quarter">
Next we define the data structures which will persist the information from our
trace. Remember, this is the critical innovation of eBPF/BCC: aggregations are
performed in-kernel.
</div>
<div class="col-three-quarters">
<pre><code>typedef struct disk_key {
    char disk[DISK_NAME_LEN];
    u64 slot;
} disk_key_t;
BPF_HASH(start, struct request *);
STORAGE
</code></pre>
<p style="margin:12px;">
We'll be using two structures to store data:
<ol>
<li>A <code>BPF_HASH</code>, seen directly above, where we'll track every
request to disk and when it came in (later this is used to figure out how long
it took). Its name is <code>start</code> and the key type is <code>struct
request *</code>. The value each entry contains is <code>uint64</code>, which is not
specified here because it's the default.</li>
<li>A <code>BPF_HISTOGRAM</code>, interpolated later (in our Python code) where
<code>STORAGE</code> is. This tracks the latencies of the disk requests and
represents either one histogram for all disks or one histogram for <i>each</i>
disk depending on command line args.
</li>
<p>
</div>
</div>
</div>

We can visualize the differences between the template, the rendered
interpolation of `STORAGE`, and the rendered interpolation of `STORE` (where
`STORAGE` is actually used) side-by-side to quickly get the gist.

<div class="container">
<div class="row">
<div class="col-one-third">template:
<pre><code>typedef struct disk_key {
    char disk[DISK_NAME_LEN];
    u64 slot;
} disk_key_t;
BPF_HASH(
    start,
    struct request *
);
STORAGE

// ... later ...
STORE
</code></pre>

</div>
<div class="col-one-third">one histogram:
<pre><code>typedef struct disk_key {
    char disk[DISK_NAME_LEN];
    u64 slot;
} disk_key_t;
BPF_HASH(
    start,
    struct request *
);
BPF_HISTOGRAM(dist);

// ... later ...
dist.increment(
    bpf_log2l(delta)
);
</code></pre>
<p>
<code>bpf_log2l()</code> buckets observed latency (<code>delta</code>) into a
powers-of-2 bucket "slot". This ensures that the number of buckets does not
grow too large. Note the lookup of disk name using <code>bpf_probe_read</code>
on right.
</p>
</div>
<div class="col-one-third">per-disk histogram:
<pre><code>typedef struct disk_key {
    char disk[DISK_NAME_LEN];
    u64 slot;
} disk_key_t;
BPF_HASH(
    start,
    struct request *
);
BPF_HISTOGRAM(
    dist,
    disk_key_t
);

// ... later ...
disk_key_t key = {
    .slot = bpf_log2l(delta)
};
bpf_probe_read(
    &key.disk,
    sizeof(key.disk),
    req->rq_disk->disk_name
);
dist.increment(key);
</code></pre>
</div>
</div>
</div>

<div class="container">
<div class="row">
<div class="col-one-quarter">
<p>
Having seen that, hopefully this code interpolation section will make a lot
more sense to you. <code>FACTOR</code>, as you might guess, determines the
scale at which the units of latency are measured. The default is nanoseconds,
but the script provides an option to also store the results in milliseconds.
</p>
</div>
<div class="col-three-quarters">
<pre><code># code substitutions
if args.milliseconds:
    bpf_text = bpf_text.replace('FACTOR', 'delta /= 1000000;')
    label = "msecs"
else:
    bpf_text = bpf_text.replace('FACTOR', 'delta /= 1000;')
    label = "usecs"
if args.disks:
    bpf_text = bpf_text.replace('STORAGE',
        'BPF_HISTOGRAM(dist, disk_key_t);')
    bpf_text = bpf_text.replace('STORE',
        'disk_key_t key = {.slot = bpf_log2l(delta)}; ' +
        'bpf_probe_read(&key.disk, sizeof(key.disk), ' +
        'req->rq_disk->disk_name); dist.increment(key);')
else:
    bpf_text = bpf_text.replace('STORAGE', 'BPF_HISTOGRAM(dist);')
    bpf_text = bpf_text.replace('STORE',
        'dist.increment(bpf_log2l(delta));')
</code></pre>
</div>
</div>
</div>

With all of that set up, let's take a look at the trace functions themselves.
We'll have two "hooks": one that runs when we hit a "request start" event,
where we will start a timer, and one that runs when the disk request finishes.

By the way, if you're curious how you can get a list of all of the tracepoints
available, the `tplist` tool from the BCC repo does exactly that. e.g.:

```
$ sudo ./tools/tplist.py | grep open | head
hda_controller:azx_pcm_open
nfsd:read_opened
nfsd:write_opened
syscalls:sys_enter_mq_open
syscalls:sys_exit_mq_open
syscalls:sys_enter_open_by_handle_at
syscalls:sys_exit_open_by_handle_at
syscalls:sys_enter_open
syscalls:sys_exit_open
syscalls:sys_enter_openat
```

<div class="container">
<div class="row">
<div class="col-one-quarter">
<p>
When we hit a <code>req_start</code>, we get the current time and update our
<code>BPF_HASH</code> named <code>start</code> from above. When we hit a
<code>req_completion</code>, we figure out how long it's been since the request
originated, and notate this in our <code>BPF_HISTOGRAM</code>. We make sure to
<code>delete</code> entries after this so we don't leak memory.
</p>
</div>
<div class="col-three-quarters">

<pre><code>int trace_req_start(struct pt_regs *ctx, struct request *req)
{
    u64 ts = bpf_ktime_get_ns();
    start.update(&req, &ts);
    return 0;
}

int trace_req_completion(struct pt_regs *ctx, struct request *req)
{
    u64 *tsp, delta;

    // fetch timestamp and calculate delta
    tsp = start.lookup(&req);
    if (tsp == 0) {
        return 0;   // missed issue
    }
    delta = bpf_ktime_get_ns() - *tsp;
    FACTOR

    // store as histogram
    STORE

    start.delete(&req);
    return 0;
}
</code></pre>
</div>
</div>
</div>

<!---
if debug:
    print(bpf_text)

# load BPF program
b = BPF(text=bpf_text)
if args.queued:
    b.attach_kprobe(event="blk_account_io_start", fn_name="trace_req_start")
else:
    b.attach_kprobe(event="blk_start_request", fn_name="trace_req_start")
    b.attach_kprobe(event="blk_mq_start_request", fn_name="trace_req_start")
b.attach_kprobe(event="blk_account_io_completion",
    fn_name="trace_req_completion")

print("Tracing block device I/O... Hit Ctrl-C to end.")

# output
exiting = 0 if args.interval else 1
dist = b.get_table("dist")
while (1):
    try:
        sleep(int(args.interval))
    except KeyboardInterrupt:
        exiting = 1

    print()
    if args.timestamp:
        print("%-8s\n" % strftime("%H:%M:%S"), end="")

    dist.print_log2_hist(label, "disk")
    dist.clear()

    countdown -= 1
    if exiting or countdown == 0:
        exit()
--->

## Getting data to userspace

There are a couple of different options for getting information from a BCC trace to userspace:

1. Reading map values directly using `bpf_read_key`
2. Submitting them using `perf`

## Kprobes vs. Uprobes vs. Tracepoints

`tplist`

## About `bpf_trace_printk`

## WTF is the ELF thing?

You might know of elves from Dungons and Dragons, but you likely are guessing
that this elf refers to the [Executable Linking Format](). But why the hell is
there an `elf` directory ? Personally, I found my eyes gloss over trying to
read the README and understand it (though I eventually)

Well, consider this dilemma: You write some sweet programs using BCC that
execute traces, 

## `[]byte` vs. `string` in table entries

## A word on what to do with results

If you've gotten this far, you deserve some pretty graphs. So here you go!

