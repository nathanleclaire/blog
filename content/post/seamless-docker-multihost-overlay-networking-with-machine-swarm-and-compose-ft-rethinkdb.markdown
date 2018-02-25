---
layout: post
title: "Seamless Docker Multihost Overlay Networking on DigitalOcean With Machine, Swarm, and Compose ft. RethinkDB"
date: "2015-11-17"
comments: true
categories: [docker,machine,swarm,compose,networking,overlay,libnetwork,devops]
---

{{%img src="/images/littleclusterguy.jpg" %}}

There have been a lot of good articles popping up lately on the new Docker
networking features and how to use them with existing Docker tools.  So far,
most guides will get you through setting up VirtualBox, which is great for
getting started, but nothing beats the feeling of getting your hands on an
enormous supply of seamlessly networked computing power.  So, this article uses
Docker Machine, Swarm, and Compose to take it to the cloud and put that power
in your hands.  I hope to stimulate your imagination as well as set the gears
turning for you on some complications and potential solutions for actually
putting this stuff out there in the real world.

Today we're going to:

- Spin up a Swarm cluster on DigitalOcean using Docker Machine
- Provision the created nodes using Ansible containers
- Run a 4-node [RethinkDB](https://rethinkdb.com) cluster across those nodes
- Use Docker Machine SSH port forwarding to access the RethinkDB admin panel without exposing it publicly

You can [clone this repo](https://github.com/nathanleclaire/mhswarm) to follow
along at home with the relevant files, and a convenient script including all of
the outlined commands, if desired.

### Initial Setup

First install:

- The latest versions of [Docker Machine](https://github.com/docker/machine)
  and [Docker Compose](https://github.com/docker/compose)
- The Docker 1.9.1 client binary

And create an account with DigitalOcean if you don't have one already. Next,
ensure that the `DIGITALOCEAN_ACCESS_TOKEN` environment variable is set with
your DigitalOcean API token.

```
$ export DIGITALOCEAN_ACCESS_TOKEN=asdfasdfasdfasdfasdfasdfasdfasdf
```

We're going to use Debian 8 for our host operating system today, so let's
configure Machine to expect that for this terminal session as well (Docker
Machine recently added support for Ubuntu >=15.04, which is needed for the
`overlay` driver of libnetwork, but that won't be released until about a week
after the time of writing).  We'll also make sure to active the private
networking feature on the created servers.  This will come in handy later as
we're setting up our overlay network.  I also set the `DIGITALOCEAN_REGION` to
`sfo1` (San Francisco), but you could set it to a region of your choice.

```
$ export DIGITALOCEAN_IMAGE=debian-8-x64
$ export DIGITALOCEAN_PRIVATE_NETWORKING=true
$ export DIGITALOCEAN_REGION=sfo1
```

### The Key-Value Store

First, let's create a host to contain the [key-value
store](https://en.wikipedia.org/wiki/Key-value_database).  This will be used by
both Swarm and libnetwork to bootstrap and communicate the shared state of the
cluster across nodes.

```
$ docker-machine create -d digitalocean kvstore
...
```

When that's finished, take a look at the output of the `ifconfig` command on
the created instance.  It should look something like this.

```
$ docker-machine ssh kvstore ifconfig
docker0   Link encap:Ethernet  HWaddr 02:42:88:cb:4f:b9
          inet addr:172.17.0.1  Bcast:0.0.0.0  Mask:255.255.0.0
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

eth0      Link encap:Ethernet  HWaddr 04:01:87:b3:66:01
          inet addr:159.203.108.236  Bcast:159.203.111.255  Mask:255.255.240.0
          inet6 addr: fe80::601:87ff:feb3:6601/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:12869 errors:0 dropped:0 overruns:0 frame:0
          TX packets:6125 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:16411203 (15.6 MiB)  TX bytes:566452 (553.1 KiB)

eth1      Link encap:Ethernet  HWaddr 04:01:87:b3:66:02
          inet addr:10.132.231.52  Bcast:10.132.255.255  Mask:255.255.0.0
          inet6 addr: fe80::601:87ff:feb3:6602/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:648 (648.0 B)  TX bytes:728 (728.0 B)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

You can see that Docker has created its usual bridge, `docker0`, and there is
an interface `eth0` which allows inbound and outbound access to the Internet.
There is also an interface `eth1` which allows private networking between nodes
in the same datacenter.  We will use this in this walkthrough to ensure that we
at least don't expose our key value store to the entire Internet.

You can most likely verify this private-vs-public address assertion by using
`ping` on your local computer.

{{%img src="/images/networking/one-ping-only.png" %}}

The public address:

```
$ ping -c 1 $(docker-machine ssh kvstore 'ifconfig eth0 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
PING 159.203.108.236 (159.203.108.236): 56 data bytes
64 bytes from 159.203.108.236: icmp_seq=0 ttl=48 time=79.571 ms

--- 159.203.108.236 ping statistics ---
1 packets transmitted, 1 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 79.571/79.571/79.571/0.000 ms
```

The private address (note that we use `eth0` instead of `eth1` here):

```
$ ping -c 1 $(docker-machine ssh kvstore 'ifconfig eth1 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
PING 10.132.231.52 (10.132.231.52): 56 data bytes

--- 10.132.231.52 ping statistics ---
1 packets transmitted, 0 packets received, 100.0% packet loss
```

### DIGRESSION: What to expect when you're expecting (libnetwork & swarm)

The `overlay` driver for libnetwork has a few expectations of you before it
will do its ~~magic~~ sufficiently advanced technological trick.  Likewise,
Swarm has at least one thing it needs configured to be able to properly
schedule based on resources.

I've set everything up properly in this article, but if you're following along
at home and deviating from the specifically prescribed commands here you
ABSOLUTELY MUST ensure that:

- Your Linux kernel version is greater than or equal to 3.16.
- The ports for [Serf](https://www.serfdom.io/) and VXLAN are available for
  inbound connections for TCP _and_ UDP-based traffic.  These are `:7946` and
  `:4789` respectively.
- [Memory accounting is enabled on the created
  instances](https://docs.docker.com/engine/installation/ubuntulinux/#adjust-memory-and-swap-accounting)
  (this is needed for Swarm to schedule properly with `-m`)

### Swarm

So, we have an IP that we can use to talk to other servers in the same data
center, and we will use this to bootstrap our cluster.  Let's go ahead and save
that into a shell environment variable so we don't have to execute that lengthy
command each time we want to use it.

```
$ export KV_IP=$(docker-machine ssh kvstore 'ifconfig eth1 | grep "inet addr:" | cut -d: -f2 | cut -d" " -f1')
```

In the future, hopefully this might be available from some type of
`docker-machine ip --private` command or similar.

Now let's run [Consul](https://consul.io), a key-value store which enables
discovery of nodes for Docker.  `docker run`'s `-p` flag accepts an optional
parameter to specify the interface that the exposed container port should be
forwarded to. E.g., you can specify to expose port `8080` from the container
only on `localhost`, instead of on `0.0.0.0` (the default), using `docker run
-p 127.0.0.1:8080:8080`.

So, naturally, in our Consul container, we will forward the port to our private
networking interface mentioned above so that only machines in the same
datacenter can access it.

```
$ eval $(docker-machine env kvstore)
$ docker run -d \
      -p ${KV_IP}:8500:8500 \
      -h consul \
      --restart always \
      progrium/consul -server -bootstrap
...
```

Now we'll set up the Swarm master box (I like to think of it as a "queen bee",
hence the name).  `--swarm` and `--swarm-master` flags are hopefully
self-explanatory.  But take a look at those other flags.  They're where the fun
bits happen.

```
$ docker-machine create \
    -d digitalocean \
    --swarm \
    --swarm-master \
    --swarm-discovery="consul://${KV_IP}:8500" \
    --engine-opt="cluster-store=consul://${KV_IP}:8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    queenbee
```

`--swarm-discovery` instructs the created Swarm worker container to look for
the created key-value store using the specified address and protocol
(`consul://` here, but it also works for Docker Hub discovery using `token://`,
[ZooKeeper](https://zookeeper.apache.org/) using `zk://`, and so on).  This
allows the instances of the Swarm to find and communicate with each other.

`--engine-opt` allows us to set Docker daemon flags without needing to edit the
configuration files manually.  Here we have two flags that we're setting:
`--cluster-store` and `--cluster-advertise`. 

- `--cluster-store` tells the Docker daemon which KV store to use for
  libnetwork's needed coordination, similar to the `--swarm-discovery` option
outlined above.
- `--cluster-advertise` allows us to specify an address that the created Docker
  daemon should "advertise" as connectable to the cluster using the KV store.

After the queen bee, we create at least one worker bee node.  E.g.:

```
$ export NUM_WORKERS=3; for i in $(seq 1 $NUM_WORKERS); do
    docker-machine create \
        -d digitalocean \
        --swarm \
        --swarm-discovery="consul://${KV_IP}:8500" \
        --engine-opt="cluster-store=consul://${KV_IP}:8500" \
        --engine-opt="cluster-advertise=eth1:2376" \
        workerbee-${i} &
done;
wait
```

You should now be able to verify that the swarm has been created.

```
$ docker-machine ls
NAME          ACTIVE   DRIVER         STATE     URL                          SWARM
default       -        virtualbox     Saved
kvstore       -        digitalocean   Running   tcp://159.203.108.236:2376
queenbee      *        digitalocean   Running   tcp://159.203.105.26:2376    queenbee (master)
workerbee-1   -        digitalocean   Running   tcp://159.203.116.251:2376   queenbee
workerbee-2   -        digitalocean   Running   tcp://159.203.77.141:2376    queenbee
workerbee-3   -        digitalocean   Running   tcp://159.203.71.235:2376    queenbee
```

Set the environment variables for connection to the swarm master:

```
$ eval $(docker-machine env --swarm queenbee)
```

And verify connectivity of the swarm by running `docker info`.  You should see
something like this:

```
$ docker info
Containers: 5
Images: 4
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 4
 queenbee: 159.203.105.26:2376
  └ Containers: 2
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 519.2 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.16.0-4-amd64, operatingsystem=Debian GNU/Linux 8 (jessie), provider=digitalocean, storagedriver=aufs
 workerbee-1: 159.203.116.251:2376
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 519.2 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.16.0-4-amd64, operatingsystem=Debian GNU/Linux 8 (jessie), provider=digitalocean, storagedriver=aufs
 workerbee-2: 159.203.77.141:2376
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 519.2 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.16.0-4-amd64, operatingsystem=Debian GNU/Linux 8 (jessie), provider=digitalocean, storagedriver=aufs
 workerbee-3: 159.203.71.235:2376
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 519.2 MiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.16.0-4-amd64, operatingsystem=Debian GNU/Linux 8 (jessie), provider=digitalocean, storagedriver=aufs
CPUs: 4
Total Memory: 2.028 GiB
Name: 37a57749a3b9
```

Note that you can see all of the Swarm containers:

```
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                     NAMES
2091ccf25804        swarm:latest        "/swarm join --advert"   12 minutes ago      Up 12 minutes       2375/tcp                                  workerbee-1/swarm-agent
097f32b1d435        swarm:latest        "/swarm join --advert"   12 minutes ago      Up 12 minutes       2375/tcp                                  workerbee-2/swarm-agent
4eb1fc84d399        swarm:latest        "/swarm join --advert"   12 minutes ago      Up 12 minutes       2375/tcp                                  workerbee-3/swarm-agent
d6adead23e97        swarm:latest        "/swarm join --advert"   20 minutes ago      Up 20 minutes       2375/tcp                                  queenbee/swarm-agent
37a57749a3b9        swarm:latest        "/swarm manage --tlsv"   20 minutes ago      Up 20 minutes       2375/tcp, 159.203.105.26:3376->3376/tcp   queenbee/swarm-agent-master
```

## Bootstrapping node configuration

We can use [the Ansible trick from this
article](/blog/2015/11/10/using-ansible-with-docker-machine-to-bootstrap-host-nodes/)
to bootstrap some basic node configuration once they have been created.  This
will set up some firewalls, install some sysadmin-friendly software on the
created instances and configure the GRUB profile to activate memory accounting.

To make the previous article's trick work with Swarm, we can update the
definition of the `provision` service to have anti-affinity with other
containers of the same type using something like this:

<pre>
provision:
  image: nathanleclaire/ansibleprovision
  net: host
  volumes:
    - /root/.ssh:/hostssh
  labels:
    - "com.nathanleclaire.ansibleprovison"
  environment:
    - "affinity:container!=*provision*"
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

While the Ansible containers are running, you can actually look at them and
check up on them using `docker ps` and `docker logs`:

<pre>
$ docker ps
CONTAINER ID        IMAGE                             COMMAND                  CREATED             STATUS              PORTS               NAMES
4dd887eeb02d        nathanleclaire/ansibleprovision   "./entrypoint.sh /pla"   16 seconds ago      Up 9 seconds                            queenbee/multihostdockerfiles_provision_run_4
e02e254fdba7        nathanleclaire/ansibleprovision   "./entrypoint.sh /pla"   18 seconds ago      Up 11 seconds                           workerbee-1/multihostdockerfiles_provision_run_3
8d918cd65608        nathanleclaire/ansibleprovision   "./entrypoint.sh /pla"   21 seconds ago      Up 13 seconds                           workerbee-2/multihostdockerfiles_provision_run_2
62c812ec3f57        nathanleclaire/ansibleprovision   "./entrypoint.sh /pla"   23 seconds ago      Up 15 seconds                           workerbee-3/multihostdockerfiles_provision_run_1

$ docker logs $(docker ps -lq)
Generating public/private rsa key pair.
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
5b:a7:88:88:3e:43:1c:3a:8e:c8:06:df:a0:a2:3b:59 root@queenbee
The key's randomart image is:
+---[RSA 2048]----+
|                 |
|                 |
|                 |
|  .              |
| o .    S . .    |
|+ E. . . + o     |
|*B.o. . o .      |
|B=+ .            |
|*o.o             |
+-----------------+

PLAY [Trick out Debian server] ************************************************

TASK: [Install desired packages] **********************************************
changed: [localhost] => (item=htop,tree,jq,fail2ban,vim,mosh,ufw)

TASK: [Get simple .vimrc] *****************************************************
changed: [localhost]

TASK: [Reset UFW firewall] ****************************************************
ok: [localhost]

TASK: [Allow SSH access on instance] ******************************************
ok: [localhost]

TASK: [Open Docker daemon, HTTP(S), and Swarm ports] **************************
ok: [localhost] => (item=80)
ok: [localhost] => (item=443)
ok: [localhost] => (item=2376)
ok: [localhost] => (item=3376)
ok: [localhost] => (item=7946)

TASK: [Open VXLAN and Serf UDP ports] *****************************************
ok: [localhost] => (item=7946)
ok: [localhost] => (item=4789)

TASK: [Set to deny incoming requests by default] ******************************
ok: [localhost]

TASK: [Turn on UFW] ***********************************************************
changed: [localhost]

TASK: [Set memory limit in GRUB] **********************************************
changed: [localhost]

TASK: [Load new GRUB config] **************************************************
changed: [localhost]

PLAY RECAP ********************************************************************
localhost                  : ok=10   changed=5    unreachable=0    failed=0
</pre>

Provisioning the `kvstore` node in a similar fashion is left as an exercise for
the reader.

Since we installed it with Ansible, you can invoke `htop` over SSH using Docker
Machine on any given host like so:

```
$ docker-machine ssh queenbee -t htop
```

{{%img src="/images/ansible/htop.png" %}}

Don't forget to clean up the provisioning containers.  They shouldn't be left
around due to their highly privileged nature.

```
$ docker rm $(docker ps -aq --filter label=com.docker.compose.service=provision)
```

You have to restart the machines if you enabled memory accounting as well:

```
$ docker-machine restart queenbee workerbee-{1..3}
```

## Fun With Cross-Host Networking.

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
  mem_limit: "450m"
  ports:
    - "127.0.0.1:8080:8080"
  restart: always

follower:
  image: rethinkdb
  mem_limit: "450m"
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

For each running instance of the service, we reserve memory using a `mem_limit`
option of `450m` (megabytes). This ensures that the RethinkDB instances are
spread evenly across the cluster (the DigitalOcean servers in this walkthough
have ~500m- YMMV if you're using a different instance type). On the leader
node, we expose `8080` (the RethinkDB admin interface panel) to `localhost` of
the instance where it will end up.

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
policies with a maximum number of failures, and/or more robust entrypoint
scripts, may be a better option for real-world use cases.

Once you have this Compose file set up, ensure that your Docker environment
variables are set to talk to the Swarm master, then:

```
$ docker-compose --x-networking up -d
```

Once the `docker-compose up` finishes running, we can view the created services
like so:

```
$ docker-compose ps
       Name                     Command               State                       Ports
------------------------------------------------------------------------------------------------------------
mhswarm_follower_1   rethinkdb --join rethinkleader   Up      28015/tcp, 29015/tcp, 8080/tcp
rethinkleader        rethinkdb --bind all             Up      28015/tcp, 29015/tcp, 127.0.0.1:8080->8080/tcp
```

Note you can also see in `docker ps` the nodes where they were scheduled:

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                          PORTS                                                 NAMES
980a0eb54b86        rethinkdb           "rethinkdb --bind all"   20 seconds ago      Up 18 seconds                   28015/tcp, 127.0.0.1:8080->8080/tcp, 29015/tcp        workerbee-1/rethinkleader
f118f5d53f2e        rethinkdb           "rethinkdb --join ret"   22 seconds ago      Restarting (1) 20 seconds ago   8080/tcp, 28015/tcp, 29015/tcp                        workerbee-3/rethinkdb_follower_1
```

You can see as well that `docker-compose` created an `overlay` network named
`rethinkdb` automatically:

```
$ docker network ls | grep overlay
0456b3c548eb        rethinkdb                     overlay
```

You can then scale out to 3 total follower nodes (so, one instance of RethinkDB
per host):

```
$ docker-compose --x-networking scale follower=3
Creating and starting 2 ... done
Creating and starting 3 ... done
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                         PORTS                                                 NAMES
794b4a2549ec        rethinkdb           "rethinkdb --join ret"   57 seconds ago      Up 55 seconds                  8080/tcp, 28015/tcp, 29015/tcp                        workerbee-1/rethinkdb_follower_3
113a02566687        rethinkdb           "rethinkdb --join ret"   58 seconds ago      Up 56 seconds                  8080/tcp, 28015/tcp, 29015/tcp                        queenbee/rethinkdb_follower_2
980a0eb54b86        rethinkdb           "rethinkdb --bind all"   3 minutes ago       Up 3 minutes                   28015/tcp, 127.0.0.1:8080->8080/tcp, 29015/tcp        workerbee-2/rethinkleader
f118f5d53f2e        rethinkdb           "rethinkdb --join ret"   3 minutes ago       Restarting (1) 3 minutes ago   8080/tcp, 28015/tcp, 29015/tcp                        workerbee-3/rethinkdb_follower_1
```

RethinkDB comes with that very nice admin interface available at port 8080 of
the leader, so let's fork off an SSH tunnel to forward it to our client
computer's `localhost`.  Find which machine it's on (e.g. `workerbee2`), then:

```
$ docker-machine ssh workerbee-2 -fN -L 8080:localhost:8080
```

This way, we can open an SSH tunnel to the instance running in the cloud,
without needing to expose the port publicly on the Internet.  You should now be
able to access the RethinkDB admin console at `localhost:8080` on your local
workstation.

{{%img src="/images/ansible/rethink.png" %}}

See how it says "Servers / 4 Connected" in the above image?  They're all
running on different host nodes! Time to do some load testing.

You could expand to an arbitrary number of worker nodes as desired.  Just
`docker-machine create` like we did above and now you have access to as much
computing power as you're willing to go in for (or that the cloud providers can
handle, which is generally a lot).

## Exercises For The Reader

Some things to chew on:

- We used private networking to ensure that our key-value store wasn't
  accessible by the Internet at large, but it may be possible for naughty
  neighbor nodes we don't own in the same data center to access it.  What steps
  can we take to ensure that our key-value store, and its dependents, are
  properly secured and protected? _(hint: one possible answer begins with T and
  ends with S)_
- Design an application architecture based on this system which will
  automatically load balance new instances of an application as new containers
  are added.  Consider that reloading configuration for load balancers such as
  HAproxy can be a resource-intensive operation.
_([hint](http://www.slideshare.net/kobolog/ipvs-for-docker-containers))_
- Applications often rely heavily on knowing "secrets" such as API tokens.
  Describe a simple architecture for sharing and handling secrets with this
  model.  Your answer may not include the words "Vault", "Keywhiz", or "Sneaker".
- What can be done about stateful applications (e.g. databases) in this model?
  Sketch out a `docker volume` plugin which might help.  What kind of data
  structure might help with sharing business-logic (i.e. not meant to be kept in
  a key-value store) related information across nodes?
  _([hint](https://github.com/docker/docker/blob/master/docs/extend/plugins_volume.md)
  and [hint](http://kafka.apache.org/))_

# fin

Hope you have fun and learned something new.

Until next time, stay sassy Internet.

- Nathan
