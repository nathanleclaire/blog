---
layout: post
title: "Using Ansible with Docker Machine to Bootstrap Host Nodes"
date: "2015-11-10"
comments: true
categories: [docker,machine,ansible,devops]
---

{{%img src="/images/ansible/ansibledockermachine.jpg" %}}

I'm a maintainer and big fan of [Docker
Machine](https://github.com/docker/machine) for quickly generating and using
Docker hosts in the cloud and elsewhere.  Creating and accessing machines,
however, is only the beginning of the battle, as most drivers will leave you
with a machine which is a relatively blank slate, and you may want to customize
the machines to your liking with a provisioning process of your own in addition
to Docker Machine's relatively thin provisioning.  For instance, we are likely
to want to turn on firewalls, add non-root users, install some software such as
[htop](http://hisham.hm/htop/) which helps with administration of the box, and
so on.  We could run a shell script on the created machine(s) using
`docker-machine ssh`, but for these types of boilerplate operational tasks I
prefer [Ansible](http://www.ansible.com/).  

### Basic Bootstrap

One option is to create the nodes we want to manage with Docker Machine and
then use an [Ansible dynamic inventory
plugin](https://github.com/nathanleclaire/dockerfiles/blob/master/ansible/machine.py)
to run our desired tasks.  Indeed, this seems like the best bet for managing
the configuration of the machines using Ansible in the long run.  But, for the
initial post-create provisioning, I could not get the idea out of my head of
simply running it within a Docker container on the created machine itself.
This would free us from needing Ansible and the stack of associated plugins
installed on our gateway box and kept up to date on whichever machine we were
bootstrapping from.

So how can we do so?  Well, it might not be the most elegant solution in the
world, but a fun hack is to:

- Run the container in the host's networking namespace.
- Generate an SSH keypair specifically for Ansible.
- SSH into the host from the container to do the provisioning.

## Dockerfile

This is the Dockerfile ([repo
here](https://github.com/nathanleclaire/dockerfiles/tree/master/ansible)) for
this trick:

<pre>
from debian:jessie

run apt-get update && \
    apt-get install -y ansible ssh && \
    rm -rf /var/lib/apt/lists/*
add ./machine.py /machine.py
add ./playbooks /playbooks
add ./conf/ansible.cfg /etc/ansible/ansible.cfg
add ./entrypoint.sh /entrypoint.sh
entrypoint ["./entrypoint.sh"]
cmd ["/playbooks/bootstrap.yml"]
</pre>

You can see that it installs Ansible and SSH, as well as adds in the files that
we will be needing (such as Ansible playbooks and configuration files).  The
Docker Machine inventory plugin is also copied in for kicks, so that this image
could also potentially be used to follow up with after the initial bootstrap to
manage the created machines as well.

Likewise, this basic image is fairly customizable. I have it on Docker Hub as
[nathanleclaire/ansibleprovision](https://hub.docker.com/r/nathanleclaire/ansibleprovision).
It could easily be extended by creating a new repo with a Dockerfile and a
desired Ansible playbook to run, where the Dockerfile's contents are something
like:

<pre>
from nathanleclaire/ansibleprovision
add ./custom.yml /playbooks/custom.yml
cmd ["/playbooks/custom.yml"]
</pre>

## Entrypoint script

What's up with that entrypoint script? Well, it runs through the trick outlined
above.

```
#!/bin/bash

if [[ ! -d /hostssh ]]; then
    echo "Must mount the host SSH directory at /hostssh, e.g. 'docker run --net host -v /root/.ssh:/hostssh nathanleclaire/ansible"
    exit 1
fi

# Generate temporary SSH key to allow access to the host machine.
mkdir -p /root/.ssh
ssh-keygen -f /root/.ssh/id_rsa -P ""

cp /hostssh/authorized_keys /hostssh/authorized_keys.bak
cat /root/.ssh/id_rsa.pub >>/hostssh/authorized_keys

ansible-playbook -i "localhost," "$@"

mv /hostssh/authorized_keys.bak /hostssh/authorized_keys
```

You can see that we expect the host's SSH configuration directory (usually
`$HOME/.ssh`) bind mounted in to `/hostssh` in the container.  A SSH keypair is
generated, intended for use with Ansible, and added to the host machine's
`authorized_keys` public key file. The original `authorized_keys` file is
"backed up" so that it can be restored at the end of the script.

Following this, the `ansible-playbook` command is invoked on `localhost` with
the `CMD` of the created image as arguments (by default,
`/playbooks/bootstrap.yml`).  Consequently, the playbooks are run on the host
from within the container.

## Ansible playbook

Following is a simple Ansible playbook (the aforementioned `bootstrap.yml`) I
have been using, feel free to riff on it and innovate more.  It is simply
intended to take care of some basic system administration tasks which should be
done to lock down the server somewhat and make it more pleasant to
administrate.  I'm sure it could be improved upon, so I'd love to hear your
ideas in the comments.

<pre>
---
- name: Trick out Debian server
  hosts: all
  gather_facts: False

  tasks:
    - name: Install desired packages
      apt: >
        package={{ item }}
        state=present
        update_cache=yes
      with_items:
        - htop
        - tree
        - jq
        - fail2ban
        - vim
        - mosh
        - ufw

    - name: Get simple .vimrc
      get_url: url=https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/basic.vim dest=/root/.vimrc

    - name: Reset UFW firewall
      ufw:
        state=reset

    - name: Allow SSH access on instance
      ufw: >
        rule=allow
        name=OpenSSH

    - name: Open Docker daemon, HTTP(S), and Swarm ports
      ufw: >
        rule=allow
        port={{ item }}
        proto=tcp
      with_items:
        - 80     # Default HTTP port
        - 443    # Default HTTPS port
        - 2376   # Docker daemon API port
        - 3376   # Swarm API port
        - 7946   # Serf port (libnetwork)
     
    - name: Open VXLAN and Serf UDP ports
      ufw: >
        rule=allow
        port={{ item }}
        proto=udp
      with_items:
        - 7946 # Serf
        - 4789 # VXLAN

    - name: Set to deny incoming requests by default
      ufw: >
        default=deny

    - name: Turn on UFW
      ufw: >
        state=enabled

    - name: Set memory limit in GRUB
      lineinfile: >
        dest=/etc/default/grub
        regexp=^GRUB_CMDLINE_LINUX_DEFAULT
        line='GRUB_CMDLINE_LINUX_DEFAULT="cgroup_enable=memory swapaccount=1"'

    - name: Load new GRUB config
      command: update-grub
</pre>

Let's face it, `htop` is ridiculous amounts of fun, and I want it on all my
servers.  I know some will protest at installing software on the host machine
instead of running it in containers, and naturally I admire the zealotry, but
when the Docker daemon crashes or containers start spinning out of control for
unforeseen reasons, personally I appreciate the escape hatch.

Likewise, check out those last two tasks above.  They enable memory and swap
accounting so that Docker's `-m` flag can be used (note that the machine has to
be rebooted for this change to take effect, which you can do with
`docker-machine restart name`).  This is critical for operations such as
reserving memory for containers using Docker Swarm and is exactly the type of
boring boilerplate systems administration task that Ansible excels at making
easier and safer.

## Let's cook

{{%img src="/images/ansible/console.png" %}}

Now that we have our "ingredients" together, we can start "cooking".  Let's do
the abovementioned process on a [DigitalOcean
server](https://digitalocean.com). I'll use an image generated from the
Dockerfile mentioned above for shorthand, but you can also build your own from
the linked repo.

```
$ export DIGITALOCEAN_ACCESS_TOKEN=...
$ docker-machine create -d digitalocean ansibleprovision
...

$ eval $(docker-machine env ansibleprovision)
$ docker run \
    --rm \
    --net host \
    -v /root/.ssh:/hostssh \
    nathanleclaire/ansibleprovision
...

$ docker-machine ssh ansibleprovision ufw status
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
2376/tcp                   ALLOW       Anywhere
3376/tcp                   ALLOW       Anywhere
7946/tcp                   ALLOW       Anywhere
7946/udp                   ALLOW       Anywhere
4789/udp                   ALLOW       Anywhere
OpenSSH (v6)               ALLOW       Anywhere (v6)
80/tcp                     ALLOW       Anywhere (v6)
443/tcp                    ALLOW       Anywhere (v6)
2376/tcp                   ALLOW       Anywhere (v6)
3376/tcp                   ALLOW       Anywhere (v6)
7946/tcp                   ALLOW       Anywhere (v6)
7946/udp                   ALLOW       Anywhere (v6)
4789/udp                   ALLOW       Anywhere (v6)
```

## Bonus Round: Using Docker Compose to simplify the process

{{%img src="/images/ansible/combo.jpg" %}}

Remembering the command lines options listed above for the `docker` client can
be somewhat cumbersome if we are doing it a lot.  Let's take those and turn
them into a service in a Docker Compose file.

```
provision:
  image: nathanleclaire/ansibleprovision
  net: host
  volumes:
    - /root/.ssh:/hostssh
```

Then, instead of the lengthy `docker run` invocation above, if we have
`docker-compose` installed we can simply run:

```
$ docker-compose run --rm provision
```

Boom!

# fin

I know it's somewhat oddball considering the general workflow expected out of
Ansible users, but I find this type of provisioning / bootstrapping process
really fun and somewhat refreshing.  In the future, perhaps an extremely
lightweight container-specific type of provisioning software which is intended
to be used this way could emerge to enable this type of workflow.  Looking even
further out, the need for traditional provisioning might shrink into the
horizon as minimalistic Docker-focused operating systems such as
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
