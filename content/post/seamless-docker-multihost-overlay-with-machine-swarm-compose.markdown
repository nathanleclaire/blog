---
layout: post
title: "Seamless Docker Multihost Overlay Networking With Machine, Swarm, and Compose"
date: "2015-11-17"
comments: true
draft: true
categories: [docker,machine,swarm,compose,networking,overlay,libnetwork,devops]
---

First, let's create a host to hold the key-value store:

```
$ docker-machine create -d digitalocean kvstore
```

We can define the `consul` sevice in our `docker-compose.yml` file mentioned
above like so:

```
consul:
  image: progrium/consul
  hostname: consul
  command: -server -bootstrap
  ports:
    - "8500:8500"
```

Then run it:

```
$ docker-compose run -d --service-ports consul
```

Now we'll set up the Swarm master box (I like to think of it as a "queen bee"):

```
$ docker-machine create \
    -d digitalocean \
    --digitalocean-image debian-8-x64 \
    --swarm \
    --swarm-master \
    --swarm-discovery="consul://$(docker-machine ip kvstore):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip kvstore):8500" \
    --engine-opt="cluster-advertise=eth0:2376" \
    queenbee-$(echo $(whoami)-$(date +"%m-%d-%Y"))
```

And at least one worker bee node.  E.g.:

```
$ export NUM_WORKERS=3; for i in $(seq 1 $NUM_WORKERS); do
    docker-machine create \
        -d digitalocean \
        --digitalocean-image debian-8-x64 \
        --swarm \
        --swarm-discovery="consul://$(docker-machine ip kvstore):8500" \
        --engine-opt="cluster-store=consul://$(docker-machine ip kvstore):8500" \
        --engine-opt="cluster-advertise=eth0:2376" \
        workerbee-${i}-$(echo $(whoami)-$(date +"%m-%d-%Y")) &
done;
wait
```

You should now be able to verify that the swarm is alive and buzzing.

```
$ docker-machine ls
NAME                                    ACTIVE   DRIVER         STATE     URL                          SWARM
default                                 -        virtualbox     Stopped
kvstore                                 *        digitalocean   Running   tcp://104.236.186.209:2376
queenbee-nathanleclaire-11-07-2015      -        digitalocean   Running   tcp://159.203.128.9:2376     queenbee-nathanleclaire-11-07-2015 (master)
workerbee-1-nathanleclaire-11-07-2015   -        digitalocean   Running   tcp://104.236.236.251:2376   queenbee-nathanleclaire-11-07-2015
workerbee-2-nathanleclaire-11-07-2015   -        digitalocean   Running   tcp://104.131.27.226:2376    queenbee-nathanleclaire-11-07-2015
workerbee-3-nathanleclaire-11-07-2015   -        digitalocean   Running   tcp://104.236.95.188:2376    queenbee-nathanleclaire-11-07-2015

$ eval $(docker-machine env --swarm queenbee-nathanleclaire-11-07-2015)

$ docker info
Containers: 9
Images: 10
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 4
 queenbee-nathanleclaire-11-09-2015: 198.199.98.44:2376
  └ Containers: 3
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 519.2 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.16.0-4-amd64, operatingsystem=Debian GNU/Linux 8 (jessie), provider=digitalocean, storagedriver=aufs
 workerbee-1-nathanleclaire-11-09-2015: 159.203.249.60:2376
  └ Containers: 2
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 519.2 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.16.0-4-amd64, operatingsystem=Debian GNU/Linux 8 (jessie), provider=digitalocean, storagedriver=aufs
 workerbee-2-nathanleclaire-11-09-2015: 104.236.141.141:2376
  └ Containers: 2
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 519.2 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.16.0-4-amd64, operatingsystem=Debian GNU/Linux 8 (jessie), provider=digitalocean, storagedriver=aufs
 workerbee-3-nathanleclaire-11-09-2015: 107.170.236.84:2376
  └ Containers: 2
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 519.2 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.16.0-4-amd64, operatingsystem=Debian GNU/Linux 8 (jessie), provider=digitalocean, storagedriver=aufs
CPUs: 4
Total Memory: 2.028 GiB
Name: 7ec9f0a9b1d3
```

We can update the definition of the `provision` service to have anti-affinity
with other containers of the same type using something like this:

<pre>
provision:
  image: nathanleclaire/ansibleprovision
  net: host
  volumes:
    - /root/.ssh:/hostssh
  labels:
    - "com.nathanleclaire.ansibleprovison"
  environment:
    - "affinity:label!=com.nathanleclaire.ansibleprovision"
</pre>

The label and Swarm scheduling constraint set through the environment variable
will ensure that no two `provision` service containers are scheduled on the
same host.

To provision, this will do:

```
$ for i in $(seq 0 ${NUM_WORKERS}); do docker-compose run -d provision; done
Pulling provision (nathanleclaire/ansibleprovision:latest)...
workerbee-2-nathanleclaire-11-07-2015: Pulling nathanleclaire/ansibleprovision:latest... : downloaded
queenbee-nathanleclaire-11-07-2015: Pulling nathanleclaire/ansibleprovision:latest... : downloaded
workerbee-1-nathanleclaire-11-07-2015: Pulling nathanleclaire/ansibleprovision:latest... : downloaded
workerbee-3-nathanleclaire-11-07-2015: Pulling nathanleclaire/ansibleprovision:latest... : downloaded
ansible_provision_run_1
ansible_provision_run_2
ansible_provision_run_3
ansible_provision_run_4
```

(Note that the master has been accounted for here).

Provisioning the `kvstore` node in a similar fashion is left as an exercise for
the reader.

Since we installed it with Ansible, you can invoke `htop` over SSH using Docker
Machine on any given host like so:

```
$ docker-machine ssh mcnname -t htop
```

{{%img src="/images/ansible/htop.png" %}}

Don't forget to clean up the provisioning containers:

```
$ docker rm $(docker ps -aq --filter label=com.nathanleclaire.ansibleprovison)
```

## Triple ultra combo round: Let's Have Some Fun With Cross-host Networking.

Now that we have the Swarm / libnetwork cluster up and running and lightly
provisioned, let's do something fun.  We'll run and scale a
[RethinkDB](https://rethinkdb.com) cluster which communicates seamlessly across
hosts using the new libnetwork changes.

Our service definition in `docker-compose.yml` for this RethinkDB cluster is as
follows:

<pre>
leader:
  container_name: rethinkleader
  image: rethinkdb
  environment:
    - affinity:container!=*rethink*
  ports:
    - "8080:8080"
  restart: always
follower:
  image: rethinkdb
  environment:
    - affinity:container!=*rethink*
  command: rethinkdb --join rethinkleader
  restart: always
</pre>

There's a few noteworthy things going on here so let's take a second to discuss
why it's set up this way.  We have two services, `leader` and `follower`.  The
`leader` service starts a RethinkDB instance which is listening on all ports
(admin interface, client connection, and intracluster connection) and available
to accept connection from other RethinkDB instances.  The container name will
be used as a hostname when the follower instances connect so I've set
`container_name` explicitly to `rethinkleader` in order to avoid having to rely
on Compose's automatic container naming.

Both services get a `environment` setting of `affinity:container!=*rethink*` to
ensure that they never run on the same host as each other.  This ensures that
the RethinkDB instances are spread evenly across the cluster (never being
colocated on the same host), even if the running Swarm instance uses the
`binpack` scheduling strategy (which packs containers as tightly as possible on
the same host by default).  I tried all kinds of ways to set these affinities
using Compose, including setting labels and using label based anti-affinity
([issue here](https://github.com/docker/compose/issues/2365)), and reserving
enough memory on each host to push them all onto different nodes ([issue
here](https://github.com/docker/swarm/issues/1399)), but at the time of
writing, this is the only way I found which works reliably.  If you can or
cannot confirm a reproduction of the issues with this cluster setup, all of us
would be happy to hear.  I'm sure the other methods will get fixed soon as more
polish gets added to the Swarm-Compose integration. On the leader node, we
expose `8080` (the RethinkDB admin interface panel) to the host.

Now, note the two remaining properties of the `follower` service.  The first is
that the `command` has been set to `rethinkdb --join rethinkleader` (RethinkDB
will default to attempting to connect to `29015`, the default port for
intracluster communication, when invoked with `--join host` flag).  Because
Compose will automatically create an `overlay` network if it's pointed at a
Swarm cluster and `--x-networking` is set, the `rethinkleader` container will
be available at that same hostname.  Therefore, the follower container(s) will
be scheduled on different hosts and be able to transparently access the leader
using the Docker `overlay` network!  

The second important property is that `restart: always` has been specified as a
restart policy for the container.  It's kind of a hack, but this is used to
ensure that if Compose starts the follower before the leader, it re-tries
connection until the leader is up as well (usually just one or two times).  The
Compose maintainers insist that they do not want to add custom ordering of
service start (arguing that services should be resilient to this type of
failure on their own), and I think it's a pretty reasonable position.  Restart
policies with a maximum number of failures (existing today) or an exponentially
increasing backoff between retries (not currently existing) might be a slightly
more elegant solution that `--restart always`, but for a demo it works fine.
Ultimately, I think custom restart policies (not sure how this would be
configured -- maybe like how volume plugins work today?) might be the answer.
"Let it crash", right?

Anywho, once you have this Compose file set up, ensure that your Docker
environment variables are set to talk to the Swarm master, then:

```
$ docker-compose --x-networking up -d
```

Once the `docker-compose up` finishes running, we can view the created services
like so:

```
$ docker-compose ps
        Name                      Command               State                          Ports
--------------------------------------------------------------------------------------------------------------------
rethinkdb_follower_1   rethinkdb --join rethinkleader   Up      28015/tcp, 29015/tcp, 8080/tcp
rethinkleader          rethinkdb --bind all             Up      28015/tcp, 29015/tcp, 104.236.141.141:8080->8080/tcp
```

Note you can also see in `docker ps` the nodes where they were scheduled:

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                          PORTS                                                 NAMES
980a0eb54b86        rethinkdb           "rethinkdb --bind all"   20 seconds ago      Up 18 seconds                   28015/tcp, 159.203.249.60:8080->8080/tcp, 29015/tcp   workerbee-1-nathanleclaire-11-09-2015/rethinkleader
f118f5d53f2e        rethinkdb           "rethinkdb --join ret"   22 seconds ago      Restarting (1) 20 seconds ago   8080/tcp, 28015/tcp, 29015/tcp                        workerbee-3-nathanleclaire-11-09-2015/rethinkdb_follower_1
```

You can then scale out to 3 total follower nodes (so, one instance of RethinkDB
per host):

```
$ docker-compose --x-networking scale follower=3
Creating and starting 2 ... done
Creating and starting 3 ... done
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                         PORTS                                                 NAMES
794b4a2549ec        rethinkdb           "rethinkdb --join ret"   57 seconds ago      Up 55 seconds                  8080/tcp, 28015/tcp, 29015/tcp                        workerbee-2-nathanleclaire-11-09-2015/rethinkdb_follower_3
113a02566687        rethinkdb           "rethinkdb --join ret"   58 seconds ago      Up 56 seconds                  8080/tcp, 28015/tcp, 29015/tcp                        queenbee-nathanleclaire-11-09-2015/rethinkdb_follower_2
980a0eb54b86        rethinkdb           "rethinkdb --bind all"   3 minutes ago       Up 3 minutes                   28015/tcp, 159.203.249.60:8080->8080/tcp, 29015/tcp   workerbee-1-nathanleclaire-11-09-2015/rethinkleader
f118f5d53f2e        rethinkdb           "rethinkdb --join ret"   3 minutes ago       Restarting (1) 3 minutes ago   8080/tcp, 28015/tcp, 29015/tcp                        workerbee-3-nathanleclaire-11-09-2015/rethinkdb_follower_1
```

And hey, RethinkDB comes with a super slick admin interface that you can access
at `<leader-node-ip>:8080`:

{{%img src="/images/ansible/rethink.png" %}}

Theoretically, you could scale this horizontally quite a lot simply by adding
more nodes to run followers on and running `docker-compose scale` some more.
Then run other services too.  Just set the labels and go -- Good times.

# fin

I know it's somewhat oddball considering the general workflow expected out of
Ansible users (and I kinda went off the rails there talking about SwarmNet),
but I find this type of provisioning / bootstrapping process really fun and
somewhat refreshing.  In the future, perhaps an extremely lightweight
container-specific type of provisioning software which is intended to be used
this way could emerge to enable this type of workflow.  Looking even further
out, the need for traditional provisioning might shrink into the horizon as
minimalistic Docker-focused operating systems such as
[RancherOS](http://rancher.com/rancher-os/) gain popularity and maturity
(consequently the "provisioning" _is_ running additional system-level Docker
containers) and/or other innovations allow us to strip machine-specific lower
layers away entirely.

Likewise, in the future, I'd really like to see a [declarative configuration
for Machine](https://github.com/docker/machine/issues/773), or just the Docker
tools in general, that makes this process (including bootstrapping swarms and
overlay networks) easier.  Docker Compose isn't really super oriented towards
the sort of use case that we're using it for here (it is somewhat more strictly
expected to bootstrap a single application, not infrastructure), so I hope in
the future to see more positioning supporting these types of use cases out of
Docker projects in the future.  The Compose folks are really smart and working
on getting everything right, so I'm optimistic there.

Until next time, stay sassy Internet.

- Nathan
