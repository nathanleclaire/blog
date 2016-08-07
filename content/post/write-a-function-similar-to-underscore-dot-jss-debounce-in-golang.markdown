---
layout: post
title: "Write a Function Similar To Underscore.js's debounce, in Golang"
date: "2014-08-03"
comments: true
url: "/blog/2014/08/03/write-a-function-similar-to-underscore-dot-jss-debounce-in-golang"
categories: [javascript,golang,underscore,debounce]
---

# Debounce, eh?

{{%img src="/images/debouncego/debounceit.gif" caption="" %}}

As some of you may recall I wrote [this post about an interview I bombed with a YCombinator Startup](https://nathanleclaire.com/blog/2013/11/16/the-javascript-question-i-bombed-in-an-interview-with-a-y-combinator-startup/) and in it I describe how to implement a `debounce` (term taken from [Underscore.js](http://underscorejs.org/)) type of function from scratch.  Recently I found myself having to implement a similar thing in Golang, so I'm sharing the results of my implementation here.

## What is it?

`debounce` in the Underscore.js documentation:

> Creates and returns a new debounced version of the passed function which will postpone its execution until after wait milliseconds have elapsed since the last time it was invoked. Useful for implementing behavior that should only happen after the input has stopped arriving. For example: rendering a preview of a Markdown comment, recalculating a layout after the window has stopped being resized, and so on. 

`debounce` is very useful if the cost of triggering the callback function (or equivalent) for your event is quite high.  It's a good way to get laziness for cheap if you have a busy event stream.  The example listed in the documentation is lucid:

```js
var lazyLayout = _.debounce(calculateLayout, 300);
$(window).resize(lazyLayout);
```

## What about in Go?

Go usually eschews the JavaScript callback continuation-passing style in favor of using goroutines and channels for concurrency.  It's a very nice language feature, and elegant, but sometimes you want use a "debounce" to respond to, say, a bunch of values coming over a channel in rapid bursts.  So how do you do this in Go?

**EDIT**: Though previously this code was implemented using `time.AfterFunc`, Github user [mechmind](https://github.com/mechmind) proposed a different method using `time.After` and a channel for the input.

Example code:

```go
package main

import (
    "fmt"
    "time"
)

func debounce(interval time.Duration, input chan int, f func(arg int)) {
    var (
        item int
    )
    for {
        select {
        case item = <-input:
            fmt.Println("received a send on a spammy channel - might be doing a costly operation if not for debounce")
        case <-time.After(interval):
            f(item)
        }
    }
}

func main() {
    spammyChan := make(chan int, 10)
    go debounce(300*time.Millisecond, spammyChan, func(arg int) {
        fmt.Println("*****************************")
        fmt.Println("* DOING A COSTLY OPERATION! *")
        fmt.Println("*****************************")
        fmt.Println("In case you were wondering, the value passed to this function is", arg)
        fmt.Println("We could have more args to our \"compiled\" debounced function too, if we wanted.")
    })
    for i := 0; i < 10; i++ {
        spammyChan <- i
    }
    time.Sleep(500 * time.Millisecond)
}
```

We create a function, `debounce`, that consumes a `func (int)` and returns a `func(int)`.  Whenever we trigger this function, it will wait a specified number of milliseconds, and, if it is not interrupted by another attempt to trigger the action in that duration, it triggers the action.  If it is interrupted, it resets the timeout.

# fin

Go is a little less flexible than JavaScript due to the strong typing (if anyone has ideas how to make this more flexible I'm very interested to hear) but this approach will get you 90% of the way there in the instances where you need debouncing.

Until next time, stay sassy Internet.

- Nathan
