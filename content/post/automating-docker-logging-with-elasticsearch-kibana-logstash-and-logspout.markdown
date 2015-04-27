---
layout: post
title: "Automating Docker Logging: ElasticSearch, Logstash, Kibana, and Logspout"
date: "2015-04-27"
comments: true
categories: [logging,elasticsearch,kibana,docker,Logstash]
---

{{%img src="/images/Logstashcontainer.gif" caption="You, too, could Logstash." %}}

Say that title five times fast!  Seriously though, I wasn't sure what else to
call this article so that people would actually find it.

This article is a spiritual successor to [Evan Hazlett's article on running the
ELK stack in
Docker](http://evanhazlett.com/2014/11/Logging-with-ELK-and-Docker/) and
[ClusterHQ's article on doing it with Fig/Docker
Compose and Flocker](https://clusterhq.com/blog/fig-flocker-multi-server-docker-apps/).
Huge shout out to them for being the giants whose shoulders I stand on. It is
also influenced by the recent [Borg
paper](http://research.google.com/pubs/pub43438.html) which came out and
mentions some of these tools in discussing having a "standard stack" for doing
the sorts of things that we are interested in here and more.

# The problem

Hopefully I don't need to convince you of the value of keeping meticulous logs
which are easily searchable. If I do, simply consider what happens when
something goes wrong with your application and _nobody has a damn clue what
happened_ - at the very least, the pointy haired bosses are upset, for some
reason that has to do with giant piles of money or audits or something like
that.

To that end, a lot of solutions have cropped up to help, including very lovely
technologies such as [Logstash](http://Logstash.net/).  More on that in a
second.  

Since most of us know that logging is critical, one of the issues which has
been driving people batty with the increase of interest in Docker is, of
course, how to handle logs in a Dockerized world.  

With Docker, one is suddenly forced to think of logging in a different way than
they otherwise might have.  In a traditional Linux deployment, the model for
application or infrastructure logging is usually to log to files, which are
frequently but not always located inside of the `/var/log` directory.  Indeed,
I have "fond" memories of checking the PHP logs for a project inside of that
directory when things would go blammo and our built-in application logging
wasn't telling me anything useful.  I'm not really a fan of splitting the logs
like that (more moving parts == harder to debug), and it's probably better
practice to have a uniform way to access logs. Indeed, there is an interesting
article about this idea (a "Unified Logging Layer")
[here](http://www.fluentd.org/blog/unified-logging-layer) by Kiyoto Tamura of
[Fluentd](http://www.fluentd.org), which is a tool similar to Logstash.

So what's different about Docker?  Well, suddenly, instead of having all of
your logs in files on one uniform place in the host system, they are scattered
in a variety of different isolated environments in containers.  Uh oh.  Sounds
like the opposite of what we said we wanted above.  

The way that Docker historically has handled logging is through the `docker
logs` command - Docker captures the STDOUT and STDERR of each container
process, stores it on disk, and the user can query it with `docker logs
<container>`.  This works pretty well for purposes like development where you
just want to dump some output to a terminal screen and access it pretty
quickly, but starts to become more troublesome when you want to consider using
Docker for more complex environments, _or_ you want to look at logs from more
traditionally-architected UNIX daemons which expect to run in the background
and log to disk inside of containers.  In the first case, the issues are mainly
around:

1. _discoverability_ - if containers are meant to be ephemeral, trying to track
   down the one with the logs that I want and parse them using something like
`grep` doesn't sound fun, and-
2. [_log rotation_](http://en.wikipedia.org/wiki/Log_rotation) - some services
   are particular chatty, or simply meant to live for a long time, so we need a
way of cleaning up after a while and making sure that our disk does not fill up
with logs we are not using.  Docker out of the box does not really support for
this as far as I'm aware.

I'm not going to talk about log rotation in this article, since that's a whole
'nother can of worms, but I will describe how the stack outlined here is meant
to ease the process of dealing with the first problem.

As for keeping tabs on processes which log to disk inside of containers, there
are a variety of solutions and hacks to make this work.  One of my favorites,
not really outlined here but in my opinion quite useful, is to make the
directory where the logs are written in the original container a
[volume](http://docs.docker.com/userguide/dockervolumes/), and have some
additional containers inherit that volume using `--volumes-from`.  Then they
can follow the logs using `tail -f /var/log/foo/access.log` or something like
that.  In my opinion this promotes a decent separation of concerns since your
container monitoring the log is different from the one writing to it, and
additionally (less substantially) you will actually bypass the union filesystem
to do so (just like you would do with a database).  No reason to track logs
(state) in images, really.

What to do about discoverability, then?  Well, we will run an [ELK
stack](https://www.elastic.co/webinars/introduction-elk-stack) inside of
Docker, and use the [logspout](https://github.com/gliderlabs/logspout) tool to
automatically route container logs to Logstash.  I really feel like this type
of approach is the future in a lot of ways - if you're going to be running
containers, stopping them, deleting them and so on, you might as well hook into
those native events and make the lifecycle of a container accessible to track
and monitor.  Then your infrastructure can be reactive instead of needy for
human intervention.  Likewise for things like load balancing, service
discovery, and so on, but that's for another article entirely.

# The approach

Following the lead of Evan and the ClusterHQ folks, we are going to run:

1. ElasticSearch to index the log data collected and make it more easily
   queryable
2. Logstash to act as a remote syslog to collect the logs from the containers
3. Logspout to actually send the container logs to Logstash
4. Kibana as a nice front end for interacting with the collected data
5. Cadvisor, a dashboard for monitoring container resource metrics, for kicks

If that sounds like an intimidating amount of stuff to run, try not to fret too
much - we're going to use [Docker Compose](https://github.com/docker/compose)
to make starting up this stack and using it very straightforward.

So, if you want to follow along at home, you can run the following commands to
get started very quickly (you will need the latest versions of
[Docker](https://docs.docker.com/installation/) and [Docker
Compose](https://docs.docker.com/compose) installed):

<pre>
$ git clone https://github.com/nathanleclaire/elk
$ cd elk
$ docker-compose -f docker-compose-quickstart.yml up
</pre>

This will boot up the application with prebaked images from Docker Hub, and
your Kibana front-end will be accessible from port 80 of whatever host
`DOCKER_HOST` points to.  

Personally, I like to kick up a DigitalOcean droplet or equivalent using
[Docker Machine](https://github.com/docker/machine) when I'm doing this kind of
work because the bandwidth for image pulls tends to be much better than on your
friendly neighborhood WiFi connection.  If you want to also do so, the commands
to create your own server to run this on will be similar to this (and once
again, make sure you have the latest version of Machine installed):

<pre>
$ export DIGITALOCEAN_ACCESS_TOKEN=MY_SECRET_API_TOKEN
$ docker-machine create -d digitalocean \
    --digitalocean-size 4gb \
    --digitalocean-image docker \
    droplet
....
....
....
To point your Docker client at it, run this in your shell: eval "$(docker-machine env droplet)"
$ eval "$(docker-machine env droplet)"
</pre>

I generally recommend a decently beefy server like outlined above because these
processes tend to be a little memory-hungry.  It will still work fine locally,
but the pulls may be a little slower unless you're one of the lucky few with
fiber.

If you're not a huge fan of running untrusted images (or you just want to
tinker and modify the build yourself), no problem: the default
`docker-compose.yml` in that repo is all based on `build` parameters, so you
can actually build the images yourself and 

<pre>
$ docker-compose build
$ docker-compose up
</pre>

When you boot the containers up, you'll see output like this in your terminal:

{{%img src="/images/figelk.png" %}}

You'll probably see some errors about Logspout failing to connect to syslog,
which is totally fine and normal.  It's just because the Logstash container
hasn't started yet.  When it starts, the errors will cease.

If you visit port 80 on the host where you've booted up the little group of
containers, you should be greeted by a Kibana welcome screen:

{{%img src="/images/kibanawelcome.png" %}}

Click on the little "Logstash dashboard" link (indicated by the arrow in the
picture above), or simply go directly to
`<machineIp>/#/dashboard/file/default.json`, and you will be taken to the
dashboard for your new Docker logging infrastructure!

Like I keep mentioning, the basic "stack" of containers for this was pretty
much ripped straight out of Evan's article, which is fantastic, but when I went
to go implement things for myself there were a few issues I encountered:

1. Logspout was sending data in a slightly different format than the `grok`
   filter for Logstash in Evan's original article / image expected, so:
2. There would be lots of grok parse failures in the logs (this just means
   Logstash tried to match the log message to a pattern it knows and couldn't).
By itself this wouldn't be _too_ terrible, but:
3. Because Logstash is a container monitored by Logspout, Logspout would
forward all of _Logstash_'s logs to Logstash, causing it to spin into a
frenetic loop and eat up almost all of the CPU on the box (`docker stats`, a
very useful command which will report container resource usage statistics in
realtime, was partially how I caught and understood that this was happening).

{{%img src="/images/dockerstats.png" caption="This can't be good." %}}


So what's a hacker to do?  Hack, of course!  I forked Evan's original
Dockerfiles/repos for the images and modified things a bit.  For starters, I
threw all of the containers into services in a `docker-compose.yml` file for
quick reference (that prevented having to re-type all of the `docker run`
commands over and over again whenever I wanted to re-run the stack).  I noticed
in [the Logspout Github repo](https://github.com/gliderlabs/logspout)'s
documentation that you could specify an environment variable on a container to
dictate that its logs should _not_ be forwarded by Logspout.  So, I enabled it
on the Logstash container: an environment variable setting of `LOGSPOUT=ignore`
did the trick.

It should also be noted, for anyone reading now, that the `gliderlabs/logspout`
image now expects the Docker socket to be mounted in at `/var/run/docker.sock`
(the classic location), rather than at `/tmp/docker.sock` like it was before -
this caused me a few headaches before I realized what was going on as I was
trying to use the commands from Evan's article verbatim.  So take note!!

Now my stack was no longer thrashing my CPU by getting into that infinite loop.
But I still had a challenge: all of those grok parse failures in the logs.  The
provided example configuration file for Logstash did not jive well with what
logspout was emitting.  So, in order to get a better grip on what was
happening, I did what anyone should do in this situation and read the source
code for Logspout.  

It wasn't long before I stumbled across this [block of code related to the
syslog
adapter](https://github.com/gliderlabs/logspout/blob/master/adapters/syslog/syslog.go#L33):

```go
func NewSyslogAdapter(route *router.Route) (router.LogAdapter, error) {
        transport, found := router.AdapterTransports.Lookup(route.AdapterTransport("udp"))
        if !found {
                return nil, errors.New("bad transport: " + route.Adapter)
        }
        conn, err := transport.Dial(route.Address, route.Options)
        if err != nil {
                return nil, err
        }

        format := getopt("SYSLOG_FORMAT", "rfc5424")
        priority := getopt("SYSLOG_PRIORITY", "{{.Priority}}")
        hostname := getopt("SYSLOG_HOSTNAME", "{{.Container.Config.Hostname}}")
        pid := getopt("SYSLOG_PID", "{{.Container.State.Pid}}")
        tag := getopt("SYSLOG_TAG", "{{.ContainerName}}"+route.Options["append_tag"])
        structuredData := getopt("SYSLOG_STRUCTURED_DATA", "")
        if route.Options["structured_data"] != "" {
                structuredData = route.Options["structured_data"]
        }
        data := getopt("SYSLOG_DATA", "{{.Data}}")

        var tmplStr string
        switch format {
        case "rfc5424":
                tmplStr = fmt.Sprintf("<%s>1 {{.Timestamp}} %s %s %s - [%s] %s\n",
                        priority, hostname, tag, pid, structuredData, data)
        case "rfc3164":
                tmplStr = fmt.Sprintf("<%s>{{.Timestamp}} %s %s[%s]: %s\n",
                        priority, hostname, tag, pid, data)
        default:
                return nil, errors.New("unsupported syslog format: " + format)
        }
        tmpl, err := template.New("syslog").Parse(tmplStr)
        if err != nil {
                return nil, err
        }
        return &SyslogAdapter{
                route: route,
                conn:  conn,
                tmpl:  tmpl,
        }, nil
}
```

Turns out that in my case Logspout forwards logs according to the [syslog
RFC5424 standard](https://tools.ietf.org/html/rfc5424) (you can see how it
defaults to this in the code above).  I spent some time fiddling with the very
cool [Logstash grok parse test app](http://grokdebug.herokuapp.com/), but then
wondered if there were any existing resources available online which solved
this problem already.  Some quick Googling lead me to [this
article](http://scottfrederick.cfapps.io/blog/2014/02/20/cloud-foundry-and-Logstash),
which brilliantly outlined pretty much the exact grok parse filter I needed.  I
changed around just a few things (for instance, I changed "app" field to
"containername") but I was soon on my way - parsing Logspout logs into useful
data.

My final Logstash configuration file looks like this:

```
input {
  tcp {
    port => 5000
    type => syslog
  }
  udp {
    port => 5000
    type => syslog
  }
}

filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOG5424PRI}%{NONNEGINT:ver} +(?:%{TIMESTAMP_ISO8601:ts}|-) +(?:%{HOSTNAME:containerid}|-) +(?:%{NOTSPACE:containername}|-) +(?:%{NOTSPACE:proc}|-) +(?:%{WORD:msgid}|-) +(?:%{SYSLOG5424SD:sd}|-|) +%{GREEDYDATA:msg}" }
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
    if !("_grokparsefailure" in [tags]) {
      mutate {
        replace => [ "@source_host", "%{syslog_hostname}" ]
        replace => [ "@message", "%{syslog_message}" ]
      }
    }
    mutate {
      remove_field => [ "syslog_hostname", "syslog_message", "syslog_timestamp" ]
    }
  }
}

output {
  elasticsearch { host => "elasticsearch" }
  stdout { codec => rubydebug }
}
```

There's probably plenty of room for improvement, but I'll have to get much
better at Logstash first ;P

# So what?

Now I actually had logs in a meaningful format, which weren't thrashing my CPU.
It's great!  Whenever I run a container on that host, the logs get indexed in
ElasticSearch and made available for querying from Kibana automatically!  The
Logstash filter takes care of parsing the raw syslog messages into more useful
labeled information.  This includes, as noted above, the logs from the
containers running this stack (except for Logstash - not sure how to handle
that one, or if I should even worry about it.  Perhaps there's an additional
configuration option that would make it only print its own logs to STDOUT
instead of all of them).  Imagine how useful this kind of automatic container
logging would be with something like
[RancherOS](http://rancher.com/rancher-os/) as well, where _everything_
including system services is running inside of Docker containers.

You can toggle which fields are displayed in the logs messages to get a quick
view of what's being logged to your application.  This makes it easier to get a
feel for what is happening in your containers in real time.  Kibana has an
insane amount of power and configurability, allowing you to sort, search, and
filter by all of the different fields you have.

{{%img src="/images/logfields.png" caption="Logs which are nice and easy to read and query!" %}}

Try running a container against the ELK stack host to see the logs appear in
Kibana automatically (you probably will need to refresh your browser or click
the little "refresh" button in Kibana)

<pre>
$ docker run -d --name number_spitter debian:jessie bash -c 'for i in {0..2000}; do echo $i; done'
</pre>

You can see now that most of the messages in the log are from the
`number_spitter` container, which naturally spits out a bunch of numbers in
that little bash loop.

{{%img src="/images/numberspitter.png" caption="Whaaaaat!  The Number Spitter container is so chatty!" %}}

There is a huge amount of amazing stuff you can do beyond this basic setup as
well.  Naturally, there is the time series graph which can be used as a visual
representation of your containers' activity over time, allowing you to zero
down on "hot spots" and quickly get a feel for what happened when, and why.

{{%img src="/images/kibanagraph.png" caption="What the hell happened here?  I don't know, but I can find out." %}}

Displayed: actual incident with the ElasticSearch container.

There is also a huge world of additional things which can and should be done
with Logstash in this setup - the configuration file discussed here is only the
beginning.  Some containers have their own logging format which should be
subjected to additional parsing.  For instance, you can see that the log
messages in the picture above showing the "table format" are for the Kibana
container itself and have their own timestamp, information about which IP
address accessed what file, the status code of the HTTP response, and so on.

So, that is additional information which could definitely be parsed into a more
useful structured format, and it is the kind of thing which will need to be
done on a per-app basis.  Likewise, you can probably imagine really cool
higher-order constructs like messages which bump their priority up if they
match a certain pattern like if the application recovers from a panic, hits a
code path which cases a null pointer exception, fails to connect to the
database, and so on.

Also, if Logspout also forwarded Docker events (I'm confused as to whether or
not it supports this, since I seem to recall seeing delete events for some
containers show up but nothing else) and/or Docker daemon logs that would be
SLICK!  Perhaps there is an easier way to do this than hijacking Logspout to do
it though.

Additionally, Docker 1.6 has [log
drivers](https://github.com/docker/docker/issues/7195) that might be able to do
a similar thing in a slightly different way, so I'm curious to explore how this
setup might mutate when taking that into consideration.  I don't understand the
Logspout internals well enough yet to know if you could do `--log-driver=none`
and still have Logspout forward the logs, for instance.  That would be pretty
cool since then you would only have to track the data in ElasticSearch, not in
ES _and_ `--log-driver=json` format.

I'm not really sure if Logstash has support for eventing as well (e.g. send an
e-mail or a text message to the on-call person if too many errors come in a
limited period of time), but that's another potential use case (I'd be
surprised if something like this wasn't already possible if not
well-supported).  Come to think of it, this kind of thing is really screaming
for a Slack integration as well - e.g., notify the #sales channel every time we
close a no-touch subscription, which we know about because it got logged.  But
I digress.

Speaking of digression, the demo app also includes an instance of
[cAdvisor](https://github.com/GoogleComputeEngine/cadvisor), a very useful tool
to monitor the resource usage of your containers.  You can access it at port
8080 on the host you're working with:

{{%img src="/images/cadvisor.png" caption="Pretty graphs for your containers" %}}

# Nice.  Should I start using this right away?

This isn't the exact setup that you would neccessarily want to chuck into
production immediately without modifying anything, although it definitely looks
a lot better than just "`docker run`, maybe check up on them later manually
using `docker logs`".  Some additional things to consider, in no particular order:

1. ElasticSearch replicas: persisting the data on multiple nodes for
redundancy.  Weird stuff will happen, nodes will go down, and ideally your
infrastructure should be set up to handle this kind of failure smoothly.
Likewise, setting up a logspout instance on each node which forwards the host's
logs to the "master" Logstash (and I'm not really certain of how redundancy
should work for this potential point of failure) is something you need to
tackle if you have a multi-host setup.
2. [Backing up](https://twitter.com/jessitron/status/591188506350845952) and
   rotating the log data stored in ElasticSearch.  To that end, I'm sure
[ClusterHQ](https://clusterhq.com) (self-identified as the "container data
people") would love to help you with this ;)
3. Making sure that access to this interface is constrained at the network and
user level (the demo app leaves everything wide open, so if you run it on the
public Internet, expect _everyone_ to be able to see it and mess with it)
4. Adding [container restart
   policies](ihttp://docs.docker.com/reference/commandline/cli/#restart-policies)
and
[monitoring](http://rancher.com/comparing-monitoring-options-for-docker-deployments/)
to ensure health and uptime of the services.
5. Running the containers as lower-privileged users for better security

So, there are still many things to think about before using this for Very Real
Stuff, but I hope I have gotten some of the gears turning in your head about
how you might accomplish this for yourself if you are motivated.  I feel like
running this tooling is within the reach of even a very small startup nowadays,
and I'm pretty excited that world-class tools like this are becoming more
accessible.  Ultimately it will be critical for teams now and in the future to
be capable of scaling to many machines per operator (SRE), and this is exactly
the type of tooling which makes that goal more approachable.

# Fin 

Go forth and log my friends!!  And let me know if you have ideas or
suggestions.  I love to see follow-up articles on this sort of thing as well,
so maybe you can be the next link in the chain.

Until next time, stay sassy Internet!

- Nathan
