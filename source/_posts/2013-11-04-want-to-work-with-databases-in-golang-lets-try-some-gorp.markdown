---
layout: post
title: "Want to work with databases in Golang?  Let's try some gorp."
date: 2013-11-04 18:58
comments: true
categories: 
---

# Google's Go

[Go](http://golang.org/) is a new programming language released by [Google](http://www.google.com).  It has an excellent pedigree (see [Rob Pike]() and [Ken Thompson]()) and it brings a lot of interesting things to the table as a programming tool. Go has been the subject of rave reviews as well as controversy.  Its supporters emphasize its [performance](), nifty approach to concurrency (it's [built right in]()), and fast compile times as advantages.  Since Google is a web company it's no surprise that Go seems hard-wired from the start to be used in the context of the modern web and the standard libaries include everything from [HTTP servers]() to [a templating system]() to address these ends.  A lot of companies seem to enjoy Go as a utility language that replaces components which used to be written in Python or Perl (with Go offering better performance).  Some of its detractors dislike its lack of exceptions and generics, but the purpose of this article is not to address these concerns, which have already been discussed *ad nauseum*.

Instead, this article will talk about and examine the `gorp` library.  I don't mean GOOD OLD RAISINS & PEANUTS, of course- I mean [gorp](), an "ORM-ish library for Go".  What is it, and how does it work its funny magic?

# ORM-ish?


