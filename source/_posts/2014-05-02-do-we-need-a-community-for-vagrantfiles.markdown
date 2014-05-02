---
layout: post
title: "Do We Need a Community for Vagrantfiles?"
date: 2014-05-02 03:50
comments: true
categories: [vagrant]
---

# vagrant up

{%img /images/swaa/vagrant.png %}

For those of you who are unfamiliar, [Vagrant](http://www.vagrantup.com/) is "development environments made easy".

> Create and configure lightweight, reproducible, and portable development environments.

Vagrant is a command line tool that aids in the creation and provisioning of development environments.  Why is it important?  Let's say that you want to work on a Django application.  In order to get started with even basic work on the application you need Python installed, probably pip and virtualenv, the dependencies on Python libraries including Django itself, and a database program (sqlite, MySQL, and PostgreSQL are all popular choices).  Orchestrating the setup of all of this creates a lot of friction, especially if you are new to the Python ecosystem, and ranges from medium difficulty to "Dear God why did I ever attempt this" difficulty on Windows.  Worst of all, when you eventually want to deploy your application so the outside world can use it, you have to juggle all of this stuff *again* plus more overhead (e.g. installing and configuring nginx) on your server.

Vagrant's value proposition is simple:  Get the repo of the project you want to work on, run `vagrant up` once in the top level directory, wait for the virtual machine to boot and get provisioned, and then you are ready to go.  Point your browser to `localhost:8000` (or wherever) and there is your app.   Vagrant works with virtualization technologies ([VirtualBox](), [VmWare](), and they recently announced [Docker]() support) and provisioners (anything from shell scripts to [Puppet]() to [Chef]()) behind the scenes and provides a nice clean interface for customization of things such as port forwarding from the guest to the host.  It really is a very flexible and powerful technology.
