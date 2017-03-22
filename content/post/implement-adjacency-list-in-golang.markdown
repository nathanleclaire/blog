---
layout: post
title: "Implement Adjacency List in Golang"
date: "2016-07-05"
comments: true
draft: true
categories: [golang,adjacency list]
---

Recently in "Programming Pearls" I came across the idea of an _adjacency list_
data structure.

Adjacency lists are a way of representing a sparse graph (adjacency matrix) in
a much more space efficient manner than the obvious solution of using a
multi-dimensional array.

Backing up for a second, we know that an adjacency matrix is a way we could
model relationships between vertices in a graph.  Each value in the matrix
indicates whether or not the vertex has a link to another vertex in the graph.
Both directed and non-directed graphs can be represented this way, e.g.:

```
graph := [][]int{
    {0, 1, 0, 0, 0}, // 0
    {1, 0, 0, 1, 1}, // 1
    {0, 0, 0, 0, 0}, // lonely 2
    {0, 1, 0, 0, 0}, // 3
    {0, 1, 0, 0, 0}, // 4
}
```

represents:

![](/images/graphs/0.png)
<center>_This graph is undirected._</center>

This works well for small graphs, but keeping track of all those connections
takes up O(n<sup>2</sup>) space. A non-quadratic solution to this problem would
be much better as our data grows larger.

If each node does not have a lot of connections to other nodes to track, this
can become wasteful.  Such data is called _sparse_ data.  To efficiently store
this data we could consider a structure called _adjacency lists_.  Let's
implement one in Golang.

## Structure

Our structure depends on the properties of our data and the solution we want to
optimize for.  For here, let's pretend we want to model some relationships
between followers and follow-ees on the social networking website
[twitter.com](https://twitter.com/dotpem).
