---
layout: post
title: "Demystifying Golang's io.Reader and io.Writer Interfaces"
date: 2014-07-19 19:35
comments: true
categories: [golang,go,io.reader,io.writer]
---

{%img /images/iowriter/aviator.png %}

If you're coming to [Go](http://golang.org) from a more flexible, dynamically typed language like Ruby or Python, there may be some confusion as you adjust to the Go way of doing things.  In my case, I had some trouble wrapping my head around `io.Reader`, `io.Writer`, `io.ReadCloser` etc.  What are they used for, and how can they be included in our Go programs for interesting and helpful results?

# Quick interface review

To make up for some of the flexibility lost by not having generics, and for other reasons as well, Go provides an abstraction in the form of interfaces.

You can specify an interface and then any consumer of that interface will accept it.

```go
type error interface {
    Error() string
}
```

Many standard library components of Go define interfaces.  In fact, the `error` type you know and love (hate?) is simply an interface which insists that a method named `Error` which consumes nothing and returns a string must be defined on a struct for the interface to count as satisfied.  Interfaces in Go are set *implicitly*, so all you have to do is define the required methods on your struct and it will qualify as implementing that interface.

For instance:

```go
package main

import (
    "fmt"
    "os"
)

type Animal interface {
    Say() string
    Greet(Animal)
}

type Person struct {
}

func (p Person) Say() string {
    return "Hey there bubba!"
}

func (p Person) Greet(animalToGreet Animal) {
    fmt.Println("Hi!")
}

type Dog struct {
    age int
    breed string
    owner *Person
}

func (d Dog) Say() string {
    return "Woof woof!"
}

func (d Dog) Growl() {
    fmt.Println("Grrr!")
}

func (d *Dog) Snuggle() {
    // snuggle code...
}

func (d Dog) Sniff(animalToSniff Animal) (bool, error) {
    // sniff code...
    return true, nil
}

func (d Dog) Greet(animalToGreet Animal) {
    if _, ok := animalToGreet.(Person); ok {
        d.Snuggle()
    } else {
        friendly, err := d.Sniff(animalToGreet)
        if err != nil {
            fmt.Fprintln(os.Stderr, "Error sniffing a non-person")
        }
        if !friendly {
            d.Growl()
        }
    }
}

func main() {
    d1 := Dog{2, "shibe", &Person{}}
    d2 := Dog{3, "poodle", &Person{}}
    d2.Greet(d1)
    fmt.Println("Successfully greeted a dog.")
}
```

Run here: [http://play.golang.org/p/m_RQeo9N1H](http://play.golang.org/p/m_RQeo9N1H)

Yup, I "went there" with the Animal OO-ish (Go doesn't have pure objects) cliché.

When you compile a program containing the above, the Go compiler knows that the `Dog` struct satisfies the `Animal` interface provided (it infers this because `Dog` implements the neccesary methods to qualify), so it won't complain if you pass instances of of `Dog` to functions which demand an `Animal` type.  This allows for a lot of power and flexibility in your architecture and abstractions, without breaking the type system.

# So what's with `io`?

`io` is a Golang standard library package that defines flexible interfaces for many operations and usecases around input and output.

See: [http://golang.org/pkg/io/](http://golang.org/pkg/io/)

You can use the same mechanisms to talk to files on disk, the network, STDIN/STDOUT, and so on.  This allows Go programmers to create re-usable "Lego brick" components that work together well without too much shimming or shuffling of components.  They smooth over cross-platform implemenation details, and it's all just `[]byte` getting passed around, so everyone's expectations (senders/writers and receivers/readers) are congruent.  You have `io.Reader`, `io.ReadCloser`, `io.Writer`, and so on to use.  Go also provides packages called `bufio` and `ioutil` that are packed with useful features related to using these interfaces.

# OK, but what can you do with it.

Let's look at an example to see how combining some of these primitives can be useful in practice.  I've been working on a project where I want to attach to multiple running Docker containers concurrently and stream (multiplex) their output to STDOUT with some metadata (container name) prepended to each log line.  Sounds easy, right? ;)

The Docker REST API bindings written by [fsouza](http://github.com/fsouza) provide an abstraction whereby we can pass an `io.Writer` instance for STDOUT and STDERR of the container we are attaching to.  So we have control of a `io.Writer` that we inject in, but how do read what gets written by this container one line at a time, and multiplex/label the output together in the fashion I described in the previous paragraph?

We will use a combination of Go's concurrency primitives, `io.Pipe`, and a `bufio.Scanner` to accomplish this.

Since the call to the API binding's `AttachContainer` method hijacks the HTTP connection and consequently forces the calling goroutine to be blocked, we run each `Attach` call in its own goroutine.

We need an `io.Reader` to be able to read and parse the output from the container, but we only have the option to pass in an instance of `io.Writer` for STDOUT and STDERR.  What to do?  We can use a call to `io.Pipe` (see [here](http://golang.org/pkg/io/#Pipe) for reference).  `io.Pipe` returns an instance of a `PipeReader`, and an instance of a `PipeWriter`, which are connected (calling the `Write` method on the `Writer` will lead directly to what comes out of `Read` in the `Reader`).  So, we can use the returned `Reader` to stream the output from the container.

The final step is to use a `bufio.Scanner` to read the output from the `PipeReader` line by line.  If you use the `Scan` method with a `range` statement, it will iterate line by line as we desire.  We have already generated the prefix earlier and saved it in the `Service` struct we are working with (`Service` in my implementation is a very light wrapper around a container).

Therefore, the final method looks like this:

```go
func (s *Service) Attach() error {
	r, w := io.Pipe()
	options := apiClient.AttachToContainerOptions{
		Container:    s.Name,
		OutputStream: w,
		ErrorStream:  w,
		Stream:       true,
		Stdout:       true,
		Stderr:       true,
		Logs:         true,
	}
	fmt.Println("Attaching to container", s.Name)
	go s.api.AttachToContainer(options)
	go func(reader io.Reader, s Service) {
		scanner := bufio.NewScanner(reader)
		for scanner.Scan() {
			fmt.Printf("%s%s \n", s.LogPrefix, scanner.Text())
		}
		if err := scanner.Err(); err != nil {
			fmt.Fprintln(os.Stderr, "There was an error with the scanner in attached container", err)
		}
	}(r, *s)
	return nil
}
```

We kick off attaching to, and reading from, the container at the same time- when the attach is complete and starts streaming, the `scanner.Scan` loop will start logging.

# Conclude

I had some trouble understanding `io.Writer`, `io.Reader`, etc. when getting started with Go (and recently as well), but I think I was over-thinking their simplicity and explicit power.  Additionally, learning about some higher-level abstractions related to them helped a lot.  Hopefully this article is useful for you and clears stuff up in the future.  I know that my Go has accelerated a lot since grokking these concepts, especially since so much (file IO etc.) relies on it.

Until next time, stay sassy Internet.

- Nathan
