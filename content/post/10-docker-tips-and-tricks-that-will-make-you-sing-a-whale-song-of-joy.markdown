---
layout: post
title: "10 Docker Tips and Tricks That Will Make You Sing A Whale Song of Joy"
date: "2014-07-12"
comments: true
categories: [docker,sysadmin,ops]
---

{{%img src="/images/dockertips/humpback.jpg" caption="" %}}

# docker run -it nathanleclaire/article

As mentioned in a previous post I just started a shiny new job at Docker Inc. and I've been accumulating all sorts of good Docker tips and tricks.  I think there is probably demand for them in the community, where just the sheer amount of information about Docker to take in is very overwhelming.  Once you've mastered the basics, the creative possibilites are endless, and already my mind has been blown by what some of the folks I work with have come up with.  Just like I mentioned in [this post](/blog/2014/03/22/what-is-this-docker-thing-that-everyone-is-so-hyped-about/), the Cambrian explosion of creativity it's provoking is extremely exciting.

So I'm going to share some of my favorite tips and tricks with you guys.  Ready?

The 10 tips and tricks are:

1. Run it on a VPS for extra speed
2. Bind mount the docker socket on docker run
3. Use containers as highly disposable dev environments
4. bash is your friend
5. Insta-nyan
6. Edit `/etc/hosts/` with the `boot2docker` IP address on OSX
7. `docker inspect -f` voodoo
8. Super easy terminals in-browser with wetty
9. nsenter
10. &#35;docker

Alright, let's do this!

## Run it on a VPS for extra speed

{{%img src="/images/dockertips/vps.jpeg" caption="" %}}

This one's pretty straightforward.  If you run Docker on [Digital Ocean](http://digitalocean.com) or [Linode](http://linode.com) you can get way better bandwidth on pulls and pushes if, like me, your home internet's bandwidth is pretty lacking.  I get around 50mbps download with Comcast, on my Linode my speed tests run an order of magnitude faster than that.

So if you have the need for speed, consider investing in a VPS for your own personal Docker playground.

## Bind mount the docker socket on docker run

What if you want to do Docker-ey things inside of a container but you don't want to go full Docker in Docker (dind) and run in `--privileged` mode?  Well, you can use a base image that has the Docker client installed and bind-mount your Docker socket with `-v`.

```sh
docker run -it -v /var/run/docker.sock:/var/run/docker.sock nathanleclaire/devbox
```

Now you can send docker commands to the same instance of the docker daemon you are using on the host - inside your container!

This is really fun because it gives you all the advantages of being able to mess around with Docker containers on the host, with the flexibility and ephemerality of containers.  Which leads into my next tip....

## Use containers as highly disposable dev environments

{{%img src="/images/dockertips/devenv.gif" caption="" %}}

How many times have you needed to quickly isolate an issue to see if it was related to certain factors in particular, and nothing else?  Or just wanted to pop onto a new branch, make some changes and experiment a little bit with what you have running/installed in your environment, without accidentally screwing something up big time?

Docker allows you to do this in a a portable way.

Simply create a Dockerfile that defines your ideal development environment on the CLI (including ack, autojump, Go, etc. if you like those - whatever you need) and kick up a new instance of that image whenever you want to pop into a totally new box and try some stuff out.  For instance, here's [Solomon's](https://github.com/shykes).

```
FROM ubuntu:14.04

RUN apt-get update -y
RUN apt-get install -y mercurial
RUN apt-get install -y git
RUN apt-get install -y python
RUN apt-get install -y curl
RUN apt-get install -y vim
RUN apt-get install -y strace
RUN apt-get install -y diffstat
RUN apt-get install -y pkg-config
RUN apt-get install -y cmake
RUN apt-get install -y build-essential
RUN apt-get install -y tcpdump
RUN apt-get install -y screen

# Install go
RUN curl https://go.googlecode.com/files/go1.2.1.linux-amd64.tar.gz | tar -C /usr/local -zx
ENV GOROOT /usr/local/go
ENV PATH /usr/local/go/bin:$PATH

# Setup home environment
RUN useradd dev
RUN mkdir /home/dev && chown -R dev: /home/dev
RUN mkdir -p /home/dev/go /home/dev/bin /home/dev/lib /home/dev/include
ENV PATH /home/dev/bin:$PATH
ENV PKG_CONFIG_PATH /home/dev/lib/pkgconfig
ENV LD_LIBRARY_PATH /home/dev/lib
ENV GOPATH /home/dev/go:$GOPATH

RUN go get github.com/dotcloud/gordon/pulls

# Create a shared data volume
# We need to create an empty file, otherwise the volume will
# belong to root.
# This is probably a Docker bug.
RUN mkdir /var/shared/
RUN touch /var/shared/placeholder
RUN chown -R dev:dev /var/shared
VOLUME /var/shared

WORKDIR /home/dev
ENV HOME /home/dev
ADD vimrc /home/dev/.vimrc
ADD vim /home/dev/.vim
ADD bash_profile /home/dev/.bash_profile
ADD gitconfig /home/dev/.gitconfig

# Link in shared parts of the home directory
RUN ln -s /var/shared/.ssh
RUN ln -s /var/shared/.bash_history
RUN ln -s /var/shared/.maintainercfg

RUN chown -R dev: /home/dev
USER dev
```

Especially deadly if you use vim/emacs as your editor `;)`.  You can use `/bin/bash` as your `CMD` and `docker run -it my/devbox` right into a shell.

You can also bind-mount the Docker client binary and socket (as mentioned above) inside the container when you run it to have access to the host's Docker daemon for container antics!

Likewise you can bootstrap a development environment on a new computer easily this way.  Just install docker and download your dev box image!

## bash is your friend

Or "the shell is your friend".  Sorry `zsh` and `fish` users.

Just like many of you have aliases for `git` to save keystrokes, you'll likely want to create little shortcuts for youself if you start to use Docker heavily.  Just add these to your `~/.bashrc` or equivalent and off you go.

There are some obvious ones:

```sh
alias drm="docker rm"
alias dps="docker ps"
```

Basically I will add one of these whenever I find myself typing the same command over and over.  Like you do :D

You can also mix and match in all kinds of fun ways.  You can do

```sh
$ drm -f $(docker ps -aq)
```

To remove all containers, for instance (including those which are running).  Or:

```
function da () {
    docker start $1 && docker attach $1
}
```

to start a stopped conatiner and attach to it.


I created a fun one to enable my rapid-bash-container-prompt habit mentioned in the previous tip:

```
function newbox () {
    docker run --name $1 --volumes-from=volume_container -it -v /var/run/docker.sock:/var/run/docker.sock -e BOX_NAME=$1 nathanleclaire/devbox
}
```

## Insta-nyan

{{%img src="/images/dockertips/nyan.png" caption="Let's face it, who doesn't love this? " %}}

Pretty simple.  You want a nyan-cat in your terminal, you have docker, and you need only one command to activate the goodness.

```
docker run -it supertest2014/nyan
```

## Edit `/etc/hosts/` with the `boot2docker` IP address on OSX

{{%img src="/images/dockertips/hacking.png" caption="This is what hacking looks like. " %}}

The newest (read: BEST) versions of [boot2docker](https://github.com/boot2docker/boot2docker) include a host-only network where you can access ports exposed by containers using the boot2docker virtual machine's IP address. The `boot2docker ip` command makes access to this value easy.  However, usually it is simply `192.168.59.103`.  I find this specific address a little hard to remember and cumbersome to type, so I add an entry to my `/etc/hosts` file for easy access of `boot2docker:port` when I'm running applications that expose ports with Docker.  It's handy, give it a shot!

**Note**: Do remember that it is possible for the boot2docker VM's IP address to change, so make sure to check that if you are encountering network issues using this shortcut.  If you are not doing something that would mess with your network configuration (setting up and tearing down multiple virtual machines including boot2docker's, etc.), though, you will likely not encounter this issues.

While you're at it you should probably tweet [@SvenDowideit](http://twitter.com/SvenDowideit) and thank him for his work on boot2docker, since he is an absolute champ for delivering, maintaining, and documenting it.  ;)

## `docker inspect -f` voodoo

You can do all sorts of awesome flexible things with the `docker inspect` command's `-f` (or `--format`) flag if you're willing to learn a little bit about [Go templates](http://golang.org/pkg/text/template/).

Normally `docker inspect $ID` outputs a big JSON dump, and you access individual properties with templating like:

```
docker inspect -f '{{ .NetworkSettings.IPAddress }}' $ID
```

The argument to `-f` is a Go template.  If you try something like:

```
$ docker inspect -f '{{ .NetworkSettings }}' $ID
map[Bridge:docker0 Gateway:172.17.42.1 IPAddress:172.17.0.4 IPPrefixLen:16 PortMapping:<nil> Ports:map[5000/tcp:[map[HostIp:0.0.0.0 HostPort:5000]]]]
```

You will not get JSON since Go will actually just dump the data type that Docker is marshalling into JSON for the output you see without `-f`.  But you can do:

```
$ docker inspect -f '{{ json .NetworkSettings }}' $ID
{"Bridge":"docker0","Gateway":"172.17.42.1","IPAddress":"172.17.0.4","IPPrefixLen":16,"PortMapping":null,"Ports":{"5000/tcp":[{"HostIp":"0.0.0.0","HostPort":"5000"}]}}
```

To get JSON!  And to prettify it, you can pipe it into a Python builtin:

```
$ docker inspect -f '{{ json .NetworkSettings }}' $ID | python -mjson.tool
{
    "Bridge": "docker0",
    "Gateway": "172.17.42.1",
    "IPAddress": "172.17.0.4",
    "IPPrefixLen": 16,
    "PortMapping": null,
    "Ports": {
        "5000/tcp": [
            {
                "HostIp": "0.0.0.0",
                "HostPort": "5000"
            }
        ]
    }
}
```

You can also do other fun tricks like access object properties which have non-alphanumeric keys.  Helps to know some Go :P

```
docker inspect -f '{{ index .Volumes "/host/path" }}' $ID
```

This is a very powerful tool for quickly extracting information about your running containers, and is extremely helpful for troubleshooting because it provides a ton of detail.

## Super easy terminals in-browser with wetty

I really foresee people making extremely FUN web applications with this kind of functionality.  You can spin up a container which is running an instance of [wetty](https://github.com/krishnasrinivas/wetty) (a JavaScript-powered in-browser terminal emulator).

Try it for yourself with:

```
docker run -p 3000:3000 -d nathanleclaire/wetty
```

{{%img src="/images/dockertips/wetty.png" caption="" %}}

Wetty only works in Chrome unfortunately, but there are other JavaScript terminal emulators begging to be Dockerized and if you are using it for a presentation or something (imagine embedding interactive CLI snapshots in your Reveal.js slideshow - nice) you control the browser anyway.  Now you can embed isolated terminal applications in web applications wherever you want, and you control the environment in which they execute with an excruciating amount of detail.  No pollution from host to container, and vice versa.

The creative possibilites of this are just mind-boggling to me.  I REALLY want to see someone make a version of [TypeRacer](http://typeracer.com) where you compete with other contestants in real time to type code into vim or emacs as quickly as possible.  That would be pure awesome.  Or a real-time coding challenge where your code competes with other code in an arena for dominance ala [Core Wars](http://www.corewars.org/).

## nsenter

[Jerome](http://twitter.com/jpetazzo) wrote an opinionated article a few weeks ago that shook things up a bit.  In it, he argues that you should not need to run `sshd` (daemon for getting a remote terminal prompt) in your containers and, in fact, if you are doing so you are violating the Docker philosophy (one concern per container).  It's a good read, and he mentions `nsenter` as a fun trick to get a prompt inside of containers which have already been initialized with a process.

See [here](http://jpetazzo.github.io/2014/06/23/docker-ssh-considered-evil/) or [here](http://www.sebastien-han.fr/blog/2014/01/27/access-a-container-without-ssh/) to learn how to do it.

## #docker

I'm not talking about the hashtag!!  I'm talking about the channel on Freenode on IRC.  It's hands-down the best place to meet with fellow Dockers online, ask questions (all levels welcome!), and seek truly excellent expertise.  At any given time there are about 1000 people or more sitting in, and it's a great community as well as resource.  Seriously, if you've never tried it before, go check it out.  I know IRC can be scary if you're not accustomed to using it, but the effort of setting it up and learning to use it a bit will pay huge dividends for you in terms of knowledge gleaned.  I guarantee it.  So if you haven't come to hang out with us on IRC yet, do it!

To join:

1. Download an IRC Client such as [LimeChat](http://limechat.net/mac/)
2. Connect to the `irc.freenode.net` network
3. Join the `#docker` channel

Welcome!

# Conclude

That's all for now folks, I hope you've learned a bit and you have all sorts of great ideas burning in your head about Docker!!  Enjoy it, join the conversation around it, and above all **BE CREATIVE**.

Until next time, stay sassy Internet.  And consider [signing up for my mailing list](https://nathanleclaire.com).

- Nathan
