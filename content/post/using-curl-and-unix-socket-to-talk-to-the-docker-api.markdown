---
layout: post
title: "Using curl and the UNIX socket to talk to the Docker API"
date: "2015-11-12"
comments: true
categories: [docker,curl,socket,unix]
---

{{%img src="/images/curl.png" %}}

Though it is usually hidden behind the docker client binary or other tools,
direct communication with the [docker
API](https://docs.docker.com/engine/reference/api/docker_remote_api/)
(REST-ish) is sometimes needed in order to debug, understand proper usage, or
simply to learn more about the internals of how Docker works.  By default the
Docker daemon listens on a UNIX socket located at `/var/run/docker.sock` for
incoming HTTP requests, but also can be exposed on a TCP port.  In most cases,
however, the TCP port exposing the Docker API is secured with TLS (otherwise
anyone with access to the API could quite trivially root the box where Docker
is running) and accessing TLS-secured endpoints using `curl` can be a real
pain.

Communication with UNIX sockets was added in [cURL version
7.40](http://superuser.com/questions/834307/can-curl-send-requests-to-sockets),
but many Linux distributions come with and/or have an older version in their
package manager.  If our host distribution's package version is out of date, we
might consider using a container for the proper curl version. However, many of
the library images have the same issue.  Out of the box in a Debian Jessie
container at the time of writing, for instance, we get a slightly older
version:

<pre>
$ docker run -ti debian:jessie
root@1cf1c9ed1bd7:/# apt-get update && apt-get install -y curl
...
root@1cf1c9ed1bd7:/# curl --version
curl 7.38.0 (x86_64-pc-linux-gnu) libcurl/7.38.0 OpenSSL/1.0.1k zlib/1.2.8 libidn/1.29 libssh2/1.4.3 librtmp/2.3
Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtmp rtsp scp sftp smtp smtps telnet tftp 
Features: AsynchDNS IDN IPv6 Largefile GSS-API SPNEGO NTLM NTLM_WB SSL libz TLS-SRP 
</pre>

We could build an image to compile `curl` from source and use that, but the
resulting image would likely be several hundred megabytes in size.  That is
very expensive for a simple image just to run some curl commands on a socket.

## Building a small image to run the right curl

Luckily, the very exciting [Alpine Linux](http://www.alpinelinux.org/) project
has both a very small disk footprint, and a version of `curl` which is
sufficiently up-to-date in their package manager.  Consequently a small
Dockerfile such as this:

<pre>
FROM alpine
RUN apk add --update curl
</pre>

Will produce a resulting image which is only about 10MB in size, but contains
the curl command we need.  I have such an image hosted at `nathanleclaire/curl`
(or you could build your own with the Dockerfile above), so to run curl on the
UNIX socket simply mount the socket in to a container based on this image:

<pre>
$ docker run -ti -v /var/run/docker.sock:/var/run/docker.sock nathanleclaire/curl sh
/ # curl --unix-socket /var/run/docker.sock http:/containers/json
[{"Id":"144ada3b2034e807d8064cbd961c180859d58e5fe878f428c55152cd2d40dc31","Names":["/insane_blackwell"],"Image":"nathanleclaire/curl","ImageID":"674e856e325a7866edd6f1a5e281595d7c2ea3d1a660f690033535e90c3414ee","Command":"sh","Created":1447359955,"Ports":[],"Labels":{},"Status":"Up About a minute","HostConfig":{"NetworkMode":"default"}}]
</pre>

You could make other images which inherit this small base image and add more
fancy stuff like `jq`, but for simple debugging purposes a small Alpine-based
image works quite well.

## fin

I hope this helps in making communicating with the Docker UNIX socket a bit
easier.

Until next time, stay sassy Internet.

- Nathan
