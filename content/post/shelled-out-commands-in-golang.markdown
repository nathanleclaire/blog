---
layout: post
title: "Shelled-out Commands In Golang"
date: "2014-12-29"
---

# The Nate Shells Out

In a perfect world we would have beautifully designed APIs and bindings for everything that we could possibly desire and that includes things which we might want to invoke the shell to do (e.g. run `imagemagick` commands, invoke `git`, invoke `docker` etc.).  But especially with burgeoning languages such as [Go](http://golang.org/), it's not as likely that such a module exists (or that it's easy to use, robust, well-tested, etc.) as it is with a more mature language such as Python.  So, we might become shellouts.

{{%img src="/images/goshell/shell.png" %}}


## What do you mean?

Go allows you to invoke commands directly from the language using some primitives defined in the `os/exec` package.  It's not as easy as it can be in, say, Ruby where you just backtick the command and read the output into a variable, but it's not too bad.  The basic usage is through the `Cmd` struct and you can invoke commands and do a variety of things with their results.  

`exec.Command()` takes a command and its arguments as arguments and returns a `Cmd` struct.  You can then call `Run` on that struct to actually run the command and wait for its results to get back.  This can be condensed into a single line for brevity using Go's multi-statement `if` style.  Consider the following example where we can use Go to execute an `imagemagick` command to half the size of an image:

```go
package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	cmd := "convert"
	args := []string{"-resize", "50%", "foo.jpg", "foo.half.jpg"}
	if err := exec.Command(cmd, args...).Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Println("Successfully halved image in size")
}
```

Cool, running shell commands in Go isn't too bad.  But what if we want to get the output, to display it or parse some information out of it?  We can use `Cmd` struct's `Output` method to get a byte slice.  This is trivially convertable to a string if that is what you're after, too.


```go
package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	var (
		cmdOut []byte
		err    error
	)
	cmdName := "git"
	cmdArgs := []string{"rev-parse", "--verify", "HEAD"}
	if cmdOut, err = exec.Command(cmdName, cmdArgs...).Output(); err != nil {
		fmt.Fprintln(os.Stderr, "There was an error running git rev-parse command: ", err)
		os.Exit(1)
	}
	sha := string(cmdOut)
	firstSix := sha[:6]
	fmt.Println("The first six chars of the SHA at HEAD in this repo are", firstSix)
}
```


## Now show me something _really_ cool.

OK, let's look at an example of streaming the output of a command line-by-line for transformation.  There are a variety of reasons why you might want to do this.  You may want to append some logging output on the front of the line, which is the use case I will demonstrate here.  You may want to apply some sort of transformation on the output as it is coming in.  You may simply want to parse out the bits you are interested in and discard the rest, and it's just a more natural fit to do so line-by-line instead of in one big string or byte slice.  Or, you may want to just see the output of a long-running command as it comes in.

```go
package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
)

func main() {
	// docker build current directory
	cmdName := "docker"
	cmdArgs := []string{"build", "."}

	cmd := exec.Command(cmdName, cmdArgs...)
	cmdReader, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error creating StdoutPipe for Cmd", err)
		os.Exit(1)
	}

	scanner := bufio.NewScanner(cmdReader)
	go func() {
		for scanner.Scan() {
			fmt.Printf("docker build out | %s\n", scanner.Text())
		}
	}()

	err = cmd.Start()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error starting Cmd", err)
		os.Exit(1)
	}

	err = cmd.Wait()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error waiting for Cmd", err)
		os.Exit(1)
	}
}
```

## Come on, you can do better than that.

OK, how about writing an agnostic function to execute shell commands on a remote computer?  With `ssh` and `Cmd` you can do it.

We could make a simple struct called `SSHCommander` where you pass user and server IP.  Then you invoke `Command` to run commands over SSH!  If your keys are in alignment, it will work.

```go
package main

import (
	"fmt"
	"os"
	"os/exec"
)

type SSHCommander struct {
	User string
	IP   string
}

func (s *SSHCommander) Command(cmd ...string) *exec.Cmd {
	arg := append(
		[]string{
			fmt.Sprintf("%s@%s", s.User, s.IP),
		},
		cmd...,
	)
	return exec.Command("ssh", arg...)
}

func main() {
	commander := SSHCommander{"root", "50.112.213.24"}

	cmd := []string{
		"apt-get",
		"install",
		"-y",
		"jq",
		"golang-go",
		"nginx",
	}

	// am I doing this automation thing right?
	if err := commander.Command(cmd...); err != nil {
		fmt.Fprintln(os.Stderr, "There was an error running SSH command: ", err)
		os.Exit(1)
	}
}
```

I stole this idea from the work we've been doing lately on [docker hosts]().  Good times.

## What's the downside?

I'm glad you asked.  There are a few notable downsides.  One, it's pretty hacky and inelegant to do this.  Ideally one would have clearly defined APIs or bindings to use that would mitigate the need to shell out commands.  Maintaining code which shells out commands will be a maintainability headache (commands often fail in opaque ways) and will be harder to grok for newcomers to the codebase (or yourself after a break) due to its lack of concision and clarity.

It definitely breaks cross-platform compatibility and repeatability.  If the user doesn't have the program you're expecting, or doesn't have it named correctly, etc., you're hosed.  Additionally, it won't end well to make assumptions that this program will be run in a UNIX shell if you eventually want a cross-platform Go binary: so be careful about pipes and the like.

However, it's pretty fun when it works.  So just be prepared to accept the consequences if you do it.

# Fin

That's all: have fun doing shelly things in Go-land everyone.

And until next time, stay sassy Internet.

- Nathan
