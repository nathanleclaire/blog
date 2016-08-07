---
layout: post
title: "Interfaces and Composition for Effective Unit Testing in Golang"
date: "2015-10-10"
comments: true
categories: [go]
---

{{%img src="/images/gounit/all.png" %}}

Go programs, when properly implemented, are fairly simple to test
programatically. Go unit tests offer:

- Increased enforcement of behavior expectations beyond the compiler (providing
  critical assurance around rapidly changing code paths)
- Fast execution speed (many popular modules' tests can execute completely in
  seconds)
- Easy integration into CI pipelines (`go test` is built right in)
- Programmatic race condition detection through the `-race` flag

Consequently, they are by far one of the best ways to ensure code quality and
prevent regressions.  Tragically, however, unit testing seems to often be one
of the most neglected aspects of any given Go project.  It is often slept on
until the effort required to implement it properly is Herculean. 

This tendency seems at least partly due to a lack of quality resources
explaining how to properly structure a Go program to be tested, and examples of
doing so.  This is a guide attempting to provide both and to increase the
general quality of programs available in the Go community. 

Don't let the compiler lull you into a false sense of security: you'll be glad
you began testing sooner rather than later.

### Overview

In this article I will walk you through:

1. Concepts for ensuring testability
2. Four concrete examples to learn how to test effectively in Go

By the end, you should be armed with the knowledge you need in order to go
forth and test.

### Concepts

If you do not structure and test your program properly from the start, it will
be astronomically more difficult to test down the road.  This is a fairly
universal axiom of programming but seems particularly true of Go testing due to
its opinionated nature.

The three most important concepts to be able to use fluidly in order to test Go
programs effectively are:

1. Using interfaces in your Go code
2. Constructing higher-level interfaces through composition (embedding)
3. Becoming familiar with `go test` and the
   [`testing`](https://golang.org/pkg/testing/) module

Let's take a look at each one and why it is important.

## Using interfaces

You may be familiar with the use of interfaces from working through the Go
walkthrough or from the official documentation.  What you may not be familiar
with is why interfaces are so important and why you should begin using your own
interfaces as soon as possible.

For those who are unfamiliar with interfaces, I highly recommend you [read the
official documentation](https://golang.org/doc/effective_go.html#interfaces) to
understand how they work (I also have an [article on
interfaces](https://nathanleclaire.com/blog/2015/03/09/youre-not-using-this-enough-part-one-go-interfaces/)).

Long story short:

1. Interfaces let you define a set of methods a type (often `struct`) must
   define to be considered an implementation of that interface.
2. When any given type implements all the methods of that interface, the Go
   compiler automatically knows that it is allowed to be used as that type.

This is used to great effect in the Go standard library so that, for instance,
the same interface in `database/sql` can be used to write functionality that
can interact with a variety of different databases using the same code.

Fledgling Go programmers may be familiar with writing unit tests in other
languages such as Java, Python, or PHP, and using "stubs" or "mocks" to fake
out the results of a method call and explore the various code paths you want to
exercise in a fine-grained way.  What many don't seem to realize, however, is
that interfaces can and should be used for this same type of operation in Go.

Due to being built into the language and supported in a huge way by the
standard library, interfaces offer the test author in Go a vast amount of power
and flexibility when used the correct way.  One can wrap operations which are
outside of the scope of a given test in an interface, and selectively
re-implement them for the relevant tests.  This allows the author to control
every aspect of the program's behavior within the test suite.

## Using composition

Interfaces are great for increased flexibility and control, but they are not
enough on their own.  Consider, for instance, the case where we have a `struct`
which exposes a large set of methods to external consumers but also relies on
these methods internally for some operations.  We cannot wrap the whole object
in an interface to control the methods it relies on, since this would require
implementing the method we are trying to test.

Consequently, it becomes critical to compose larger interfaces from smaller
ones through embedding to enable control of the methods which we _do_ want to
change while still being able to test the ones we don't want to change.  This
is a bit easier to see in an actual example, so I will eschew further abstract
discussion until later in the article.

## `go test` and `testing`

This may seem obvious, but at least skimming the documentation for the `go
test` command and the `testing` package and familiarizing yourself with how
each works will make you much more effective at unit testing.  The tools and
library can seem a bit quirky if you are not familiar with them or with Go
tooling in general (though they are very nice once acclimated).

It might be tempting to reach for a 3rd party package which promises to help
with testing, but I highly encourage you to avoid doing so until you have a
handle on the basics and are absolutely certain that the dependency will bring
you more benefit than headaches.

Please, please, read the docs, but the basic knowledge you need to get started is:

- For any given file `foo.go`, the test is placed in a file in the same
  directory called `foo_test.go`.
- `go test .` runs the unit tests in the current directory.  `go test ./...`
  will run the tests in the current directory and every directory underneath
  it.  `go test foo_test.go` not work because the file under test is not
  included.
- The `-v` flag for `go test` is useful because it prints out verbose output
  (the result of each individual test).
- Tests are functions which accept a `testing.T` struct pointer as an argument
  and are idiomatically called `TestFoo`, where `Foo` is the name of the
  function being tested.
- You usually do not assert that conditions you expect are true like you may be
  accustomed to; rather, you fail the test by calling `t.Fatal` if you
  encounter conditions which are different than you expect.
- Displaying output in tests may not work [how you
  expect](http://stackoverflow.com/questions/23205419/how-do-you-print-in-a-go-test-using-the-testing-package)
   -- use the `t.Log` and/or `t.Logf` methods if you need to print information
  in a test.

### Examples

Enough discussion of fundamentals; let's write some tests.

If you are curious to check out the source code in its final form for the
following examples, they are organized in separate directories at
[https://github.com/nathanleclaire/testing-article](https://github.com/nathanleclaire/testing-article).

## Example #1: Hello, Testing!

I'm assuming that you have Go installed and configured for these exercises.

Make a new Go package in your `GOPATH`, e.g. I would execute:

<pre>
$ mkdir -p ~/go/src/github.com/nathanleclaire/testing-article
$ cd ~/go/src/github.com/nathanleclaire/testing-article
</pre>

Create a file `hello.go`:

```go
package main

import (
        "fmt"
)

func hello() string {
        return "Hello, Testing!"
}

func main() {
        fmt.Println(hello())
}
```

Now let's write a test for `hello.go`.

Make a file `hello_test.go` in the same directory:

```go
package main

import (
        "testing"
)

func TestHello(t *testing.T) {
        expectedStr := "Hello, Testing!"
        result := hello()
        if result != expectedStr {
                t.Fatalf("Expected %s, got %s", expectedStr, result)
        }
}
```

Hopefully this test should be pretty self-explanatory.  We inject an instance
of `*testing.T` to the test, and this is used to control the test flow and
output.  We set what our expectations for the function call are in one
variable, and then check it against what the function actually returns.

To run the test:

<pre>
$ go test -v
=== RUN   TestHello
--- PASS: TestHello (0.00s)
PASS
ok      github.com/nathanleclaire/testing-article       0.006s
</pre>

Great, now let's try something more complex.

## Example #2: Using an interface to mock results

Let's say that as part of a program we wanted to get some data from the GitHub
API.  In this case, let's say we wanted to query the git tag which the latest
release of a given repo corresponds to.

We _could_ write some code like the following to do so:

```
package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

type ReleasesInfo struct {
	Id      uint   `json:"id"`
	TagName string `json:"tag_name"`
}

// Function to actually query the GitHub API for the release information.
func getLatestReleaseTag(repo string) (string, error) {
	apiUrl := fmt.Sprintf("https://api.github.com/repos/%s/releases", repo)
	response, err := http.Get(apiUrl)
	if err != nil {
		return "", err
	}

	defer response.Body.Close()

	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return "", err
	}

	releases := []ReleasesInfo{}

	if err := json.Unmarshal(body, &releases); err != nil {
		return "", err
	}

	tag := releases[0].TagName

	return tag, nil
}

// Function to get the message to display to the end user.
func getReleaseTagMessage(repo string) (string, error) {
	tag, err := getLatestReleaseTag(repo)
	if err != nil {
                return "", fmt.Errorf("Error querying GitHub API: %s", err)
	}

        return fmt.Sprintf("The latest release is %s", tag), nil
}

func main() {
        msg, err := getReleaseTagMessage("docker/machine")
        if err != nil {
                fmt.Fprintln(os.Stderr, msg)
        }

        fmt.Println(msg)
}
```

And, in fact, this is commonly how one will see Go programs structured in the
wild.

But it is not very testable.  If we were to test the `getLatestReleaseTag`
function directly, our test would fail if the GitHub API went down or if GitHub
decided to rate limit us (which is likely if running the test frequently such
as in CI environments).  Additionally, we'd have to update the test every time
that the latest release tag changed.  Yuck.

What to do?  We can re-define the way that this is implemented to be a lot more
testable.  If we query the GitHub API through an `interface` instead of
directly through a function call, then we can actually control the result of
what will be returned through our test.

Let's redefine the program a bit to have an interface, `ReleaseInfoer`, of
which one implementation can be `GithubReleaseInfoer`.  `ReleaseInfoer` only
has one method, `GetLatestReleaseTag`, which is similar in nature to our
function above (it accepts a repository name as an argument and returns a
`string` and/or `error` for the result).

The `interface` definition looks like:

```go
type ReleaseInfoer interface {
        GetLatestReleaseTag(string) (string, error)
}
```

Then, we can update our above bare function call to be a method on a
`GithubReleaseInfoer` struct instead:

```go
type GithubReleaseInfoer struct {}

// Function to actually query the GitHub API for the release information.
func (gh GithubReleaseInfoer) GetLatestReleaseTag(repo string) (string, error) {
        // ... same code as above
}
```

And, consequently, update the `getReleaseTagMessage` and `main` functions like
so:

```
// Function to get the message to display to the end user.
func getReleaseTagMessage(ri ReleaseInfoer, repo string) (string, error) {
	tag, err := ri.GetLatestReleaseTag(repo)
	if err != nil {
                return "", fmt.Errorf("Error query GitHub API: %s", err)
	}

        return fmt.Sprintf("The latest release is %s", tag), nil
}

func main() {
        gh := GithubReleaseInfoer{}
        msg, err := getReleaseTagMessage(gh, "docker/machine")
        if err != nil {
                fmt.Fprintln(os.Stderr, err)
                os.Exit(1)
        }

        fmt.Println(msg)
}
```

Why bother?  Well, now we can actually test the `getReleaseTagMessage` function
by defining a new struct that fulfills the `ReleaseInfoer` interface with a
method which we control completely.  That way, at test time, we can ensure that
the behavior of the method which we depend on is exactly as we expect.

We could define a `FakeReleaseInfoer` struct which behaves however we want.  We
simply define what to return in the parameters of the struct.

```
package main

import "testing"

type FakeReleaseInfoer struct {
	Tag string
	Err error
}

func (f FakeReleaseInfoer) GetLatestReleaseTag(repo string) (string, error) {
	if f.Err != nil {
		return "", f.Err
	}

	return f.Tag, nil
}

func TestGetReleaseTagMessage(t *testing.T) {
	f := FakeReleaseInfoer{
		Tag: "v0.1.0",
		Err: nil,
	}

	expectedMsg := "The latest release is v0.1.0"
	msg, err := getReleaseTagMessage(f, "dev/null")
	if err != nil {
		t.Fatalf("Expected err to be nil but it was %s", err)
	}

	if expectedMsg != msg {
		t.Fatalf("Expected %s but got %s", expectedMsg, msg)
	}
}
```

You can see above that the `FakeReleaseInfoer` struct was set to return
`"v0.1.0"` and the returned error was set to nil.

That's great for this case, but notice we're not testing our error return.  It
would be preferable to cover this case as well.

{{%img src="/images/gounit/coverage.png" %}}

Is there any way to express the various paths and return possibilities for this
function concisely in our unit tests? Certainly. We can test a wide variety of
cases in one function with an anonymous struct slice (thanks to [Andrew
Gerrand's talk](https://talks.golang.org/2012/10things.slide#3) and [David
Cheney's article on test
tables](http://dave.cheney.net/2013/06/09/writing-table-driven-tests-in-go) for
this idea).

```
func TestGetReleaseTagMessage(t *testing.T) {
        cases := []struct {
                f           FakeReleaseInfoer
                repo        string
                expectedMsg string
                expectedErr error
        }{
                {
                        f: FakeReleaseInfoer{
                                Tag: "v0.1.0",
                                Err: nil,
                        },
                        repo:        "doesnt/matter",
                        expectedMsg: "The latest release is v0.1.0",
                        expectedErr: nil,
                },
                {
                        f: FakeReleaseInfoer{
                                Tag: "v0.1.0",
                                Err: errors.New("TCP timeout"),
                        },
                        repo:        "doesnt/foo",
                        expectedMsg: "",
                        expectedErr: errors.New("Error querying GitHub API: TCP timeout"),
                },
        }

        for _, c := range cases {
                msg, err := getReleaseTagMessage(c.f, c.repo)
                if !reflect.DeepEqual(err, c.expectedErr) {
                        t.Errorf("Expected err to be %q but it was %q", c.expectedErr, err)
                }

                if c.expectedMsg != msg {
                        t.Errorf("Expected %q but got %q", c.expectedMsg, msg)
                }
        }
}
```

Note the use of `reflect.DeepEqual` there.  It's a [useful
method](https://golang.org/pkg/reflect/#DeepEqual) from the standard library
which will check if two structs are equal by value.  It's used to check error
equality here, but it also could be used to compare the contents of two
`struct`s.  Just `==` alone won't work for equality for this due to the use of
`errors.New` (I tried using the `Error` method but that doesn't work with `nil`
value errors, so if anyone has better ideas please mention it in the comments).

Something to take note of is that this technique can be used to gain more
control over 3rd party libraries in tests.  For instance, [Sam Alba's Golang
Docker client](https://github.com/samalba/dockerclient) will give you a `type
DockerClient struct` to interact with, which is not easily mock-able for tests.
But you could create a `type DockerClient interface` in your own module which
specifies the methods you are using on `dockerclient.DockerClient` as the
things to implement, use that in your code instead, and then create your own
version of that interface for testing.

Aside from the benefits to testability which I'm focusing on here, using
interfaces can potentially be a huge boon for future extensibility of your
program.  If you have structured every component which interacts with the
GitHub API as working through an interface, for instance, you won't need to
change your program's architecture at all to add support for another source
code hosting platform.  You could simply implement a `BitbucketReleaseInfoer`
and use that wherever you want to wrap the Bitbucket API instead of GitHub.
Granted, this type of wrapper abstraction won't work for every use case, but it
can be used powerfully to mock out external and internal dependencies.

## Example #3: Using composition to test a large struct

The above example illustrates an introductory concept which can be very useful,
but sometimes we might want to mock out parts of one `struct` which depend on
each other and test each piece separately.  

If you find yourself with an `interface` or `struct` which is starting to get
larger in terms of the number of methods exposed, it might be a good candidate
for breaking into several smaller `interfaces` and
[embedding](https://golang.org/doc/effective_go.html#embedding) them.  For
instance, let's suppose that we have a `Job` interface which exposes a `Log`
method both internally and externally to the structure.  Any `interface` can be
passed to this method with a variable number of arguments.  It also provides
supported for `Run`ing, `Suspend`ing, and `Resume`ing jobs.

```go
type Job interface {
	Log(...interface{})
	Suspend() error
	Resume() error
	Run() error
}
```

If we are working on developing a `struct` which implements this `interface`,
we may want to use the `Log` method inside of the `Suspend` and `Resume`
methods to keep track of what has happened.  Therefore, faking out the whole
interface like in the previous example won't work.  How do we test the whole
structure while mocking out only part of the interface?

We can do so by defining several smaller interfaces and using composition.
Consider an implementation of a `Job`, `PollerJob`, which can be used for
questionable homebrew system monitoring software.  My first crack at coding it
was this:

```
package main

import (
	"log"
	"net/http"
	"time"
)

type Job interface {
	Log(...interface{})
	Suspend() error
	Resume() error
	Run() error
}

type PollerJob struct {
	suspend     chan bool
	resume      chan bool
	resourceUrl string
	inMemLog    string
}

func NewPollerJob(resourceUrl string) PollerJob {
	return PollerJob{
		resourceUrl: resourceUrl,
		suspend:     make(chan bool),
		resume:      make(chan bool),
	}
}

func (p PollerJob) Log(args ...interface{}) {
	log.Println(args...)
}

func (p PollerJob) Suspend() error {
	p.suspend <- true
	return nil
}

func (p PollerJob) PollServer() error {
	resp, err := http.Get(p.resourceUrl)
	if err != nil {
		return err
	}

	p.Log(p.resourceUrl, "--", resp.Status)

	return nil
}

func (p PollerJob) Run() error {
	for {
		select {
		case <-p.suspend:
			<-p.resume
		default:
			if err := p.PollServer(); err != nil {
				p.Log("Error trying to get resource: ", err)
			}
			time.Sleep(1 * time.Second)
		}
	}
}

func (p PollerJob) Resume() error {
	p.resume <- true
	return nil
}

func main() {
	p := NewPollerJob("https://nathanleclaire.com")
	go p.Run()
	time.Sleep(5 * time.Second)

	p.Log("Suspending monitoring of server for 5 seconds...")
	p.Suspend()
	time.Sleep(5 * time.Second)

	p.Log("Resuming job...")
	p.Resume()

	// Wait for a bit before exiting
	time.Sleep(5 * time.Second)
}
```

The output of the above program, when run, looks like:

<pre>
$ go run -race job.go
2015/10/11 20:37:59 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:01 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:02 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:03 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:04 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:04 Suspending monitoring of server for 5 seconds...
2015/10/11 20:38:10 Resuming job...
2015/10/11 20:38:10 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:11 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:12 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:14 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:15 https://nathanleclaire.com -- 200 OK
2015/10/11 20:38:16 https://nathanleclaire.com -- 200 OK
</pre>

If we want to test the various complex interactions at play here, how do we do
so?  With everything in one structure, it seems to be daunting to test each
component of the program in isolation and without using external resources.

The solution is to break the higher-level `Job` interface into several other
interfaces and embed them all into the `PollerJob` struct, allowing us to mock
out each piece in isolation when we do testing.

We can break the `Job` interface into a few different interfaces like so:

```go
type Logger interface {
	Log(...interface{})
}

type SuspendResumer interface {
	Suspend() error
	Resume() error
}

type Job interface {
	Logger
	SuspendResumer
	Run() error
}
```

You can see that there is an interface `SuspendResumer` for handling
suspend/resume functionality, and an interface `Log` whose only purpose is to
manage the `Log` method. Additionally, we will create a `PollServer` interface
for controlling the status calls to the server we are polling:

```go
type ServerPoller interface {
	PollServer() (string, error)
}
```

With all of these component interfaces in place, we can begin re-constructing
our `PollerJob` implementation of the `Job` interface.  By embedding `Logger`
and `ServerPoller` (both interfaces) and a pointer to a `PollSuspendResumer`
struct, we ensure that the compiler is satisfied for the definition of
`PollerJob` as a `Job`.  We provide a `NewPollerJob` function which will
provide an instance of the struct with all of the components set up and
initialized properly.  Notice that we use our own implementation of the
components such as `Logger` in the struct literal that this function returns.

```go
type PollerLogger struct{}

type URLServerPoller struct {
	resourceUrl string
}

type PollSuspendResumer struct {
	SuspendCh chan bool
	ResumeCh  chan bool
}

type PollerJob struct {
	WaitDuration time.Duration
	ServerPoller
	Logger
	*PollSuspendResumer
}

func NewPollerJob(resourceUrl string, waitDuration time.Duration) PollerJob {
	return PollerJob{
		WaitDuration: waitDuration,
		Logger:       &PollerLogger{},
		ServerPoller: &URLServerPoller{
			resourceUrl: resourceUrl,
		},
		PollSuspendResumer: &PollSuspendResumer{
			SuspendCh: make(chan bool),
			ResumeCh:  make(chan bool),
		},
	}
}
```

The rest of the code defines the methods on the relevant structs, and is
available in full [on GitHub here]().

This provides us with the flexibility that we need to actually fake out each
component of the `PollerJob` struct in isolation when we do testing.  Each
"mock" component can be re-used and/or re-worked to be more flexible where
needed, allowing us to cover a wide range of possible outcomes from the
components which we depend on.

We can now test `Run` in isolation, and without talking to any actual servers.
We simply control what the `ServerPoller` returns and verify that what was
written to the `Logger` was as we expect by re-implementing those interfaces.
Consequently the test file for `PollerJob` looks similar to this.

```go
package main

import (
	"errors"
	"fmt"
	"testing"
	"time"
)

type ReadableLogger interface {
	Logger
	Read() string
}

type MessageReader struct {
	Msg string
}

func (mr *MessageReader) Read() string {
	return mr.Msg
}

type LastEntryLogger struct {
	*MessageReader
}

func (lel *LastEntryLogger) Log(args ...interface{}) {
	lel.Msg = fmt.Sprint(args...)
}

type DiscardFirstWriteLogger struct {
	*MessageReader
	writtenBefore bool
}

func (dfwl *DiscardFirstWriteLogger) Log(args ...interface{}) {
	if dfwl.writtenBefore {
		dfwl.Msg = fmt.Sprint(args...)
	}
	dfwl.writtenBefore = true
}

type FakeServerPoller struct {
	result string
	err    error
}

func (fsp FakeServerPoller) PollServer() (string, error) {
	return fsp.result, fsp.err
}

func TestPollerJobRunLog(t *testing.T) {
	waitBeforeReading := 100 * time.Millisecond
	shortInterval := 20 * time.Millisecond
	longInterval := 200 * time.Millisecond

	testCases := []struct {
		p           PollerJob
		logger      ReadableLogger
		sp          ServerPoller
		expectedMsg string
	}{
		{
			p:           NewPollerJob("madeup.website", shortInterval),
			logger:      &LastEntryLogger{&MessageReader{}},
			sp:          FakeServerPoller{"200 OK", nil},
			expectedMsg: "200 OK",
		},
		{
			p:           NewPollerJob("down.website", shortInterval),
			logger:      &LastEntryLogger{&MessageReader{}},
			sp:          FakeServerPoller{"500 SERVER ERROR", nil},
			expectedMsg: "500 SERVER ERROR",
		},
		{
			p:           NewPollerJob("error.website", shortInterval),
			logger:      &LastEntryLogger{&MessageReader{}},
			sp:          FakeServerPoller{"", errors.New("DNS probe failed")},
			expectedMsg: "Error trying to get state: DNS probe failed",
		},
		{
			p: NewPollerJob("some.website", longInterval),

			// Discard first write since we want to verify that no
			// additional logs get made after the first one (time
			// out)
			logger: &DiscardFirstWriteLogger{MessageReader: &MessageReader{}},

			sp:          FakeServerPoller{"200 OK", nil},
			expectedMsg: "",
		},
	}

	for _, c := range testCases {
		c.p.Logger = c.logger
		c.p.ServerPoller = c.sp

		go c.p.Run()

		time.Sleep(waitBeforeReading)

		if c.logger.Read() != c.expectedMsg {
			t.Errorf("Expected message did not align with what was written:\n\texpected: %q\n\tactual: %q", c.expectedMsg, c.logger.Read())
		}
	}
}
```

Note the creative flexibility that making our own `ReadableLogger` interface
for testing, and being able to implement `Logger` in a variety of ways,
provides us.  `Suspend` and `Resume` functionality can likewise be tested
meticulously by controlling the `ServerPoller` interface component of
`JobPoller`.

```go
func TestPollerJobSuspendResume(t *testing.T) {
	p := NewPollerJob("foobar.com", 20*time.Millisecond)
	waitBeforeReading := 100 * time.Millisecond
	expectedLogLine := "200 OK"
	normalServerPoller := &FakeServerPoller{expectedLogLine, nil}

	logger := &LastEntryLogger{&MessageReader{}}
	p.Logger = logger
	p.ServerPoller = normalServerPoller

	// First start the job / polling
	go p.Run()

	time.Sleep(waitBeforeReading)

	if logger.Read() != expectedLogLine {
		t.Errorf("Line read from logger does not match what was expected:\n\texpected: %q\n\tactual: %q", expectedLogLine, logger.Read())
	}

	// Then suspend the job
	if err := p.Suspend(); err != nil {
		t.Errorf("Expected suspend error to be nil but got %q", err)
	}

	// Fake the log line to detect if poller is still running
	newExpectedLogLine := "500 Internal Server Error"
	logger.MessageReader.Msg = newExpectedLogLine

	// Give it a second to poll if it's going to poll
	time.Sleep(waitBeforeReading)

	// If this log writes, we know we are polling the server when we're not
	// supposed to (job should be suspended).
	if logger.Read() != newExpectedLogLine {
		t.Errorf("Line read from logger does not match what was expected:\n\texpected: %q\n\tactual: %q", newExpectedLogLine, logger.Read())
	}

	if err := p.Resume(); err != nil {
		t.Errorf("Expected resume error to be nil but got %q", err)
	}

	// Give it a second to poll if it's going to poll
	time.Sleep(waitBeforeReading)

	if logger.Read() != expectedLogLine {
		t.Errorf("Line read from logger does not match what was expected:\n\texpected: %q\n\tactual: %q", expectedLogLine, logger.Read())
	}
}
```

It certainly might seem like a lot of boilerplate to test a small file, but it
will scale well as the size of the code base grows.  Mocking out dependent bits
in this fashion makes it easier to specify what behavior should be like in
error cases or to control flow in the case of tricky concurrency issues.

Due to the practical and creative enhancements that interfaces offer to
testability, it is preferred to wrap external dependencies in one and then
combine them to create higher-order interfaces wherever possible.  As you can
hopefully see, even small one-method interfaces are useful to combine into
bigger pieces of functionality.

## Example #4: Using and faking standard library functionality

{{%img src="/images/gounit/magic.png" %}}

The concepts illustrated above are useful for your own programs, but you will
also notice that many of the constructs in the Go standard library can be
managed in your unit tests in a similar fashion (and indeed they _are_
frequently used in such a manner in the tests for the standard library itself).

Let's take a look at testing an example HTTP server.  It might be tempting to
actually start up the HTTP server in a goroutine and send it the requests that
you expect it to be able to handle directly (e.g.  with `http.Get`).  But that
is far more like an integration test than a proper unit test.  Let's take a
look at a little HTTP server and discuss how to approach testing it.

```go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func mainHandler(w http.ResponseWriter, r *http.Request) {
	token := r.Header.Get("X-Access-Token")
	if token == "magic" {
		fmt.Fprintf(w, "You have some magic in you\n")
		log.Println("Allowed an access attempt")
	} else {
		http.Error(w, "You don't have enough magic in you", http.StatusForbidden)
		log.Println("Denied an access attempt")
	}
}

func main() {
	http.HandleFunc("/", mainHandler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

The above HTTP server listens on `:8080/` for requests, and checks if they have
a `X-Access-Token` header set.  If the token matches our `"magic"` value, we
allow the users access and return a HTTP 200 OK status code.  Otherwise, we
reject the request with a HTTP 403 Access Forbidden status code.  This is a
crude imitation of how some API servers handle authorization.  How can we test
it?

As you can see, the `mainHandler` function accepts two arguments: a
`http.ResponseWriter` (note that it is an `interface`, which you can verify by
reading the source of `http` or the documentation) and a `http.Request` struct
pointer.  To test the handler, we could make our own implementation of the
[`http.ResponseWriter`
interface](https://golang.org/pkg/net/http/#ResponseWriter) which we could also
read from later, but fortunately the Go authors have already provided a
`httptest` package with a [`ResponseRecorder`
struct](https://golang.org/pkg/net/http/httptest/#ResponseRecorder) which is
meant to help with exactly this issue.  Having such a module to provide common
testing functionality where needed is a useful and not uncommon pattern.

Given that, we can also create a hand-crafted `http.Request` struct by calling
`NewRequest` with the expected parameters.  We simply have to call `Header.Set`
on the `Request` to set the desired header.  We specify in the `NewRequest`
method that it should be `GET` method and not contain any information in the
request body, though we could also test `POST` requests and so on if we wanted
to by creating structures for those instead.

The initial test looks like this:

```go
package main

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestMainHandler(t *testing.T) {
	rootRequest, err := http.NewRequest("GET", "/", nil)
	if err != nil {
		t.Fatal("Root request error: %s", err)
	}

	cases := []struct {
		w                    *httptest.ResponseRecorder
		r                    *http.Request
		accessTokenHeader    string
		expectedResponseCode int
		expectedResponseBody []byte
	}{
		{
			w:                    httptest.NewRecorder(),
			r:                    rootRequest,
			accessTokenHeader:    "magic",
			expectedResponseCode: http.StatusOK,
			expectedResponseBody: []byte("You have some magic in you\n"),
		},
		{
			w:                    httptest.NewRecorder(),
			r:                    rootRequest,
			accessTokenHeader:    "",
			expectedResponseCode: http.StatusForbidden,
			expectedResponseBody: []byte("You don't have enough magic in you\n"),
		},
	}

	for _, c := range cases {
		c.r.Header.Set("X-Access-Token", c.accessTokenHeader)

		mainHandler(c.w, c.r)

		if c.expectedResponseCode != c.w.Code {
			t.Errorf("Status Code didn't match:\n\t%q\n\t%q", c.expectedResponseCode, c.w.Code)
		}

		if !bytes.Equal(c.expectedResponseBody, c.w.Body.Bytes()) {
			t.Errorf("Body didn't match:\n\t%q\n\t%q", string(c.expectedResponseBody), c.w.Body.String())
		}
	}
}
```

However, there is one glaring omission of testing functionality we can account
for.  We do not check that what was written to the `log` is what we expected at
all.  How can we do so?

Well, if we examine the source for the standard library's `log` package, we can
see that the `log.Println` method directly wraps an instance of the `Logger`
struct which internally calls the `Write` method on a `Writer` interface (in
the case of the `std` struct which is written to if you invoke `log.*`
directly, that `Writer` is `os.Stdout`).  Hm, I wonder if there's any way we
could set that interface to whatever we want so we can verify that what was
written is what we expected?

Naturally, there is a way to do so.  We can invoke the `log.SetOutput` method
to specify our own custom writer for logging to.  In order to pass something in
which we can read from later, we create the `Writer` to pass in using
[`io.Pipe`](https://golang.org/pkg/io/#Pipe).  This will provide us with a
`Reader` that we can use to `Read` the subsequent `Write` calls made in the
`Logger`.  We wrap the given `PipeReader` in a `bufio.Reader` so that we can
easily read line-by-line using a call to `bufio.Reader`'s `ReadString` method.

Note that in `PipeWriter`'s
[documentation](https://golang.org/pkg/io/#PipeWriter.Write) it says:

> Write implements the standard Write interface: it writes data to the pipe,
> blocking until readers have consumed all the data or the read end is closed.

Therefore, we have to concurrently read from the `PipeReader` as the
`mainHandler` function is writing to it, so we run that bit of the test in its
own goroutine.  In my original version I got this wrong and discovered my error
by using `go test`'s `-timeout` flag, which will panic any given test if it
stalls for longer than the specified interval.

Put together, it all looks like this:

```go
func TestMainHandler(t *testing.T) {
	rootRequest, err := http.NewRequest("GET", "/", nil)
	if err != nil {
		t.Fatal("Root request error: %s", err)
	}

	cases := []struct {
		w                    *httptest.ResponseRecorder
		r                    *http.Request
		accessTokenHeader    string
		expectedResponseCode int
		expectedResponseBody []byte
		expectedLogs         []string
	}{
		{
			w:                    httptest.NewRecorder(),
			r:                    rootRequest,
			accessTokenHeader:    "magic",
			expectedResponseCode: http.StatusOK,
			expectedResponseBody: []byte("You have some magic in you\n"),
			expectedLogs: []string{
				"Allowed an access attempt\n",
			},
		},
		{
			w:                    httptest.NewRecorder(),
			r:                    rootRequest,
			accessTokenHeader:    "",
			expectedResponseCode: http.StatusForbidden,
			expectedResponseBody: []byte("You don't have enough magic in you\n"),
			expectedLogs: []string{
				"Denied an access attempt\n",
			},
		},
	}

	for _, c := range cases {
		logReader, logWriter := io.Pipe()
		bufLogReader := bufio.NewReader(logReader)
		log.SetOutput(logWriter)

		c.r.Header.Set("X-Access-Token", c.accessTokenHeader)

		go func() {
			for _, expectedLine := range c.expectedLogs {
				msg, err := bufLogReader.ReadString('\n')
				if err != nil {
					t.Errorf("Expected to be able to read from log but got error: %s", err)
				}
				if !strings.HasSuffix(msg, expectedLine) {
					t.Errorf("Log line didn't match suffix:\n\t%q\n\t%q", expectedLine, msg)
				}
			}
		}()

		mainHandler(c.w, c.r)

		if c.expectedResponseCode != c.w.Code {
			t.Errorf("Status Code didn't match:\n\t%q\n\t%q", c.expectedResponseCode, c.w.Code)
		}

		if !bytes.Equal(c.expectedResponseBody, c.w.Body.Bytes()) {
			t.Errorf("Body didn't match:\n\t%q\n\t%q", string(c.expectedResponseBody), c.w.Body.String())
		}
	}
}
```

I hope that this example illustrates clearly the value of having
well-architected interfaces in the Go standard library as well as in your own
code, and how reading the source code of modules upon which you are relying
(including the Go standard library, which is meticulously documented) can make
your understanding of the code you are working with better as well as ease
testing.
