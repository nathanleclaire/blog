---
layout: post
title: "How to Wait for All Goroutines to Finish Executing Before Continuing, Part Two:  Fixing My Oops"
date: "2014-02-21"
comments: true
url: "/blog/2014/02/21/how-to-wait-for-all-goroutines-to-finish-executing-before-continuing-part-two-fixing-my-ooops/"
categories: [golang,concurrency,goroutines,waitGroup,sync]
---

Earlier this week I published an article called [How To Wait for All Goroutines to Finish Executing Before Continuing](/blog/2014/02/15/how-to-wait-for-all-goroutines-to-finish-executing-before-continuing/) detailing a problem that I'd run into while coding with Golang and the solution that I'd encountered, which was to use [sync.WaitGroup](http://golang.org/pkg/sync/#WaitGroup).  I was still basking a little in that I-just-finished-a-new-blog-article afterglow when something in the [Reddit comments](http://www.reddit.com/r/golang/comments/1y3spq/how_to_wait_for_all_goroutines_to_finish/) caught my eye!

{{%img src="/images/syncwaitgroup2/enneff_speaks.jpeg" caption="Oh. " %}}

Turns out that my approach in the previous article causes a race condition.  So, just so you guys are all aware, I was wrong, and here's why.

# What was wrong

As [/u/enneff](http://reddit.com/u/enneff) pointed out, there are a variety of issues with the examples I provided.

## What was wrong with the "Old-School way" code?

I'll start at the second example (The "Old-School" way) since the first example is REALLY bad by design (please don't write Go like that).  I used a "done" channel to communicate the status of the goroutines, and it turns out that this was completely unneccsary.

The original code:

```go
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

Thinking about it a bit, enneff's assertion that the channel is unneeded makes a lot of sense, since you know the number of messages ahead of time.  It's a great example of how you shouldn't needlessly overcomplicate things ([simple is better than complex](http://legacy.python.org/dev/peps/pep-0020/)).

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
    for i := 0; i < 3; i++ {
        fmt.Println(<-messages)
    }
}
```

This code is shorter, and doesn't introduce unneeded complexity.

## What was wrong with the "Canonical way" code?

Well, for one thing, the messages channel doesn't get closed, which could cause a memory leak.  It's also not exactly cosidered the best use for a `WaitGroup`.  As enneff put it:

> The original program leaves the printing goroutine hanging (it blocks trying to receive a fourth message that never comes). This will create a memory leak in a long-running problem. You need to close the messages channel after the wg.Wait, to make sure that goroutine terminates. Obviously not a problem in a trivial program, but we should teach good practices at all times. But that still doesn't solve the problem of the racing and printing goroutines, and there's no reason why the so-called "old-school" way isn't appropriate here. When you know the number of messages to expect you might as well count them to know when to finish. Here the waitgroup is superfluous and confusing. WaitGroups are more useful for doing different tasks in parallel.

More importantly, I mistakenly put the code to print the results in its own goroutine, which causes a race condition between the main goroutine and the goroutine that is printing.  In many cases, the main goroutine will win this race, which is BAD!!  Turns out that my whole "sleep for a few seconds, then send a message down the channel" example is actually not a good example for wait groups at all.

The "fetch some JSON from the Reddit API" example, however, actually is a good candidate for `sync.WaitGroup`, and enneff even featured a rewrite that takes advantage of multiple channels to send errors in case something goes wrong!

```go
// This snippet was prepared in response to this article:
// /blog/2014/02/15/how-to-wait-for-all-goroutines-to-finish-executing-before-continuing/
package main

import (
    "fmt"
    "io/ioutil"
    "net/http"
)

func main() {
    urls := []string{
        "http://www.reddit.com/r/aww.json",
        "http://www.reddit.com/r/funny.json",
        "http://www.reddit.com/r/programming.json",
    }

    resc, errc := make(chan string), make(chan error)

    for _, url := range urls {
        go func(url string) {
            body, err := fetch(url)
            if err != nil {
                errc <- err
                return
            }
            resc <- string(body)
        }(url)
    }

    for i := 0; i < len(urls); i++ {
        select {
        case res := <-resc:
            fmt.Println(res)
        case err := <-errc:
            fmt.Println(err)
        }
    }
}

func fetch(url string) (string, error) {
    res, err := http.Get(url)
    if err != nil {
        return "", err
    }
    body, err := ioutil.ReadAll(res.Body)
    res.Body.Close()
    if err != nil {
        return "", err
    }
    return string(body), nil
}
```

Lookin' good!

# Conclusion

All I know is that I don't know nothing.

<iframe width="420" height="315" src="//www.youtube.com/embed/5HtUnubXAO4" frameborder="0" allowfullscreen></iframe>

Thanks again to [Andrew Gerrand](https://twitter.com/enneff) for helping me to learn more about Go.  And until next time, stay sassy Internet.

- Nathan
