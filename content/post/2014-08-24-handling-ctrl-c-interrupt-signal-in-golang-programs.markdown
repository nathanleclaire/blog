---
layout: post
title: "Handling CTRL-C (interrupt signal) in Golang Programs"
date: "2014-08-24"
comments: true
categories: [golang,sigint,ctrl-c]
---

# Interruptions

{{%img src="/images/signal.png" caption="" %}}

Recently I've been working on a Go program where I will need to do some cleanup work before exiting if the users press `CTRL+C` (thereby sending an interrupt signal, `SIGINT`, to the process).  I was unsure how to do this.

As it turns out, `signal.Notify` is the method by which this is accomplished.

Here is some sample source code:

```go
// Code to set up some services up here...

// After setting everything up!
// Wait for a SIGINT (perhaps triggered by user with CTRL-C)
// Run cleanup when signal is received
signalChan := make(chan os.Signal, 1)
cleanupDone := make(chan bool)
signal.Notify(signalChan, os.Interrupt)
go func() {
    for _ = range signalChan {
        fmt.Println("\nReceived an interrupt, stopping services...\n")
        cleanup(services, c)
        cleanupDone <- true
    }
}()
<-cleanupDone
```

I like this example because it really illuminates the power of Go's concurrency primitives.  Instead of having to worry about complicated process or threading logic I simply abstract away the concurrency details using a goroutine and a couple of channels. In this instance, the main goroutine is blocked by a unbuffered `cleanupDone` channel because that is what behavior is expected (we've already spin up additional goroutines earlier to do some logging and handling of outside of the context of the main goroutine). 

Now I can clean up after my containers when a user interrupts the terminal with CTRL+C.  Awesome!

Until next time, stay sassy Internet.

- Nathan