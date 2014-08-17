---
layout: post
title: "Automagical Deploys from Docker Hub"
date: 2014-08-16 22:52:12 -0700
comments: true
categories: [docker, hub]
---

> I want the speed and other advantages of a static site generator, with the flexibility of a database-backed CMS.

{%img /images/automagic-dockerhub/hub.png %}

# I want performance, flexibility, and ease of maintenance.

Business and individuals in the modern world have to make a carefully weighed set of trade-offs between flexibility and performance in a lot of cases, and generating content for your readers and fans on the web is no exception.  Geeks have embraced static site generators such as Jekyll as all the rage in recent years, and for good reason, as these systems provide a lot of advantages (deploy straight to Github pages, performance, and keeping your content in version control spring to mind).  However, they are not without their own challenges.

A flexible, database-backed content management systems such as Wordpress can still be a better choice in some situations.  It's very nice to have the flexibility for non-technical people to also edit and update content, and for authors to edit online from anywhere without needing a special suite of software.  However, CMSes such as Wordpress are slow, temperamental, and hard to optimize.

Lately I've been trying to find a good balance for my website.  I LOVE that people from the community can make pull requests on it from Github, and it's helped me to clean it up tremendously, and I also value the performance and general ease of maintenance from just serving up static files using Nginx.  However, using Jekyll (especially on new computers) is a real pain - my stack is based on Octopress and gives me a lot of heartaches due to my general newbishness around the Ruby ecosystem and some not-so-great design decisions I made early on.  Additionally, if I merge in a minor change on Github I have to fetch the changes to a local computer where Octopress is set up to perform correctly, re-generate the site using some `rake` commands and then deploy it again.  Not immensely difficult, but not trivial either, and if I am catching small mistakes every day and I want to keep the blog in sync instead of letting it slip the time to regenerate and re-deploy the site starts to add up quickly.  Usually I just let things slip, including keeping the changes up to date on Github.  Not to mention that Github's online markdown editor is **nice**.

# Game on.

So what to do?  Well, lately I've been thinking that I could chain some automation systems together and deploy directly from an automated build on [Docker Hub](http://hub.docker.com) using the great [Web Hooks]() feature.  This would allow me to trigger a re-build and re-deploy of the blog when there is a change in source control on master, and it would all run asynchronously without needing my attention.  The best part is, this technique could be applied to other stacks and other static site generators to roll a solution which fits your needs no matter what you're building.

To do so we will:

1. Build a `Dockerfile` to compile the latest static site from source using our chosen stack (Octopress in my case)
2. Set up an automated build on Docker Hub which will re-build the image from scratch whenever a change is made on Github (including merges and the online editor)
3. Use Docker Hub Web Hooks to make a `POST` request to a small ["hook listener" server](https://github.com/cpuguy83/dockerhub-webhook-listener) running on my Linode which re-deploys the new image (props to [cpuguy83](https://github.com/cpuguy83) for this)

## Step 1: Build a `Dockerfile` for our static site generator

This is my Dockerfile for this Octopress build:

```
from debian:wheezy

run apt-get update && \
    apt-get install -y curl build-essential

run apt-get install -y ruby1.9.3
run apt-get install -y lsb-release && \
    curl -sL https://deb.nodesource.com/setup | bash
run apt-get install -y nodejs npm
run apt-get install -y nginx
run gem install bundler

add Gemfile /blog/Gemfile
workdir /blog
run bundle install -j8

add . /blog


run rake install['pageburner'] && rake generate
run rm /etc/nginx/sites-available/default
add nginx/nathanleclaire.com /etc/nginx/sites-available/nathanleclaire.com
run ln -s /etc/nginx/sites-available/nathanleclaire.com /etc/nginx/sites-enabled/nathanleclaire.com

run echo "daemon off;" >>/etc/nginx/nginx.conf

expose 80

cmd ["service", "nginx", "start"]
```

Apparently Jekyll has a Node.js dependency these days.  Who knew?  Side note:  Writing my Dockerfiles in all lowercase like this makes me feel like e e cummings.  A really geeky e e cummings.

This Dockerfile is really cool because the `bundle install` gets cached as long as the Gemfile doesn't get changed.  So, the only part that takes non-trivial time in the `docker build` of the image once it's been built once is the `rake generate` command to spit out the final static site, so it runs quite quickly (unfortunately Highland, Docker's automated build robot, doesn't cache builds though).  

I would love to see some more of these for various static site generating stacks, and I intend to contribute just a vanilla Octopress / Jekyll one at some point.

Octopress is pretty rude about working with only Ruby 1.9.3., so fortunately I was able to find a Debian package to fit my needs on that front.  The static files get served up with nginx on port 80 of the container (which I just proxy to the host for now), which works well for my purposes.  In fact, I just have all the gzip and other per-site (caching headers etc.) settings in the nginx config in the container, so I can deploy that this way too (just change the source in the repo and push to Github!).  I like this kind of high-level-ops knowledge PaaS fusion mutated weirdness.  Yum.

It cuts my "native" sites-available file for the websites down to something like:

<pre>
server {
  server_name nathanleclaire.com;

  location / {
       proxy_pass http://localhost:8000;
  }

  location /hubhook {
      proxy_pass https://localhost:3000;
  }
}
</pre>

The `/hubhook` is some proxy-matic goodness, which farms out the task to re-deploy the site to a simple but effective "Docker Hub Listener" worker that my colleague Brian Goff originally wrote (and I twisted to my own nefarious purposes, muahaha).  Enter the next couples of steps.

## Step 2: Set up Automated Build for this repo on Docker Hub

This step is crucial, and really illustrates the power and flexibility of Hub's automated builds (which if you haven't tried already, you *totally should*).  When a change (commit, merge or otherwise) hits the `dockerize` branch on Github (though it could be any branch, and eventually it will be master for me), it triggers a re-build of the images with the most up-to-date Dockerfile.  This means that new articles I have written or content that I have added will be re-built asynchronously by Highland without needing any attention from me.  So, even if I merge in a small change from another user on Github or make a quick edit with the online editor, the site will be rebuilt from source (mostly Markdown files and a "theme" template).  Automated builds work with Bitbucket too if you prefer Bitbucket!!

And, crticially, Docker Hub offers a feature called Web Hooks which will make a `POST` request to the endpoint of your choice whenever a new build is complete.  So, we can use this to re-deploy the website.

## Step 3: Post to the hook listener server and re-deploy!

I had been kicking around the idea of implementing something like this for a while, but I was missing a piece.  I had no server to listen for the request from Docker Hub when the build was completed.  Then, serendipitously, my colleague Brian Goff (also known as [cpuguy83](https://github.com/cpuguy83), a very helpful community member) demoed the very thing that I was thinking of writing myself (only his was more well thought out, if I'm being honest).  It's a tiny little Golang program which allows you to register handlers to run when the hook hits, and has support for self-signed SSL (so that you can send the request with encryption / `https` from Docker Hub) and API keys (so that even if people know the endpoint to hit, they won't know the API key to pass to actually get it to do anything).

Link to the repo here:

- [https://github.com/cpuguy83/dockerhub-webhook-listener](https://github.com/cpuguy83/dockerhub-webhook-listener)

To get it to work, I generated an OpenSSL key and cert (which I linked to in a `config.ini` file passed to Brian's server program).

I wrote this script to automate that key/cert generation:

<pre>
#!/bin/bash

openssl genrsa -des3 -out server.key 1024 && \
  openssl req -new -key server.key -out server.csr && \
  cp server.key server.key.org && \
  openssl rsa -in server.key.org -out server.key && \
  openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
</pre>

Then I generated a random API key and also added it to the config file.

Lastly, I wrote a simple shell script to run whenever the hub hook listener received a valid request, and wrote a Go handler to invoke it from Brian's server program.

The shell script looks like this:

<pre>
#!/bin/bash

sudo docker pull nathanleclaire/octoblog:latest
docker kill blog
docker rm blog
docker run --name blog -d -p 8000:80 nathanleclaire/octoblog
</pre>

Just keeping it simple for now.

The Go code like this:

```go
func reloadHandler(msg HubMessage) {
  log.Println("received message to reload ...")
  out, err := exec.Command("../reload.sh").Output()
  if err != nil {
    log.Println("ERROR EXECUTING COMMAND IN RELOAD HANDLER!!")
    log.Println(err)
    return
  }
  log.Println("output of reload.sh is", string(out))
}
```

As you can see, there's nothing too fancy here.  It's just Plain Old Golang and Shell Script.  In fact, it could be a lot more sophisticated, but this works just fine- which is part of what pleases me a lot about this setup.

So, pieced together, this all works.

1. Commit hits Github
2. Docker Hub builds image
3. Docker Hub hits middleware server with hook
4. Server pulls image, and restarts the server

# Automagical.

Now my deploys go seamlessly from source control push.  I really enjoy it since now that everything is set up it will work smoothly without needing any manual intervention from me (though I need additional logging and monitoring around the systems involved to ensure their uptime and successful operation, mostly the hub hook listener - *am I slowly turning into a sysadmin?  NAH*)  

There is still a lot of room for improvement in this setup (mostly around how Docker images get moved around and the ability to extract build artifacts from them, both of which should improve in the future), but I hope I have stimulated your imagination with this setup.  I really envision the future of application portability as being able to work and edit apps anywhere, without needing your hand-crafted pet environment, and being able to rapidly deploy them without having to painstakingly sit through every step of the process yourself.

So go forth and create cool stuff, then tell the world.  And until next time, stay sassy Internet.

- Nathan
