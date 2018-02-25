---
layout: post
title: "Do We Need a Community for Vagrantfiles?"
date: "2014-05-02"
comments: true
categories: [vagrant]
---

# vagrant up

{{%img src="/images/swaa/vagrant.png" caption="" %}}

For those of you who are unfamiliar, [Vagrant](http://www.vagrantup.com/) is "development environments made easy".

> Create and configure lightweight, reproducible, and portable development environments.

Vagrant is a command line tool that aids in the creation and provisioning of development environments.  Why is it important?  Let's say that you want to work on a Django application.  In order to get started with even basic work on the application you need Python installed, probably pip and virtualenv, the dependencies on Python libraries including Django itself, and a database program (sqlite, MySQL, and PostgreSQL are all popular choices).  Orchestrating the setup of all of this creates a lot of friction, especially if you are new to the Python ecosystem, and ranges from medium difficulty to "Dear God why did I ever attempt this" difficulty on Windows.  Worst of all, when you eventually want to deploy your application so the outside world can use it, you have to juggle all of this stuff *again* plus more overhead (e.g. installing and configuring nginx) on your server.

Vagrant's value proposition is simple:  Get the repo of the project you want to work on, run `vagrant up` once in the top level directory, wait for the virtual machine to boot and get provisioned, and then you are ready to go.  Point your browser to `localhost:8000` (or wherever) and there is your app.   Vagrant works with virtualization technologies ([VirtualBox](https://www.virtualbox.org/), [VmWare](https://www.virtualbox.org/), and they recently announced [Docker](http://docker.io) support) and provisioners (anything from shell scripts to [Puppet](https://puppetlabs.com/) to [Chef](http://www.getchef.com/chef/)) behind the scenes and provides a nice clean interface for customization of things such as port forwarding from the guest to the host.  It really is a very flexible and powerful technology.

But it, and related technologies (like Docker), are so new, they still have a big problem.  There's no centralized way to find a quality image for what you may be searching for (e.g. Rails).  Someone out there has probably already done the legwork of creating that Vagrantfile and provisioning, right?  But at best we have Google and Github to try and hunt one down, and no assurance that it actually works.  For instance, I once tried to run a Vagrantfile that pretty much required Ansible to be installed on the host machine, and I was on Windows (so it was no good).  There are workarounds, but at that point you've already missed out on the awesome `vagrant up` workflow.

## The Idea

About a month ago I got frustrated with the fact that I had to set up all of the weird Ruby stuff on a new computer any time I wanted to blog (because my blog right now is based on [Octopress](http://octopress.org/)) so I set about creating a Vagrantfile and a provisioning script to take care of that.  That way, any time I wanted to blog on a new computer, I could just run `vagrant up` and have Octopress rarin' to go.

5 hours later, I was still struggling.  For a variety of reasons that I won't go into here, including that Windows interfered with several critical `rake` commands due to shared folder access.  I did eventually get it online, but it might have done me well to know that there was an existing version with these issues resolved floating around.  Indeed, some Googling just now reveals that [this is the case](http://blog.andrewallen.co.uk/2013/05/13/setting-up-vagrant-for-octopress/).  Or is it?  There's no way to know if things you find just by Googling work well, on what OSes, whether or not they're outdated, and so on.

Which brings me to my point.

I think there should be a community for Vagrantfiles (and their corresponding provisioning scripts), which I envision as being a sort of an awesome mashup of [Google](http://google.com), [Github](http://github.com), and [Reddit](http://reddit.com).  Basically, it would just be a CRUD app where people could submit and vote on Vagrant environments for particular stacks (want a [MEAN](http://mean.io/#!/) stack?  Here's the definitive one, etc.).  That way, if you wanted to start a new project with a particular stack, you could just `git clone` the project, optionally delete the `.git` directory to start fresh, run `vagrant up` and be done with it.  This is the sort of workflow we used to get going on a Laravel app when we [won Startup Weekend](/blog/2014/02/10/5-reasons-we-won-startup-weekend/) and it worked incredibly well.  

Additionally it would be pretty amazing if there were continuously integrated builds of the box/provisioning under OSX, Windows, and Linux hosts to reasonably assure you that no funny business was going to happen if you built the box with `vagrant up` locally.  For instance, making things work with a Windows host for me entailed making some pretty drastic changes to the Rakefile to appease SASS.  This would account for stuff like that.

The upvote/downvote and discussion mechanisms would enable people to isolate the builds which are the "best" for various reasons, including being actively maintained.

I feel like the [Docker index](https://index.docker.io) is sort of headed in the right direction here, but at the time of writing lacks a way to sort search results by relevant paramters e.g. stars.  The code for that is online and written in Python, which I am familiar with, so I may take a stab at implementing it.

## Fin

Maybe I'm just barking up the wrong tree here, but if there's interest in this as a tool I definitely want to start looking into building and maintaining such a site.  I think we would see so many cool apps come to fruition that otherwise might have languished in dependency hell.  Everyone should know the awesomeness of `vagrant up`.

Until next time, stay sassy Internet.  And [consider subscribing to my blog](https://nathanleclaire.com).
