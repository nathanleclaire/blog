---
layout: post
title: "How to Wait for All Goroutines to Finish Executing Before Continuing"
date: "2014-02-15"
comments: true
categories: [golang,concurrency,goroutines,waitGroup,sync]
---

*EDIT:*  As pointed out by effenn in [this Reddit comment](http://www.reddit.com/r/golang/comments/1y3spq/how_to_wait_for_all_goroutines_to_finish/cfh9fg7), a lot of information in this article is "dangerously inaccurate".  OOPS!  I've written a followup/correction article [here](/blog/2014/02/21/how-to-wait-for-all-goroutines-to-finish-executing-before-continuing-part-two-fixing-my-ooops/) for your viewing pleasure, but I'm leaving this article up for "historical purposes".

{{%img src="/images/syncwaitgroup/gophermegaphones.jpeg" caption="" %}}

Goroutines and channels are one of [Go](http://golang.org)'s nicest language features.  They provide a rather headache-free way to use the power of concurrency in your Go programs, and they are baked into the language itself instead of relying on standard or external libraries.  I was very excited when I started playing around with them but eventually came across a problem : what if you want to wait for all goroutines (a kind of lightweight thread in case you're not familiar) to finish executing before you continue execution in the current goroutine?

For instance, I came across this problem when I wanted to run a batch operation (transform some strings from a slice- kind of like a map) in parallel (and yes, I know that [concurrency is not parallelism](http://blog.golang.org/concurrency-is-not-parallelism)).  I needed to know when this execution was over so my program didn't exit prematurely.  How?

(Psst:  In case you just want the answer, and not the journey, it's to use [sync.WaitGroup](http://golang.org/pkg/sync/#WaitGroup)!)

In this article, I assume that you have some elementary proficiency with [goroutines and channels](http://golang.org/doc/codewalk/sharemem/).

# The Hacky Way

A lot of tutorials or blog articles that you come across online when you start getting into this stuff will have examples like this (forgive me for being a little bit contrived but hopefully you'll be familiar with the general idea):

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    messages := make(chan int)
    go func() {
        time.Sleep(time.Second * 3)
        messages <- 1
    }()
    go func() {
        time.Sleep(time.Second * 2)
        messages <- 2
    }() 
    go func() {
        time.Sleep(time.Second * 1)
        messages <- 3
    }()
    go func() {
        for i := range messages {
            fmt.Println(i)
        }
    }()
    time.Sleep(time.Second * 5)
}
```

This will print out:

```
3
2
1
```

because the goroutines all execute concurrently and some of the numbers sleep for longer than others.  If it weren't for that `time.Sleep(time.Second * 5)` at the end, though, the program would terminate execution BEFORE the goroutines got a chance to finish executing and it would print nothing.

This kind of works for our contrived example but its hackiness makes me go "ICK!".  Trying to make this style work in any nontrivial program would be a complete nightmare - what if we don't know how long our goroutines will be executing for?  We'd rather not just cross our fingers and hope for the best.

# The "Old-School" Way

As mentioned by a commenter in [this StackOverflow post](http://stackoverflow.com/questions/18207772/how-to-wait-for-all-goroutines-to-finish-without-using-time-sleep), the way that this was accomplished without using `sync.WaitGroup` is to use an additional channel to signify the end of execution.  Using this solution our previous example would look like:

```
package main

import (
    "fmt"
    "time"
)

func main() {
    messages := make(chan int)

    // Use this channel to follow the execution status
    // of our goroutines :D
    done := make(chan bool)

    go func() {
        time.Sleep(time.Second * 3)
        messages <- 1
        done <- true
    }()
    go func() {
        time.Sleep(time.Second * 2)
        messages <- 2
        done <- true
    }() 
    go func() {
        time.Sleep(time.Second * 1)
        messages <- 3
        done <- true
    }()
    go func() {
        for i := range messages {
            fmt.Println(i)
        }
    }()
    for i := 0; i < 3; i++ {
        <-done
    }
}
```

This method is a little better but sacrifices some flexibility.  For instance, it introduces some additional weirdness in the case that we don't actually know how many goroutines we want to spin up ahead of time.

# The Canonical Way

As mentioned, the canonical way to do this is to use the `sync` package's `WaitGroup` structure ([link](http://golang.org/pkg/sync/#WaitGroup)).  From the docs:

> A WaitGroup waits for a collection of goroutines to finish. The main goroutine calls Add to set the number of goroutines to wait for. Then each of the goroutines runs and calls Done when finished. At the same time, Wait can be used to block until all goroutines have finished.  

To use `sync.WaitGroup` we:

1. Create a new instance of a `sync.WaitGroup` (we'll call it `wg`)
2. Call `wg.Add(n)` where `n` is the number of goroutines to wait for (we can also call `wg.Add(1)` `n` times)
3. Execute `defer wg.Done()` in each goroutine to indicate that goroutine is finished executing to the `WaitGroup` (see [defer](http://golang.org/doc/effective_go.html#defer))
4. Call `wg.Wait()` where we want to block.

This fits our use case perfectly.  Rewritten, our code now uses `sync.WaitGroup` and looks like this:

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

func main() {
    messages := make(chan int)
    var wg sync.WaitGroup

    // you can also add these one at 
    // a time if you need to 

    wg.Add(3)
    go func() {
        defer wg.Done()
        time.Sleep(time.Second * 3)
        messages <- 1
    }()
    go func() {
        defer wg.Done()
        time.Sleep(time.Second * 2)
        messages <- 2
    }() 
    go func() {
        defer wg.Done()
        time.Sleep(time.Second * 1)
        messages <- 3
    }()
    go func() {
        for i := range messages {
            fmt.Println(i)
        }
    }()

    wg.Wait()
}
```

This example is a little silly, but suppose we wanted to slurp JSON data from 3 different subreddits concurrently.  We don't know how long those HTTP requests are going to take, and we don't want to cause a race condition by trying to work with data that hasn't been populated yet in our Go program, so `sync.WaitGroup` ends up being very handy:

```go
package main

import (
    "fmt"
    "io/ioutil"
    "log"
    "net/http"
    "sync"
)

func main() {
    urls := []string{
        "http://www.reddit.com/r/aww.json",
        "http://www.reddit.com/r/funny.json",
        "http://www.reddit.com/r/programming.json",
    }
    jsonResponses := make(chan string)

    var wg sync.WaitGroup
    defer wg.Wait()
    wg.Add(len(urls)+1)

    for _, url := range urls {
        go func(url string) {
            defer wg.Done()
            res, err := http.Get(url)
            if err != nil {
                log.Fatal(err)
            } else {
                defer res.Body.Close()
                body, err := ioutil.ReadAll(res.Body)
                if err != nil {
                    log.Fatal(err)
                } else {
                    jsonResponses <- string(body)
                }
            }
        }(url)
    }

    go func() {
        defer wg.Done()
        for response := range jsonResponses {
            fmt.Println(response)
        }
    }()
}
```

Check out a [Runnable](http://runnable.com/UwEzO6LcUjMdAABH/using-sync-waitgroup-to-slurp-json-from-reddit-concurrently-wait-for-all-goroutines-to-finish-before-continuing-) of this code in action!

# Conclusion

Go is so very fun.  I need to start writing more of it again and put down this silly JavaScript stuff XD  [Martini](http://martini.codegangsta.io/) looks super promising, so maybe I will develop and application with it.

Until next time, stay sassy Internet.

- Nathan
