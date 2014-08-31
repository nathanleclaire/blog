---
layout: post
title: "Why codegangsta's cli package is the bomb, and you should use it"
date: 2014-08-30 23:18:50 -0700
comments: true
categories: [go]
---


# go go go

{%img /images/cli/codegangsta.png Blowing other gangsters (and coders) to smithereens. %}

This week I'm writing an opinion piece on why I think that [codegangsta](https://github.com/codegangsta/cli)'s command line interface package for Golang is great, and you should use it.  Nice job, contributors!

The reasons are:

1. Well designed, and a pleasure to use
2. Lets you get stuff done
3. Flags are how they're meant to be
4. Well documented
5. Friendly community

## Well designed, and a pleasure to use

This is the library that you dreamed about when you first learned how to use `argv` and `argc` in C.  If you've ever tried parsing `argv` by hand (without relying on an external library), you know that it can be a pain and require a lot of strenuous fixing up with duct tape in order to get working effectively.  Well no more now.  Just:

- `import "github.com/codegangsta/cli"`
- get an instance of `cli.App`
- set actions and usage, and quickly get to making the thing you set out to!!

As evidenced by the popularity of [Martini](https://github.com/codegangsta/martini) and [Negroni](https://github.com/codegangsta/negroni), codegangsta has good taste when it comes to designing APIs for developers to consume.  I've used `cli` for a variety of things now, and it's very flexible while still be incredibly effective.

I mean come on, this just _looks_ incredibly fun:

```
/* greet.go */
package main

import (
  "os"
  "github.com/codegangsta/cli"
)

func main() {
  app := cli.NewApp()
  app.Name = "greet"
  app.Usage = "fight the loneliness!"
  app.Action = func(c *cli.Context) {
    println("Hello friend!")
  }

  app.Run(os.Args)
}
```

And gives you stuff like _this_:

```
$ greet help
NAME:
    greet - fight the loneliness!

USAGE:
    greet [global options] command [command options] [arguments...]

VERSION:
    0.0.0

COMMANDS:
    help, h  Shows a list of commands or help for one command

GLOBAL OPTIONS
    --version   Shows version information
```

From the manual:

> cli.go also generates some bitchass help text:

+1

## Lets you get stuff done

I sorted of hinted at this, but this is what I see as the main advantage of `cli` over using nothing, or just using raw `flag` parsing, it allows you to handle the inevitable complexity of developing a command line application before it even becomes an issue.

I've long noticed that developers love libraries the most when you barely even notice they're there.  The framework or tool becomes like an extension of your own mind in solving the problem.  In my opinion, jQuery is like this.  It inspires such a raw explosion of creativity in the people using it that its explosion and proliferation was inevitable.  Instead of making you cobble together vanilla JavaScript to get what you want, you can work way further up in many different ways which are _all right_.  Go is like that too, with `gofmt` and Go's error handling patterns etc. at play everyone's code starts to look the same.

That's what `cli` is like.  It just gets out of the way, and lets you write the application that you actually came here to write.

## Flags are how they're meant to be

I have to admit, I _LOVE_ flags.  I grew up on a steady diet of UNIX weirdness and writing apps that have crazy flag fun is fantastic.  `cli`'s API is easy to follow.  Even a complicated structure retains order.  For instance, a sample from a rewrite of [fig](fig) in Go that I've been doing:

```go
// global level flags
app.Flags = []gangstaCli.Flag{
	gangstaCli.BoolFlag{
		Name:  "verbose",
		Usage: "Show more output",
	},
	gangstaCli.StringFlag{
		Name:  "f, file",
		Usage: "Specify an alternate fig file (default: fig.yml)",
	},
	gangstaCli.StringFlag{
		Name:  "p, project-name",
		Usage: "Specify an alternate project name (default: directory name)",
	},
}

// Commands
app.Commands = []gangstaCli.Command{
	{
		Name: "build",
		Flags: []gangstaCli.Flag{
			gangstaCli.BoolFlag{
				Name:  "no-cache",
				Usage: "Do not use cache when building the image.",
			},
		},
		Usage:  "Build or rebuild services",
		Action: CmdBuild,
	},
	// etc...
	{
		Name: "run",
		Flags: []gangstaCli.Flag{
			gangstaCli.BoolFlag{
				Name:  "d",
				Usage: "Detached mode: Run container in the background, print new container name.",
			},
			gangstaCli.BoolFlag{
				Name:  "T",
				Usage: "Disables psuedo-tty allocation. By default `fig run` allocates a TTY.",
			},
			gangstaCli.BoolFlag{
				Name:  "rm",
				Usage: "Remove container after run.  Ignored in detached mode.",
			},
			gangstaCli.BoolFlag{
				Name:  "no-deps",
				Usage: "Don't start linked services.",
			},
		},
		Usage:  "Run a one-off command",
		Action: CmdRm,
	},
	
	{
		Name: "up",
		Flags: []gangstaCli.Flag{
			gangstaCli.BoolFlag{
				Name:  "watch",
				Usage: "Watch build directory for changes and auto-rebuild/restart",
			},
			gangstaCli.BoolFlag{
				Name:  "d",
				Usage: "Detached mode: Run containers in the background, print new container names.",
			},
			gangstaCli.BoolFlag{
				Name:  "k,kill",
				Usage: "Kill instead of stop on terminal stignal",
			},
			gangstaCli.BoolFlag{
				Name:  "no-clean",
				Usage: "Don't remove containers after termination signal interrupt (CTRL+C)",
			},
			gangstaCli.BoolFlag{
				Name:  "no-deps",
				Usage: "Don't start linked services.",
			},
			gangstaCli.BoolFlag{
				Name:  "no-recreate",
				Usage: "If containers already exist, don't recreate them.",
			},
		},
		Usage:  "Create and start containers",
		Action: CmdUp,
	},
}
```

It always drove me crazy that Golang's default `flag` package preferred `-name` style (one hyphen) flags  by default, although there may be a good reason for it that I'm not aware of.  `cli` does `--long-flags` this way by default.  Yay!

It supports multiple forms of flags (e.g. `-v` and `--verbose`).  You get subcommands too (e.g. `git remote add`, `git remote rm`).  It's an incredible amount of power and flexibility.

## Well documented

I was able to divine pretty much everything I needed to write an effective app with this library quite easily from the documentation.  'Nuff said.  That's a rare honor in this world of half-baked Github repos, Gists, and JSFiddles.

## Friendly community

codegangsta and crew are pretty active on Github (and I would guess IRC, but I don't know this for a fact).  Proposals for new features and the like are not met with hostility on Github, instead they are discussed with civility.  I hate seeing Github issues devolve into flame wars and I definitely think community matters a lot in weeding out the bad actors to keep the experience of discussing software a pleasurable one.

# What are the downsides?

Like anything new, `cli` has a few downsides too.

- [this bug about the flag parsing terminator (`--`)](https://github.com/codegangsta/cli/issues/56)
- Performance (probably not a concern for most apps)
- Still early in development

In spite of these issues, obviously I think `cli` is really great for getting applications out the door quickly with Go.  I am hopeful that its great design and philosophy will influence future libraries, frameworks, and software.  :thumbsup:

# Fin.

I like this library.  Use it.

Until next time, stay sassy Internet.

- Nathan