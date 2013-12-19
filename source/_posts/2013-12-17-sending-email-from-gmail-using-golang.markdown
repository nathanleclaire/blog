---
layout: post
title: "Sending Email From Gmail Using Golang"
date: 2013-12-17 23:38
comments: true
categories: [Email, Golang, SMTP]
---

As part of the recently deployed [checkforbrokenlinks.com](checkforbrokenlinks.com) app, I found myself faced with the task of creating a contact form that would allow users to send me feedback on the app, so I could improve it and make it better in the future.  In order to do so I had to figure out a way to configure my server-side backend, written in Golang, to perform all of the neccessary steps in order to send me an e-mail from the front-end (written in [AngularJS](angularjs.org)).  Looking into it, I don't see too many e-mail sending implementations in Golang available easily online, so I'm putting the results of my research out there for all to see.

# `net/smtp`

Golang provides a language 


