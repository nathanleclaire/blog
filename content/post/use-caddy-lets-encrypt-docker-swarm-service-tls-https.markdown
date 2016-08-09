---
layout: post
title: "Use Caddy and Let's Encrypt With Docker Swarm Service for TLS/HTTPS"
date: "2016-08-03"
comments: true
draft: true
categories: ["caddy", "docker", "swarm", "tls"]
---

### Killer Bees

At this point some folks have tried out the `docker service` and `docker swarm`
Docker commands, introduced in 1.12, and found that they are quite nice.  I
particularly enjoy the built-in features around networking and load balancing.

Let's take a look at this.  We'll:

1. Build a `docker network` overlay for (encrypted!) service-to-service
   communication
2. Put a [Caddy](https://caddyserver.com) service in place for inbound L7 load
   balancing
3. Notice that Caddy can generate signed certificates automatically using
   [Let's Encrypt](https://letsencrypt.org).  "Free" HTTPS to keep your users
   safer!
4. Observe that a web app can be effectively load balanced ("scaled") behind
   this

## Create Swarm and Network

First [let's create a Docker Swarm
cluster](https://docs.docker.com/engine/reference/commandline/swarm_init/).

From one node:

<pre>
$ docker swarm init
To add a worker to this swarm, run the following command:
    docker swarm join \
    --token SWMTKN-1-BIGLONGSTRING \
    ip:2377

To add a manager to this swarm, run the following command:
    docker swarm join \
    --token SWMTKN-1-BIGLONGSTRING \
    ip:2377
</pre>

__NOTE:__ _If the computer you run the `init` on has "indecisive" options for
advertising its IP address, e.g.  multiple `eth*` displays in `ifconfig`
command output, you may have to configure deliberately `--advertise-addr` flag
yourself._

_(optional)_ Run the `docker swarm join` commands suggested on other nodes to
connect.

Then create an overlay network for our future services. `--opt encrypted` will
encrypt communication between the services if provided. (Side note: I am not
100% sure if this works only from node-to-node or if it works on the same host
as well).

<pre>
$ docker network create -d overlay --opt encrypted caddypal
a06g007et936s3m691k74121q

$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
2073082916aa        bridge              bridge              local               
a06g007et936        caddypal            overlay             swarm               
eb990a399965        docker_gwbridge     bridge              local               
ff9b67728e3d        host                host                local               
6tn0mhbopirf        ingress             overlay             swarm               
656cd8ae85f2        none                null                local               
</pre>

## Build & Run Caddy Service

[Caddy](https://caddyserver.com) is a friendly load balancer with simple
configuration, [HTTP/2 by default](https://http2.github.io/), and offering
[automatically managed SSL via
LetsEncrypt](https://caddyserver.com/docs/automatic-https).  We will use it to
bridge the gap between higher-level inbound requests with protocols such as
HTTP, and Docker Swarm mode's built-in L4 IPVS-based service load balancing
which is extremely performant but much lower level.

For Caddy we will use a Dockerfile like the following.  It provides:

1. Minimal base & tools via [Alpine Linux](https://www.alpinelinux.org/)
2. A layer which grabs the Caddy binary archive from the internet, extracts it,
   installs the Caddy binary and cleans up the install cruft
3. The addition of a non-privileged user to execute the process
4. A `Caddyfile` for configuration and whatever static files we want (we'll
   edit this later)
6. A few metadata parameters, such as exposed HTTP/HTTPS ports

```
FROM alpine
MAINTAINER Nathan LeClaire <nathan.leclaire@gmail.com>

ENV VERSION v0.9.0

# Get version including minification and rate limiting functionality.
RUN apk add --no-cache openssl && \
    wget "https://caddyserver.com/download/build?os=linux&arch=amd64&features=minify%2Cratelimit" -O /caddy.tar.gz && \
    gunzip caddy.tar.gz && \
    mkdir /caddy && \
    tar xvf caddy.tar -C /caddy  && \
    mv /caddy/caddy /usr/local/bin/caddy && \
    rm -r caddy*
RUN adduser -D caddy
USER caddy
WORKDIR /home/caddy
VOLUME ["/home/caddy/.caddy"]
EXPOSE 80
EXPOSE 443
ENTRYPOINT ["caddy"]
CMD ["-log", "stdout"]
COPY Caddyfile /home/caddy/Caddyfile
COPY index.html /home/caddy/index.html
```

Go ahead, give it a go, it's fun.  It builds nice and fast if you have a decent
network.

<pre>
$ docker build -t yourname/caddy .
Sending build context to Docker daemon 3.072 kB
Step 1 : FROM alpine
 ---> 4e38e38c8ce0
Step 2 : MAINTAINER Nathan LeClaire <nathan.leclaire@gmail.com>
 ---> Running in 6a21849f2aaa
 ---> 3bcd51f1228f
Removing intermediate container 6a21849f2aaa
Step 3 : RUN apk add --no-cache openssl &&     wget https://github.com/mholt/caddy/releases/download/v0.9.0/caddy_linux_amd64.tar.gz -O /caddy.tar.gz &&     gunzip caddy.tar.gz &&     mkdir /caddy &&     tar xvf caddy.tar -C /caddy  &&     mv /caddy/caddy_linux_amd64 /usr/local/bin/caddy &&     rm -r caddy*
 ---> Running in b602d4bf5a7c
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/main/x86_64/APKINDEX.tar.gz
efetch http://dl-cdn.alpinelinux.org/alpine/v3.4/community/x86_64/APKINDEX.tar.gz
w(1/1) Installing openssl (1.0.2h-r1)
Executing busybox-1.24.2-r9.trigger
OK: 5 MiB in 12 packages
Connecting to github.com (192.30.253.112:443)
Connecting to github-cloud.s3.amazonaws.com (52.216.224.72:443)
caddy.tar.gz         100% |*******************************|  4939k  0:00:00 ETA
init/
init/README.md
init/freebsd/
init/freebsd/caddy
init/linux-systemd/
init/linux-systemd/README.md
init/linux-systemd/caddy.service
init/linux-upstart/
init/linux-upstart/README.md
init/linux-upstart/caddy.conf
CHANGES.txt
LICENSES.txt
README.txt
caddy_linux_amd64
 ---> 8f8f6c7c7a65
Removing intermediate container b602d4bf5a7c
Step 4 : RUN adduser -D caddy
 ---> Running in e2686582977b
 ---> e421db1ad8d9
Removing intermediate container e2686582977b
Step 5 : USER caddy
 ---> Running in 1fe3b9aefcfb
 ---> a6b1451837f8
Removing intermediate container 1fe3b9aefcfb
Step 6 : VOLUME /home/caddy/.caddy
 ---> Running in 116d39c754ef
 ---> 510c710b9fa0
Removing intermediate container 116d39c754ef
Step 7 : EXPOSE 80
 ---> Running in 6a6063be7559
 ---> ac19a8afee6e
Removing intermediate container 6a6063be7559
Step 8 : EXPOSE 443
 ---> Running in 347a33705338
 ---> 787a105fd35a
Removing intermediate container 347a33705338
Step 9 : ENTRYPOINT caddy
 ---> Running in f00594b5f047
 ---> 4adf738cfe90
Removing intermediate container f00594b5f047
Successfully built 4adf738cfe90

$ docker push yourname/caddy
...
</pre>

Cool, now we can easily invoke `caddy` in container.

<pre>
$ docker run -ti yourname/caddy --help
Usage of caddy:
  -agree
        Agree to the CA's Subscriber Agreement
  -ca string
        URL to certificate authority's ACME server directory (default "https://acme-v01.api.letsencrypt.org/directory")
  -conf string
        Caddyfile to load (default "Caddyfile")
  -cpu string
        CPU cap (default "100%")
  -email string
        Default ACME CA account email address
  -grace duration
        Maximum duration of graceful shutdown (default 5s)
  -host string
        Default host
  -http2
        Use HTTP/2 (default true)
  -log string
        Process log file
  -pidfile string
        Path to write pid file
  -plugins
        List installed plugins
  -port string
        Default port (default "2015")
  -quic
        Use experimental QUIC
  -quiet
        Quiet mode (no initialization output)
  -revoke string
        Hostname for which to revoke the certificate
  -root string
        Root path of default site (default ".")
  -type string
        Type of server to run (default "http")
  -version
        Show version
</pre>

Nice.  We're about to get hella HTTP2, HTTPS, and more.

We could start an instance of Caddy server serving an index page easily.  Since
the `WORKDIR` is `/home/caddy` in the image, let's just drop an `index.html`
file there and invoke `caddy` with a small configuration.  For now we'll just
set the Caddy listen host to `0.0.0.0:2015` (all interfaces on port 2015) and
then when we deploy our webapp with managed TLS later, we'll change it.

We'll make a simple `Caddyfile` to serve this content.

<pre>
localhost, 127.0.0.1 {
    log stdout
    root /home/caddy
}
</pre>

__NOTE__: _I am going to use IPv4 addressing deliberately in these examples due to
a [known issue which is being resolved with the ingress
network](https://github.com/docker/docker/issues/25445#issuecomment-237906313).
Depending on your setup (this affects native Linux, but not Docker for OSX --
haven't tried Docker for Windows), you may only be able to view examples in
your browser using `127.0.0.1` directly as opposed to `localhost`._

You can make an `index.html` file such as:

<pre>
&lt;html&gt;
&lt;head&gt;&lt;title&gt;Hostnamer&lt;/title&gt;&lt;/head&gt;
&lt;body&gt;
&lt;h1&gt; Hostnamer Technology &lt;/h1&gt;
&lt;p&gt;Welcome to the wonderful world of technology that returns reported
hostnames.  Sign up for our wonderful app today.&lt;/p&gt;
&lt;/body&gt;
&lt;/html&gt;
</pre>

Cool, if you add some `COPY` directives to drop those files in the image at the
`/home/caddy` directory like in the Dockerfile above, you can build the image
and deploy a Caddy service.  Caddy serves on port 2015 by default for
`localhost` / `127.0.0.1` so we'll forward that to `80` in the host network
namespace just to save a little typing (in case you're not familiar, 80 is the
default HTTP port).

<pre>
$ docker service create \
    --network caddypal \
    --publish 80:2015 \
    --name revprox \
    yourname/caddy
4pwllm8u7clfepbmbink9czwv
</pre>

Viewing it after the fact.
   
<pre>
$ docker service ls
ID            NAME     REPLICAS  IMAGE                 COMMAND
4pwllm8u7clf  revprox  1/1       nathanleclaire/caddy  

$ curl -i -4 localhost
HTTP/1.1 200 OK
Accept-Ranges: bytes
Content-Length: 223
Content-Type: text/html; charset=utf-8
Etag: W/"57a55d95-df"
Last-Modified: Sat, 06 Aug 2016 03:46:29 GMT
Server: Caddy
Date: Sat, 06 Aug 2016 03:54:43 GMT

&lt;html&gt;
&lt;head&gt;&lt;title&gt;Hostnamer&lt;/title&gt;&lt;/head&gt;
&lt;body&gt;
&lt;h1&gt; Hostnamer Technology &lt;/h1&gt;
&lt;p&gt;Welcome to the wonderful world of technology that returns reported
hostnames.  Sign up for our wonderful app today.&lt;/p&gt;
&lt;/body&gt;
&lt;/html&gt;
</pre>

Nice, Caddy is up and running.  We just created one static file to serve here
but we could add all of our static assets into the image if we truly desired,
or even create a `docker volume` and `--mount` them into the service.  We'll
see an example of using `--mount` later to keep track of the Caddy
certificates.

## Build & Run Shiny New Webapp

We're knocking out some static files, but most web applications include dynamic
functionality. Let's take a look, then, at a making a tiny little Go webserver
called `hn`.  This will serve as a simple demonstration of a downstream service
which we might want to slap Caddy in front of.

Its purpose is exactly as the landing page advertises: it responds to HTTP
requests with information about the hostname reported by its process.

```
package main

import (
    "log"
    "net/http"
    "os"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        h, err := os.Hostname()
        if err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }

        if _, err := w.Write([]byte(`⚡ The container serving this request is ` + h + ` ⚡`)); err != nil {
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
    })
    log.Println("Listening on :8080")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

(Why bind to port 8080 and not 80?  Privileges.  As the time of writing, I
could not find a way to add the capability
[`CAP_NET_BIND_SERVICE`](http://linux.die.net/man/7/capabilities) to service
tasks and I am running the webapps as a non-root user.)

To Dockerize it we will use a Makefile with a few Dockerfiles in a small image
pipeline to build the Go binary and then pass it to an `alpine`-based image
(this reduces image size and the scope of installed tools dramatically).

In the same directory:

`Makefile`:

```
USER := nathanleclaire
COMPILE_IMAGE := "$(USER)/hnbuild"
TAG := "latest"
RUN_IMAGE := "$(USER)/hn:$(TAG)"

default: compile

push:
    docker push $(RUN_IMAGE)

compile: compilerbuild
    docker build -t $(RUN_IMAGE) -f Dockerfile.run .

compilerbuild:
    docker build -t $(COMPILE_IMAGE) -f Dockerfile.build .
    docker run $(COMPILE_IMAGE) >hn
```

`Dockerfile.build`:

```
FROM golang:1.7-alpine
MAINTAINER Nathan LeClaire <nathan.leclaire@gmail.com>

RUN mkdir -p /go/src/github.com/nathanleclaire/hn
COPY . /go/src/github.com/nathanleclaire/hn
RUN go install github.com/nathanleclaire/hn

CMD ["cat", "/go/bin/hn"]
```

`Dockerfile.run`:

```
FROM alpine
MAINTAINER Nathan LeClaire <nathan.leclaire@gmail.com>

COPY /hn /usr/local/bin/hn
RUN chmod +x /usr/local/bin/hn
RUN adduser -D hn
USER hn

ENTRYPOINT ["hn"]
```

To build you can:

<pre>
$ make USER=yourname TAG=0.0.1
</pre>

To quickly produce tagged images you can do things like `make
USER=nathanleclaire TAG=foobar`. That would produce an image
`nathanleclaire/hn:foobar`.  

__NOTE:__ _Tags can be any alphanumeric string with a few special characters
such as `.` but it might be useful for you to create a convention for tagging
your images.  For instance, by `git commit` SHA.  In the future images might be
deployed based mostly based on content-addressable SHA256 checksums (many
building blocks for this are already in place) -- this would provide stronger
guarantees that what you end up running is what you originally created, with no
accidental or intentional tampering along the way._

Once we have an image we want to run from building the `hn` app, we can create
an `hn` service on the original `caddypal` network that we created.  This will
allow us to connect to the service from the `revprox` (Caddy) container later
on.

<pre>
$ docker service create --name hn --network caddypal yourname/hn:0.0.1
</pre>

If you want to test it, you can create another container on the same network
which `curl`s the service periodically.  It's not too bad, one might even argue
it's kind of fun.  I have a little `nathanleclaire/curl` image, but making your
own is simple as well.

<pre>
$ echo 'FROM alpine
RUN apk add --update --no-cache curl' | docker build -t curl -
Sending build context to Docker daemon 2.048 kB
Step 1 : FROM alpine
 ---> 4e38e38c8ce0
Step 2 : RUN apk add --update --no-cache curl
 ---> Running in 5f822f7c2205
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/community/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.4/community/x86_64/APKINDEX.tar.gz
(1/4) Installing ca-certificates (20160104-r4)
(2/4) Installing libssh2 (1.7.0-r0)
(3/4) Installing libcurl (7.50.1-r0)
(4/4) Installing curl (7.50.1-r0)
Executing busybox-1.24.2-r9.trigger
Executing ca-certificates-20160104-r4.trigger
OK: 6 MiB in 15 packages
 ---> 4894949d0443
Removing intermediate container 5f822f7c2205
Successfully built 4894949d0443
</pre>

Then just:

<pre>
$ docker service create --network caddypal \
    --name curler \
    curl \
    sh -c 'while true; do curl -s hn; sleep 5; done'
</pre>

To check the log, figure out the container ID that the service "task"
corresponds to using `docker ps`, and check `docker logs`, e.g.:

<pre>
$ $ docker ps 
CONTAINER ID        IMAGE                          COMMAND                  CREATED             STATUS              PORTS               NAMES
3a27edbd3c20        curl:latest                    "sh -c 'while true; d"   30 seconds ago      Up 25 seconds                           curler.1.ej67lix58oi8whdyd5qavqkrd
84a39281d40a        nathanleclaire/hn:0.0.4        "hn"                     11 minutes ago      Up 11 minutes                           hn.1.bw9tkd1ofnesunyqtrtho3tz1
2e315ae1dc08        nathanleclaire/caddy:landing   "caddy -log stdout"      2 hours ago         Up 2 hours          80/tcp, 443/tcp     revprox.1.3wlbcy3mj0eel8nrytj4z0uzo
bdc01719fc44        alpine                         "sh"                     13 hours ago        Up 13 hours                             hungry_galileo

$ docker logs 3a27edbd3c20
⚡ The container serving this request is 84a39281d40a ⚡
⚡ The container serving this request is 84a39281d40a ⚡
⚡ The container serving this request is 84a39281d40a ⚡
...
</pre>

(Note: A `docker service logs` command to make this easier is not implemented,
but it's [a known issue](https://github.com/docker/swarmkit/issues/1332).)

Cool.  And if we `update` our service's number of replicas, we can load balance
between different instances of the same app automatically.  Requests to `hn`
inside of the `curler` service will be resolved by the Docker daemon to a DNS
entry for a [virtual IP
address](https://en.wikipedia.org/wiki/Virtual_IP_address) which load balances
the requests using a fast low-level kernel feature,
[IPVS](http://www.linuxvirtualserver.org/software/ipvs.html). Service
containers can therefore be spread across various hosts and replicated to
"scale" a webapp (Linux process).  Since IPVS is a
[L4](https://en.wikipedia.org/wiki/Transport_layer) load balancer, it is very
fast, but higher level features such as HTTP header injection require [higher
level load balancers](https://en.wikipedia.org/wiki/Application_layer) like
Caddy. Using Swarm mode networking, the best of both worlds can be obtained.

<pre>
$ docker service update hn --replicas 5
hn

$ docker service ls
ID            NAME     REPLICAS  IMAGE                         COMMAND
4x7rmuebms6w  revprox  1/1       nathanleclaire/caddy:landing  
9lkbt5pe05bg  curler   1/1       curl                          sh -c while true; do curl -s hn:8080; echo; sleep 1; done
e5mm19wx86qh  hn       5/5       nathanleclaire/hn:0.0.4       

$ docker logs --tail 5 $(docker ps -q --filter name=curler)
⚡ The container serving this request is 84a39281d40a ⚡
⚡ The container serving this request is 381642bd7635 ⚡
⚡ The container serving this request is 9bc4c61086e3 ⚡
⚡ The container serving this request is 48a3253f0f20 ⚡
⚡ The container serving this request is 08d4629e5019 ⚡
</pre>

Check it out, hostname returned by the app changed.  Excellent!

## Roll out New Caddy Service With Webapp

Cool, now that we have a downstream service we can update Caddy to route some
requests to it,  Let's revise the Caddyfile to route requests to
`localhost:2015/hn` to this service.

Doing so is just a one line change.  We add `proxy /api hn:8080` to the
`localhost` block.

<pre>
localhost, 127.0.0.1 {
    log stdout
    root /home/caddy
    proxy /api hn:8080
}
</pre>

After re-building the image with a new tag, you can roll the new image out to
the `docker service` using `docker service update --image`.

Note that if you scale the Caddy service up a few replicas first, you can roll
out an update with minimal downtime.  The [rolling
update](https://docs.docker.com/engine/swarm/swarm-tutorial/rolling-update/)
features of swarm mode will update the containers one at a time (by default,
this is configurable) by killing and restarting them.

<pre>
$ make TAG=0.0.2
...
Successfully built yourname/caddy:0.0.2

$ docker service update revprox --replicas 2
revprox

$ docker service update revprox --image yourname/caddy:0.0.2
revprox
</pre>


Then hitting `localhost/api` should work:

<pre>
$ $ for i in $(seq 0 4); do curl -s -4 localhost/api; echo; done
⚡ The container serving this request is 381642bd7635 ⚡
⚡ The container serving this request is 84a39281d40a ⚡
⚡ The container serving this request is 381642bd7635 ⚡
⚡ The container serving this request is 84a39281d40a ⚡
⚡ The container serving this request is 381642bd7635 ⚡
</pre>

__NOTE:__ _If the published port displays odd behavior such as load balancing to
only one member of the service, try jiggling the published ports around a bit
with `docker service update --publish-rm 2015 revprox` and `docker service
update --publish-add 80:2015 revprox` to add it back in. Some issues with
updating network configuration for the service in place, especially across
`--image` updates, are still being ironed out._

Our trusty old `curler` service is "watching" this whole time and potentially
useful for spotting network hiccups in the rolling deploy as well.

<pre>
$ docker logs $(docker ps --filter name=curler -q) | less -S
</pre>

OK, we got some test configuration running locally to try things out, but we
all know that shipping our webapp as soon as possible is of paramount
importance.  So how about moving to higher environments such as staging?

## Deploy Staging Instance of Webapp

## Deploy Webapp to Production

Hell, we'll even throw in `minify` for fun, since [Caddy has a plugin which
will minify HTML, JavaScript, and CSS for you on the
fly](https://caddyserver.com/docs/minify) (we made sure to include this in the
download line in the `Dockerfile` above).

And at this point some of you out there are going "But Nate, this article would
be better if you persisted the certs on an EBS volume or with some kind of
secrets management service.  Otherwise, if the VM crashes or goes away, the
certificates might not be recoverable."  Well, you obviously know how to do it,
smarty pants, so go rig it up yourself.  Probably should write about it so
others can learn as well.

Or just use `cron` and `scp`.  Nobody's gonna do these types of backup
operations the exact same way because everyone has different risk profiles and
operational skills.  You are not the government, Facebook or $BIG_COMPANY (or
are you?) so you might have less at stake or more.  Judge accordingly.

## Update Webapp in Production

Until next time, stay sassy Internet.

- Nate
