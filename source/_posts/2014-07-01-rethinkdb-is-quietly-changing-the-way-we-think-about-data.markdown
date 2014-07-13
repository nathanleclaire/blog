---
layout: post
title: "RethinkDB is Quietly Changing the Way We Think About Data"
date: 2014-07-01 23:10
comments: true
categories: [databases,rethinkdb,data,nosql]
---

# meet up

This past week I attended a meetup at [Firebase](http://firebase.io) headquarters in downtown San Francisco.  No joke, there is photographic evidence.

{%img /images/rethinkfire/meetup.jpeg Me! %}

It was a very intruiging event since the focus of the conversation was on building real-time apps, and what the future of that is going to look like.  Essentially real-time apps are websites or native device applications where the interaction with other users is nearly instantaneous.  For instance, if you've ever edited a Google Doc at the same time as someone else, you will recall that you could see changes that they made in real-time, and vice versa, and so on.

There were a lot of great speakers, including Sara Robinson from [Firebase](http://firebase.io) and Vincent Woo from [CoderPad](http://coderpad.io), but here I'm going to discuss a little about what RethinkDB demoed.

In case you're not familiar, [RethinkDB](http://rethinkdb.com) is a JSON data store similar in some ways to [MongoDB](http://mongodb.com).  The comparison has been done to death so I won't rehash as it's easy to [Google](http://lmgtfy.com/?q=difference+between+rethinkdb+and+mongodb), I want to talk here about some new features that RethinkDB has been introducing which I find very innovative.

# http as a query (HaaQ)

{%img /images/rethinkfire/rethinkquer.gif %}

RethinkDB just introduced a new feature that allows users to query APIs directly from their "Data Explorer" view (which is amazingly cool by the way, you should check it out - I really wish there was a demo of it online for people to play with).

It's called `http` and it's a part of ReQL, their query language.  What it does is connect to a remote server to retrieve JSON, which you can then dump into RethinkDB directly and/or query with a very expressive query language (the ReQL API is based on JavaScript so it contains many familiar patterns, however there are many bindings for other languages as well).  This task traditionally is done using a scripting language like Ruby, Perl, or Python to keep the feedback loop tight, but being able to do it directly from Rethink makes the feedback loop even tighter.

I suspect this sort of mutation will be a winning one in the end.  Just thinking about the possibilities, it reminded me of many times where I had to do some sort of straightforward data manipulation task based on external data and I was forced to reach for Python et al. for their networking capabilities.  It's really interesting to, say, be able to very quickly access information from APIs such as who are the top committers for your project on GitHub, what are your most popular submissions to [/r/javascript](http://reddit.com/r/javascript), and so on, and then query that information in a very richly interactive and intuitive manner.

Expect to see more http-as-a-query (HaaQ) and similar features popping up in technologies the future.

# changefeeds

Now this is really fascinating.  You can set a query so that, when changes occur to it, your program gets notified.

Why is this useful?  For starters, a given client can subscribe to be notified when a value changes with another user (their score increased, they got further along the map, they typed something in to the document, etc.).

```python
feed = r.table('users').changes().run(conn)
for change in feed:
    print change
```

I imagine doing this in a Goroutine or a similar type of lightweight thread.

And perhaps more interestingly, you can also subscribe to just a certain kind of event (e.g. the user's gotten a new high score):

```python
r.table('scores').changes().filter(
    lambda change: change['new_val']['score'] > change['old_val']['score']
)['new_val'].run(conn)
```

Nice!  In the kind of industry sweep that we're seeing towards applications which are reactive (I think of them as "springy" or "spongey") vs. applications which are sluggish and imperative, this kind of feature will prove invaluable.  I'm especially keen to see when they have it working with aggregate functions (if I recall correctly eventually it will work with any function parallelizable with Map/Reduce).  Imagine getting notifications every time some kind of complex-to-calculate performance metric changed, or a real-time visualization of data that is constantly being re-crunched on the fly.

# fin

I was really impressed with Rethink's new features and I think they represent a bold new direction for things.  It would have been easy to play it safe and stick to existing features but instead Rethink is really trying to shake things up around how we think about data : storing it, querying it, and delivering it to the end user in real-time.

Until next time, stay sassy Internet.

- Nathan
