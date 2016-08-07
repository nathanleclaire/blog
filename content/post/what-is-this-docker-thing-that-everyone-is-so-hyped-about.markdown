---
layout: post
title: "What is this Docker thing that everyone is so hyped about?"
date: "2014-03-22"
comments: true
categories: [docker,containers,virtualization,vagrant]
---

{{%img src="/images/what-is-docker/moby-dick.jpg" caption="Just another day in Devops. " %}}

# Docker

Approximately one year ago I was browsing [Hacker News](http://news.ycombinator.com) and I came across this video:

<div style="text-align: center;">
<iframe style="width: 420px !important;" width="420" height="315" src="//www.youtube.com/embed/wW9CAH9nSLs" frameborder="0" allowfullscreen></iframe>
</div>

I found it profoundly exciting for reasons I could not explain, mostly Solomon's infectious enthusiasm and the enthusiasm that the Hacker News commmunity reacted to it with.  When I learned that Docker was being written in [Go](http://golang.org) I was even more intruiged.  Especially having played with Go quite a bit, I have a hunch that Go will be a language which dictates the future of the "cloud" in a lot of ways.  [Cloudflare](http://cloudflare.com), for instance, has a ton of infrastructure written in Go that powers their CDN and other cool tools they provide such as [Railgun](https://www.cloudflare.com/railgun).  This was definitely a project to keep an eye on.  I mentally dog-eared it.

There was only one problem:  I didn't understand what Docker *was* yet.  There was talk of containers and shipping but I didn't understand what it all meant, or what it could be used for.

Then about six months ago, things began to gel and sink in for me.

# The Problem

{{%img src="/images/what-is-docker/matrix-from-hell.png" caption="" %}}

In order to better understand Docker you have to understand the problem it is trying to solve.

Modern day development (I'll be focusing on the web here) lives in a world of lots of complexity.  In even the most basic application you are likely to have a back-end language that lives on the server, a front-end language (almost ubiquitously JavaScript) that lives on the client, third-party and in-house libraries for both of these languages to manage, a database, an operating system (often deploying to Linux but developing on God-knows-what OS), and more.  And this is for a *basic* app!  What if you have utility programs that are written in another language?  What if you have other weird dependencies and requirements?

My point is that this all adds up to a lot of complexity, and worst of all- it is complexity that you have to manage across multiple platforms.  If I got an app up and running on my Macbook, and wanted to deploy to Linux, my options were not great.  If you've ever administrated your own VPS, much less a bare metal server, you know what I mean.  Having to install all of the packages and dependencies that you have in a totally different way is a recipe for headaches and tears.  Getting stuff to production is a completely different ball game from writing it in the first place.  Different technologies on different platforms create a "Matrix from Hell" (pictured above) that makes even the most courageous ops person want to set her hair on fire.

Traditionally there have been a variety of solutions that have popped up in response to this, ranging from "just develop in PHP and FTP is your deploy" (ew) to [Heroku](http://heroku.com) (`git push heroku master` is your deploy) to virtualization with provisioning (see [Vagrant](http://vagrantup.com)).  Vagrant in particular has been gaining a lot of steam lately, for very good reason, and is a great technology (see my post on [how we won Startup Weekend](https://nathanleclaire.com/blog/2014/02/10/5-reasons-we-won-startup-weekend/) if you're curious why Vagrant was useful to us in that case).  However, virtual machines have several disadvantages as well.  Because the VM software has to simulate actual physical hardware, you take a big performance hit.  They are slow to start up and, especially before Vagrant started to become popular, difficult to get inexperienced developers started on (Download Vagrant and its dependencies and run `vagrant up` is a lot nicer than going through all of the VirtualBox menus, then provisioning your box manually). 

# Containers

{{%img src="/images/what-is-docker/containers.jpg" caption="" %}}

[Containers](https://linuxcontainers.org/) popped up as a solution to this issue.  They are sort of like virtual machines, but they focus on process isolation and containment instead of emulating a full-fledged physical machine.  The "guest" container uses the same kernel as the "host" machine (and possibly some other resources as well, but my understanding of this at this time is a little fuzzy).  This allows many of the advantages of virtual machines without some of the aforementioned disadvantages.

Enter [Docker](http://docker.io) (from the homepage):

> Docker is an open-source project to easily create lightweight, portable, self-sufficient containers from any application. The same container that a developer builds and tests on a laptop can run at scale, in production, on VMs, bare metal, OpenStack clusters, public clouds and more.

{{%img src="/images/what-is-docker/docker.png" caption="" %}}

Docker's goal is to provide a software solution that will allow users to "pack up" their applications into a standardized container and "ship it off" to wherever their heart desires.  A container, once developed, can be deployed anywhere that Docker runs.  They compare these containers to actual [physical shipping containers](http://en.wikipedia.org/wiki/Containerization), pictured above, which revolutionized international trade when it was standardized after World War 2.  From Wikipedia:

> Containerization dramatically reduced transport costs ... reduced congestion in ports, significantly shortened shipping time, and reduced losses from damage and theft.

Sound like benefits that would be nice to have for your business? 

# A Cambrian Explosion

{{%img src="/images/what-is-docker/cambrian.png" caption="" %}}

What is really interesting about Docker though, to me personally at least, is the Cambrian Explosion-esque fugue of creativity that it has inspired so far and continues to inspire in people everywhere.  It is being used for things online that aren't exactly aligned to its original use case but really hearken to a bold new future of tech.  I know of at least one example where it is being used to make possible a interpreter-by-runnable-code editor for conducting Python interviews.  [Runnable.com](http://www.runnable.com) uses Docker to host self-contained executable / editable little code projects where you can look at existing code which you know works, edit it on the fly, and re-run it.  That's awesome!

I'm super optimistic for the future of this technology.

Until next time, stay sassy Internet.

- Nathan
