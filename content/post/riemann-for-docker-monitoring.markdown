---
layout: post
title: "Riemann for Docker Monitoring"
date: "2015-11-23"
comments: true
draft: true
categories: [riemann,clojure,docker,monitoring]
---

## Riemann

We can run `Riemann`, a wonderful monitoring system written by Kyle Kingsbury,
to aggregate events and monitor the created instances.  We need some extra
resources to host the Riemann server, so let's spin up another, beefier
instance:

```
docker-machine create \
        -d digitalocean \
        --swarm \
        --swarm-discovery="consul://${KV_IP}:8500" \
        --digitalocean-size 2gb \
        --engine-opt="cluster-store=consul://${KV_IP}:8500" \
        --engine-opt="cluster-advertise=eth1:2376" \
        riemann
```
