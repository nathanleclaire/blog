---
layout: post
title: "The Dockerfile is not the source of truth for your image"
date: "2014-09-29"
comments: true
categories: [docker,go,dockerfile]
---

As Docker grows in popularity we at Docker Inc. are very pleased and one of the things we are trying to encourage the most is the clearing up of misconceptions in the community. Things move rapidly in the open source world, so we do our best to educate those who are willing to listen. On that note, there's a few thoughts about Dockerfiles that I want to share.

The Dockerfile is a wonderful creation - it allows you to automate the otherwise tedious process of creating Docker images. A bit of review for those of you who might be scratching your heads right now:

- Docker provides process, network, etc. isolation and a "chroot on steroids" from a given filesystem state.
- You have to get that initial filesystem state somehow.
- You could either roll your own (any Docker on ARM people out there?) from scratch, or use the images provided by a registry. Docker Hub is one such registry.
- You can also create images interactively using a base image and `docker commit`.

`docker commit` is the operation which creates a new image layer in Docker's layered union filesystem (AUFS by default on Debian-based systems). You can actually see the changes which will be committed with `docker diff`:

<pre>
$ docker run -it ubuntu bash
root@b3a195b117aa:/# mkdir /data
root@b3a195b117aa:/# cd /data
root@b3a195b117aa:/data# touch a.java b.java
root@b3a195b117aa:/data# exit
exit
$ docker diff $(docker ps -lq)
A /data
A /data/a.java
A /data/b.java
C /root
A /root/.bash_history
</pre>

Similar to what you may be familiar with through source control.

docker commit allows you to actually commit the container in question to a totally new image, therefore providing a way of layering that's pretty nifty. It ties in nicely with Docker's transport mechanisms, since on push and pull you only have to move around the things that have changed. You can even tag it with a new name as well.

<pre>
$ # get the last run container ID
$ docker ps -lq
b3a195b117aa
$ docker commit b3a195b117aa username/my_awesome_new_image
</pre>

This basic mechanic opens up the doors for some pretty fun stuff, since you will have an assurance that when you run that Docker image (no matter where you are running it) it will run the exact same. No more bombed out npm package installations, missing headers, random dependencies breaking and so on.

Just one problem: the process of custom crafting images by hand is very tedious and slow. Additionally, if I make a mistake somewhere in the construction of the image, I would have to start over.

This is one of several reasons why the Dockerfile was created. It is a way of automating the aforementioned process of constructing images manually layered with docker commit. Now you can zip through the process by defining a file such as this:

<pre>
FROM ubuntu:14.04
MAINTAINER Nathan LeClaire 

RUN apt-get update && \
    apt-get install -y curl wget python
ADD . /code
WORKDIR /code
CMD ["python", "/code/app.py"]
</pre>

Additionally it allows you to define some metadata about the image, such as a `MAINTAINER` you see above, and `CMD`, which is actually a runtime configuration property.

## So?

So, the Dockerfile generally works beautifully for the class of problem for which it was designed. But it bears mentioning that:

1. ~~Layer IDs are currently not content-addressable, therefore:~~ __EDIT:__ As of Docker 1.10 this is not true any more.  However, points about reproducibility still stand.
2. Building two images from the same Dockerfile in different places is not a guarantee that they will consist of the same layers, both by ID and by content. Additionally:
3. Frequently peoples' Dockerfiles use packages from upstream (apt-get, yum, go get, etc.) which could possibly break on any build without cache.

Therefore the point of this article: The Dockerfile is not the source of truth for your image.

The Dockerfile is a tool for creating images, but it is not the only weapon in your arsenal. With the popularity of Automated Builds (and I'm quite pleased with that feature, though I'm not going to stop pestering [ldlework](http://github.com/dustinlacewell) for a version which somehow - magically - uses caching), it is essential for users to recognize that the Dockerfile is not the end-all be-all of image creation and verification. Solutions for this need to continue to thrive and evolve in the community.

This is why some people were so grumbly about Automated Builds originally being "Trusted Builds". It's not a very compelling label when a security breach upstream might actually compromise the contents of my image too. Rootkits for everyone!

It is very useful to be able to link directly to Github or Bitbucket to see the source which was used to build images. But it is the responsibility of the users to actually assess each step of the Dockerfile, track down base images, etc. It is not the Dockerfile's job to provide a perfectly reproducible experience across all environments. You have to construct your images in a way that ensures perfect repeatability. The Dockerfile does not guarantee it for you.

## What's the takeaway?

1. Put effort into understanding the mechanics of how images work to avoid being bitten by non-deterministic `docker build`s.
2. The Dockerfile cache should be used when possible.
3. Participate in community discussions about how to improve the way images are built and shared. Most likely these issues will be ironed out over time.

## fin.

In the future these issues will be corroded but for now, as always, the best approach to docker builds is user vigilance.

I am excited to write this article as I hope it will help clear up magical thinking around Dockerfiles and promote patterns that encourage consistency across environments and truly obliterate the "It worked on my machine" problem.

Until next time, stay sassy Internet.

- Nathan
