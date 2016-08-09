---
layout: post
title: "cURL with HTTP2 Support - A Minimal Alpine-based Docker Image"
date: "2016-08-11"
comments: true
categories: [curl,linux,alpine,http2,docker]
---

# cURL the Night Away

![](/images/curldockeralpine.png)

One of my favorite open source projects is [cURL](https://curl.haxx.se/).
Though frequently taken for granted I really feel that it deserves a lot of
appreciation and respect.  Without `curl` available in our toolbelt those of
use who do heavy interaction with the network (quite a few of us) would really
be in a pickle.  `curl` is fast, minimal, and like most good tools, tends to
stay out of your way and "just work".

Due to its wide-ranging "Swiss army knife for data transfer" scope it is not
entirely unheard of to want a feature of `curl` (such as [UNIX socket
support](https://nathanleclaire/blog/2015/11/12/using-curl-and-the-unix-socket-to-talk-to-the-docker-api/))
that your system's provided packages either have not been configured to support
or are too old to include. Consequently you might find yourself wanting to
compile a version of `curl` for yourself which includes these features.  In
spite of the fact that compiling your own dependencies can be scary, especially
if you're not the type to pop open the proverbial hood and poke around, it is
an incredibly liberating experience to customize the software you are using
exactly to your own specifications.

It is also empowering to know that if needed you can compile your own software
and aren't limited to the packages that others hand to you. Suddenly, you may
become filled with a giddy feeling that you can install and configure any
software under the sun, exactly how you like it, without needing to accept the
limitations or differences in preference where others left off.  Since humans
frequently like nothing more than to feel that they have made their own mark on
a thing, this is one of the most addicting rushes of working with open source
software.

[Docker](https://docker.com), with its filesystem isolation properties, is a
perfect fit for this sort of tinkering.  You don't need to worry about messing
up your own local system with installing dependency libraries or a botched
`make install`-type command. It frees you to take the training wheels off a bit
and be willing to make mistakes.  This is a great thing since the only way to
learn is to sometimes botch things completely and botching them inside of a
container that you can simply throw away is much safer than messing with your
local system until you get it into some bespoke state.  Additionally, if you
script the steps with a `Dockerfile` there will be no messy attempts at
recalling the build later on -- it will all be documented and automatable via
`Dockerfile`.  Though it does not [100% guarantee build
reproducibility](https://nathanleclaire.com/blog/2014/09/29/the-dockerfile-is-not-the-source-of-truth-for-your-image/),
it is a dramatic improvement over a hastily scrawled `README`.

Let's build a `Dockerfile` to create a minimal, [Alpine
Linux](https://www.alpinelinux.org/)-based image with support for HTTP2.  An
emphasis will be made on keeping the generated image small and on customizing
`curl` 100% how we like it.

## Approach

We will:

1. Discuss "Why do we care about HTTP2"?
2. Present the `Dockerfile` in full to get a feel for the build
3. Discuss the choice of Alpine as a base image
4. Go over the `Dockerfile` step-by-step
5. Build and run the image

## Why HTTP2?

From [https://http2.github.io/](https://http2.github.io/):

> HTTP/2 is a replacement for how HTTP is expressed “on the wire.” It is not a
> ground-up rewrite of the protocol; HTTP methods, status codes and semantics
> are the same, and it should be possible to use the same APIs as HTTP/1.x
> (possibly with some small additions) to represent the protocol.

> The focus of the protocol is on performance; specifically, end-user perceived
> latency, network and server resource usage. One major goal is to allow the
> use of a single connection from browsers to a Web site.

Long story short, HTTP2 is meant to address some shortcomings of the original
HTTP/1.1 protocol, including [performance](https://www.cloudflare.com/http2/).
Playing with the linked demo, CloudFlare claims about a 4x-8x speedup from my
home computer.  A web that's 4x-8x faster?  Yes, please.

## Dockerfile

Here is the curl-with-HTTP2-support `Dockerfile`:

<pre>
FROM alpine:edge

# For nghttp2-dev, we need this respository.
RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/testing >>/etc/apk/repositories 

ENV CURL_VERSION 7.50.1

RUN apk add --update --no-cache openssl openssl-dev nghttp2-dev ca-certificates
RUN apk add --update --no-cache --virtual curldeps g++ make perl && \
    wget https://curl.haxx.se/download/curl-$CURL_VERSION.tar.bz2 && \
    tar xjvf curl-$CURL_VERSION.tar.bz2 && \
    rm curl-$CURL_VERSION.tar.bz2 && \
    cd curl-$CURL_VERSION && \
    ./configure \
        --with-nghttp2=/usr \
        --prefix=/usr \
        --with-ssl \
        --enable-ipv6 \
        --enable-unix-sockets \
        --without-libidn \
        --disable-static \
        --disable-ldap \
        --with-pic && \
    make && \
    make install && \
    cd / && \
    rm -r curl-$CURL_VERSION && \
    rm -r /var/cache/apk && \
    rm -r /usr/share/man && \
    apk del curldeps
CMD ["curl"]
</pre>

The general outline of the build is like so:

1. We install some packages, intended to stay around, for the libraries we need
   for SSL (HTTPS) and HTTP2 support
2. We install packages needed to compile cURL
3. We download and extract the cURL source (latest stable version at time of
   writing)
4. We configure, compile, and install `curl`
5. We clean up dependencies that we needed to perform the build, but don't want
   in the finished image
6. We set the default `CMD` to `curl`

## Why Alpine?

Alpine Linux is a minimal Linux distribution with an emphasis on security and
speed.  Package installs are fast using `apk`, the image contains only the bare
minimum to do basic UNIX-ey things by default, and it is tiny relative to other
Docker base images people use. Disk space, and especially network usage, really
does matter, so the lighter we can make our image, the better.

Comparison of uncompressed size of common base images (using `:latest` at time
of writing):

- `alpine` - 4.8 MB
- `ubuntu` - 124.8 MB
- `debian` - 125.1 MB
- `centos` - 196 MB

![](/images/image-size-chart.png)

<center>_Now imagine pulling these on the network over and over._</center>

Are you getting 25x the amount of value considering the congruent hit to disk
and bandwidth?  In some cases, maybe, but the Alpine packages keep getting
better and better every day and include killer features such as search by
filename (Example: Need to locate which `apk` package contains the binary file
`mke2fs`?  [No problem at
all.](https://pkgs.alpinelinux.org/contents?file=mke2fs&path=&name=&branch=&repo=&arch=)).
Unlike some other tools where I've found myself resentful to have spent a bunch
of time learning their quirks, I'm delighted with Alpine so far and it
continues to reward me.  Especially for little utility containers such as this
`curl` one, the reduced size is wonderful.

## Build Steps in Detail

Let's examine the `Dockerfile` more closely.

<pre>
FROM alpine:edge

# For nghttp2-dev, we need this respository.
RUN echo https://dl-cdn.alpinelinux.org/alpine/edge/testing >>/etc/apk/repositories 
</pre>

The `nghttp2` package (required for HTTP2 support in cURL) is only available in
the "testing" repository of the Alpine "edge" branch, so these lines set the
stage to make sure that package is available when we `apk install`.  I found
this all out by reading some explanations of using cURL with HTTP2 noting that
the `nghttp2` library was required (due to the complexity that HTTP2
introduces) and poking around at the [Alpine package
archives](https://pkgs.alpinelinux.org/package/edge/testing/x86_64/nghttp2-dev).

<pre>
ENV CURL_VERSION 7.50.1
</pre>

When cURL releases a new version and we want to update the image, we will only
need to change one place in this file, the environment variable.  `7.50.1` is
the latest stable cURL release at the time of writing.

<pre>
RUN apk add --update --no-cache openssl openssl-dev nghttp2-dev ca-certificates
</pre>

These are dependencies that we actually want to stick around in the final
image, default certficiates and libraries to use SSL with `curl` (needed for
HTTPS).  Note the `--no-cache`.  This ensures that `apk` does not use more disk
space than needed to "cache" the package location lookups it is doing and saves
us space in our final image.

The next `RUN` command is just one layer (so that we can install some
dependencies, use them, and clean them up without having them be persisted in
the final image) but there's a lot going on so let's take a look step-by-step
to see what it does.

<pre>
RUN apk add --update --no-cache --virtual curldeps g++ make perl && \
</pre>

All needed to successfully compile and install `curl`.  The use of `--virtual`
illustrates a useful `apk` property, "virtual" packages.  You can give a subset
of packages a label and then clean them all up with just one line later, `apk
del virtual-pkg-name`.

<pre>
    wget https://curl.haxx.se/download/curl-$CURL_VERSION.tar.bz2 && \
    tar xjvf curl-$CURL_VERSION.tar.bz2 && \
    rm curl-$CURL_VERSION.tar.bz2 && \
    cd curl-$CURL_VERSION && \
</pre>

Get the cURL source tarball, extract it, remove the downloaded artifact (we
don't need it after extracting it), and `cd` into the source directory.

<pre>
    ./configure \
        --with-nghttp2=/usr \
        --prefix=/usr \
        --with-ssl \
        --enable-ipv6 \
        --enable-unix-sockets \
        --without-libidn \
        --disable-static \
        --disable-ldap \
        --with-pic && \
    make && \
    make install && \
</pre>

The familiar `./configure; make; make install` rodeo with some cURL-specific
flavor. `--with-nghttp2=/usr` is the magic bit here for HTTP2 support. Since
our Alpine package installed `nghttp2-dev` to `/usr/lib`, `/usr` is the proper
argument to pass here. The build will look for `lib` and a package
configuration file inside of that directory.  You might see `/usr/local` or
other dirs in some other examples.

Most of the other arguments (except `--with-ssl`) are ripped off of the
[upstream's `APKBUILD` for `curl`
package](http://git.alpinelinux.org/cgit/aports/tree/main/curl/APKBUILD).
Since the Alpine package maintainers generally do a good job I decided to just
re-use their existing configuration.  If I was feeling really saucy, I'd go dig
in and decide in a granular way which ones I did and did not need, but I
probably would like most of them including UNIX socket support and IPv6, so I
left them as-is.

<pre>
    cd / && \
    rm -r curl-$CURL_VERSION && \
    rm -r /var/cache/apk && \
    rm -r /usr/share/man && \
    apk del curldeps
</pre>

This is all just cleanup. 

Leave the build directory (our binary has been installed now), remove the
source directory, run `apk del curldeps` to remove the virtual package we
started before, and remove `/var/cache/apk` (package cache, not sure why this
is still around with `--no-cache` to be honest) and `/usr/share/man` (manpage,
which is useless without `man` installed) directories.  Some of this,
especially the removal of the cache and man directories, is somewhat image size
fetishism, because they are really not more than 1MB or so in size.  Those were
the ones that I identified using `du | sort -n` as being probably unneeded in
the final image, and I do love trimming images down to be quite minimal.

Because all of these steps were done with one `RUN` command, they result in a
fairly small image layer in spite of the fact that at the beginning we
installed ~212MiB worth of dependencies to build the finished product. If that
was done in a separate layer, the removal would not truly "remove" the files in
the finished image but instead would merely "white out" the files.

And last but not least:

<pre>
CMD ["curl"]
</pre>

`docker run image` will invoke `curl` by default.  This could also be
`ENTRYPOINT` but I don't really mind `CMD` here to allow for easier over-riding
on the `docker run` CLI.

## Building and Running

To build, just drop the `Dockerfile` into an empty directory, and:

<pre>
$ docker build -t yourname/curl .
</pre>

Running it is fairly straightforward once built.  Let's check that everything
worked as intended by contacting `nghttp2.org`. `-s` for "silent", `--http2`
for HTTP2, and `-I` to return just the headers to verify that we are using the
correct protocol.

<pre>
$ docker run yourname/curl curl -s --http2 -I https://nghttp2.org
HTTP/2 200 
date: Sat, 06 Aug 2016 21:47:31 GMT
content-type: text/html
last-modified: Thu, 21 Jul 2016 14:06:56 GMT
etag: "5790d700-19e1"
accept-ranges: bytes
content-length: 6625
x-backend-header-rtt: 0.00166
strict-transport-security: max-age=31536000
server: nghttpx nghttp2/1.14.0-DEV
via: 2 nghttpx
x-frame-options: SAMEORIGIN
x-xss-protection: 1; mode=block
x-content-type-options: nosniff
</pre>

It works, good times.  And the final image clocks in around 16MB.  Not bad for
a bespoke `curl` build that needed hundreds of `MiB` in requirements to
compile.

# Conclusion

- Alpine Linux is great
- Building your own tools from scratch is scary but exciting
- Docker is extremely useful for tinkering with building tools from source
- You can haz teh cURL with HTTP2 support

Hope you found this useful.  Until next time, stay sassy Internet.

- Nathan
