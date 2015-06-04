---
layout: post
title: "Docker Machine 0.3.0 Sneak Preview: Transmogrify Existing Servers To Be Docker-ready and much, much, more"
date: "2015-06-02"
comments: true
categories: 
---

# SPECIAL SNEAK PREVIEW OF DOCKER MACHINE 0.3.0

{{%img src="/images/daftdocker.png" caption="Basically @ehazlett and I these days" %}}

# Welcome to the Machine.

It's release season and the incorrigible [Evan
Hazlett](https://github.com/ehazlett) and I, along with many others whose work
I am infinitely appreciative for and could not possibly do without, are firing
on all cylinders to try and get the best possible [Docker
Machine](https://github.com/docker/machine) that we can out the door for the
0.3.0 release.  There are [_so_ many new
features](https://github.com/ehazlett/machine/blob/ce4d16af5d89430a8d481d562e96544f91905360/CHANGES.md)
and so much goodness in this release that I couldn't possibly do them all
justice in a single blog post (although I may well try for the release post),
but since I am bursting at the seams with enthusiasm for it I can't help but
possibly "spill the beans" on one of the things we are getting ready to drop
and give you a little sneak preview.

We're introducing a new driver in this release called `generic`.  It seems like
a really subtle (albeit useful) feature at first, but I have a feeling it's
going to be really important to the future of the project, and in my opinion
really hearkens to all kinds of insanely awesome new things which are starting
to become viable -- particularly, integration with other projects that
previously seemed to overlap in functionality with Machine, or where the
boundaries weren't quite clear.  More on the specifics of that in a later post.

# Go doesn't have generics, but Machine does.

Yeah, sorry, couldn't resist that one.

Much like the `virtualbox`, `digitalocean`, `amazonec2`, etc. drivers for
Machine, which allow you to create machine instances with Docker installed and
configured the proper way on an ad-hoc basis and then manage them on those
providers, the `generic` driver does so for _ANY_ machine which you have SSH
access to.  You lose a little bit of flexibility in terms of, say, powering off
and on the instance through the provider's remote API (which the `generic`
driver cannot control), but you make up for it in terms of flexibility and
accessibility in terms of bridging Machine with tools it does not directly
account for, e.g. Ansible, or providers which Machine does not natively
support.

Here's the kicker: All of the options that you use with Machine to configure,
say, [Docker
Swarm](https://docs.docker.com/machine/#using-docker-machine-with-docker-swarm)
on the created hosts also apply for these hosts you "import" into your Machine
store using the `generic` driver.  So, bootstrapping and using a Docker Swarm
cluster is becoming easier than ever (you can just use existing machines to run
it if you want to), and so is interacting with the Docker daemon which is
running on those hosts directly.  Introspecting the state of your system and
running Docker daemons Secure communication from your client to the remote
daemons using TLS is, of course, also a huge plus, and is something else which
Machine sets up automatically for you.

Let's take a look at this in action.

## The Generic Driver in Action

Note:  If you want to follow along at home, you can grab the most recent
[release candidate](https://github.com/docker/machine/releases) from GitHub.
Cheers!

Let's say that I've created a server through the DigitalOcean admin interface,
and imported my public key into the instance (so I can SSH in without having to
type a password).  That's cool, but I want to use it with Docker and Docker
Machine, and I don't have any of that set up and configured right now.  On top
of that, I want to make it a master node for a Docker Swarm.  That sounds
pretty scary and/or tedious to set up by hand, but Machine with the `generic`
driver can automate the process for you quite nicely.

Firstly, we have to create a Swarm token if we don't have one already (this is
used for discovery by the master and its worker nodes):

<pre>
$ docker run swarm create
181a89a5589fbc7f3be78e09b585d21a
</pre>

Suppose my instance is at the IP address `107.170.195.209`.  Since I have SSH
and `sudo` access on the box (which Machine needs in order to work), I can
bootstrap all of the things listed above with just one command:

<pre>
$ docker-machine create \
    -d generic \
    --swarm \
    --swarm-master \
    --swarm-discovery token://181a89a5589fbc7f3be78e09b585d21a \
    --generic-ip-address 107.170.195.209 \
    gendo
</pre>

This will create a new Docker Machine host, `gendo`, which has Docker (and
Swarm!) configured and ready to rip.  We might have had to specify the path to
the SSH key file or name of the user to work as, but in this case the defaults
of `$HOME/.ssh/id_rsa` and `root` for those values served fine.

You can see it in the output of `docker-machine ls`:

<pre>
$ docker-machine ls
NAME    ACTIVE   DRIVER       STATE     URL                          SWARM
dev     *        virtualbox   Running   tcp://192.168.99.124:2376    
gendo            generic      Running   tcp://107.170.195.209:2376   
</pre>

Best of all, it is configured as a Swarm master, so you can create other nodes
which join the cluster using the same discovery token if you wish.  All of this
is set up behind the scenes for you based on your desired configuration, so you
don't have to go mucking about with TLS certificates and the like just to play
with Swarm.  It is automated for you.

You can use the swarm master with: `eval $(docker-machine env --swarm gendo)`.

<pre>
$ # To use plain old Docker...

$ eval $(docker-machine env gendo)

$ docker ps
CONTAINER ID        IMAGE               COMMAND                CREATED             STATUS              PORTS                              NAMES
0a4bddd2b2eb        swarm:latest        "/swarm join --addr    52 seconds ago      Up 52 seconds       2375/tcp                           swarm-agent          
a4ea6691c9b4        swarm:latest        "/swarm manage --tls   53 seconds ago      Up 53 seconds       2375/tcp, 0.0.0.0:3376->3376/tcp   swarm-agent-master   

$ # Nice, the swarm containers are bootstrapped automatically.

$ eval $(docker-machine env --swarm gendo) # Now let's talk to the swarm master

$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES

$ # The Swarm containers are gone!  Don't worry, it's just the master only shows them with "docker ps -a".

$ docker info
Containers: 2
Strategy: spread
Filters: affinity, health, constraint, port, dependency
Nodes: 1
 gendo: 107.170.195.209:2376
  └ Containers: 2
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 514.5 MiB

$ # And now you're cooking with Swarm.
</pre>

I think this is the basis of a really powerful and flexible method which
eventually will be used to bridge the gap between Docker Machine and other
tools such as Terraform and Ansible, among other use cases.

# Fin.

I hope that this little teaser preview, makes you want to go try it out ;D

Until next time, stay sassy Internet.

- Nathan
