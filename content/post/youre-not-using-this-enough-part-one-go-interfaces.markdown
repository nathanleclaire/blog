---
layout: post
title: "You're Not Using This Enough, Part One: Go Interfaces"
date: "2015-03-09"
---

![](/images/gointerface/interface.jpeg)

[Go](https://github.com/golang/go) is getting really popular, and it's caused a
hilarious amount of confusion as some headstrong developers continue to rage
about whether or not it has generics while others quietly or not so quietly get
things done with it.  I sling a little Go code these days and I wanted to talk
to you today about a pattern that can really help your Go code development be
more flexible and testable.

My suggestion is for you to use [Go
interfaces](https://golang.org/doc/effective_go.html#interfaces_and_types) as
much as you possibly can.  Especially as I've been working on automated testing
of Go code, I find that when `struct`s begin to get too big and important, it's
time to break out the interfaces.

Today we're going to look at :

- Fast Interface Review
- Testing with Interfaces

## Fast Interface Review

Define an interface that has some methods you want to use like this.

```go
type Config interface {
    Get(key string) (string, error)
    Set(key, val string) (error)
}
```

To define a concrete `struct` that fulfills the interface's "contract", just
make sure that it implements all of the methods with those signatures:

```go
type InmemConfig struct {
    M map[string]string
}

func (c InmemConfig) Get(key string) (string, error) {
    val, ok := c.M[key]
    if ok {
        return val, nil
    } else {
        return "", errors.New("Tried to get a key which doesn't exist")
    }
}

func (c InmemConfig) Set(key, val string) error {
    c.M[key] = val
    return nil
}
```

This is a really powerful and flexible tool, especially if you want to write
code which conceals a couple of different "backends" through a standard
interface, or a component which you need to mock out for testing.

## Testing with Interfaces

Go doesn't really gravitate towards "mocks" in the sense that you might be
familiar with if you've done testing with Java, PHP, or other languages.
Instead, it's recommended that the user implements small interfaces, easily
faked out by defining new `struct`s, for testing.

Take a look at the following program, which expands on the example outlined
above to serve a request with an optional header set using a CLI argument.

`config.go`:

```go
package main

import (
    "errors"
    "fmt"
    "log"
    "net/http"
    "os"
)

type Config interface {
    Get(key string) (string, error)
    Set(key, val string) error
}

var (
    Cfg InmemConfig
)

type InmemConfig struct {
    M map[string]string
}

type Responder struct {
    Cfg Config
}

func (c InmemConfig) Get(key string) (string, error) {
    val, ok := c.M[key]
    if ok {
        return val, nil
    } else {
        return "", errors.New("Tried to get a key which doesn't exist")
    }
}

func (c InmemConfig) Set(key, val string) error {
    c.M[key] = val
    return nil
}

func (r *Responder) Handler(w http.ResponseWriter, req *http.Request) {
    cfgOption, err := r.Cfg.Get("Option.Header")
    if err != nil {
        log.Fatal(err)
    }
    w.Header().Set("X-Config-Option", cfgOption)
    fmt.Fprintf(w, "This is the response body!")
}

func main() {
    responder := Responder{
        Cfg: InmemConfig{
            M: make(map[string]string),
        },
    }
    if err := responder.Cfg.Set("Option.Header", os.Args[1]); err != nil {
        log.Fatal(err)
    }
    http.HandleFunc("/", responder.Handler)
    http.ListenAndServe(":8080", nil)
}
```

To run it :

<pre>
$ go run file.go MagicTokenOfMagic
</pre>

{{%img src="/images/gointerface/cfgheader.png" caption="Hey, there's the header that we configured at runtime!" %}}

The `Config` interface is simple but powerful in implementation, and if you use
your imagination you can probably think of all sorts of creative ways that the
configuration could be stored and accessed, and consequently a whole lot of
ways to implement the `Config` interface which would be usable from all code
which was written to use that interface.  This promotes code reuse _a lot_.
For instance, think about storing such data in
[etcd](https://github.com/coreos/etcd) or [Consul](https://consul.io) and being
able to access it across your entire cluster on whichever machine you need to
query from.  Likewise, you could store the data encrypted on local hard disk:
as long as the "contract" of the interface was fulfilled, the programs which
use the configuration store need not know or care about the implementation
detail of storage.

This agnosticism is also useful for testing, where frequently you don't want to
actually run through all of the code which the code you are testing relies on.
Consider our example above: If we want to test the HTTP handler, we don't
actually have to go through the motions of creating an `InmemConfig` and
setting the configuration argument from the command line.  We can just fake it
completely, since we don't care about testing that part.

Also useful is the fact that `w` implements the `http.ResponseWriter` interface
from the Go standard library.  We could use this fact to gain _extremely_
fine-grained control over this component's behavior if we needed it.

All of this allows us to automate testing our code more efficiently and become
more effective at delivering quality software.

This is what the test for that handler looks like.  As you can see, we create a
`FakeConfig` struct which implements our custom interface, as well as a
`FakeResponseWriter` struct which behaves however we want in place of the
standard libary implementation.

`config_test.go`:

```go
package main

import (
    "net/http"
    "testing"
)

type FakeConfig struct{}
type FakeResponseWriter struct {
    h    http.Header
    Body []byte
}

const (
    msg = "Please send help, I'm trapped in the web server"
)

func (c FakeConfig) Get(key string) (string, error) {
    return msg, nil
}

// It always works!  Nice
func (c FakeConfig) Set(key, val string) error {
    return nil
}

func (wr FakeResponseWriter) Header() http.Header {
    return wr.h
}

func (wr FakeResponseWriter) Write(b []byte) (int, error) {
    wr.Body = b
    return len(msg), nil
}

func (wr FakeResponseWriter) WriteHeader(i int) {}

func TestResponderHandler(t *testing.T) {
    responder := Responder{
        Cfg: FakeConfig{},
    }
    w := FakeResponseWriter{
        h: http.Header{},
    }

    // Don't even care about the request!
    // But if needed to we could control that pretty well too.
    responder.Handler(w, nil)
    header := w.Header().Get("X-Config-Option")
    if header != msg {
        t.Fatalf("Expected X-Config-Option to be %q, got %q", msg, header)
    }
}
```

The amount of control we have over the interface is extreme, and we can now
snap them together like Lego bricks to test our program.

Writing tests in this style will encourage to create and modify them more
often, thereby encouraging experimentation and good code coverage.  What I like
about it is that once you set up your "mock" interfaces, it is usually quick
and easy to get what you want out of the things which you are testing, and
faking things out in slightly different ways is equally fast and cheap.

## fin

So that's what you should be doing more of this week.  Go interfaces and unit
testing.

Until next time, stay sassy Internet.

- Nathan
