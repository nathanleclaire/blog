---
layout: post
title: "Docker Machine Design Principles I: Failure is the Norm"
date: "2015-03-09"
draft: true
---

![](/images/docker-machine/whale.jpg)

Howdy all, lately I've been contributing to [Docker
Machine](https://github.com/docker/machine) and I wanted to write up some
thoughts that I've had lately about how the design direction for the future of
the project should go.  Namely, they are the principles which I think are
uncannily important to remember in the implementation of any project with a
scope similar to Machine's.

Today's design principle is:

> Failure is the Norm.  Act accordingly.

It sounds simple and obvious, but generally I've found programmers (myself
included) have a tendency to be over-optimistic in our assumptions.  I think
it's just a natural personality quirk of the types of people who get into
computers; how else could you get through brutal nights and cold unforgiving
debug cycles with the compiler?  You have to have a vision and a belief that
your attempts will succeed.

At any rate, I think that this swing of the pendulum expresses itself in our
tendency to _YOLO_ with assumptions in code.

This is why the [Fallacies of Distributed
Computing](http://en.wikipedia.org/wiki/Fallacies_of_distributed_computing) warn
of so many issues (related to the network in particular) which could throw off
our game when we're trying to implement such a system.  It's exactly these types
of issues that Machine has run into in the past, and will in the future, so I
wanted to have a conversation with you about the direction that I want to take
Machine to in the future, so that we can create the best possible project for
people.

# Failure in the Norm

Many many times I've run into issues with the network, with assumptions that
we've make the code which turned out to be faulty, and so on.  It's led me to
believe that uncertainty is a fundamental part of modern computing.  Failure is
the _new normal_;  especially in distributed systems you can't expect every node
to be up all of the time, or accurate, or responding with 100% success.  And so
we've run into similar problems with Docker Machine.

What can one do about this?  Well, in our case, so far we've coded around it
with a variety of strategies.  Since an important part of Machine to me (and I'm
assuming to other maintainers and contributors) is its ad-hoc, "spongy"
interactive nature, I would prefer not to delve too deep on long-running
processes or daemons from the main Machine experience.  Instead, we have worked
around things in part by using retries and timeouts.

Consider the following situation, for starters, to get a feel for the types of
uncertainty that the Machine program must contend with on a regular basis.

1.  The user wants to create a new host running on Amazon's Elastic Compute
    Cloud.
2.  The user invokes `docker-machine create -d amazonec2 jungle` after setting
    the proper environment variables required to aunthenticate as their user on
    AWS.
3.  The driver for `amazonec2` calls out to an Amazon API to create the
    instance, but disconnects from the WiFi halfway through the creation.

Well, what now?  Originally in some of `docker-machine`'s implementation, this
bit us a lot.  The window of failure between when we would save the critical
information (instance ID for future lookup and querying in this case) after
obtaining / validating it  was biting us really hard; and this is a simple use
case, so how would we even begin to handle the very erratic and unstable
situation where a user has done something like send a `SIGINT` (e.g. `CTRL+C`)
to the program in the middle of it doing something.

- Nathan
