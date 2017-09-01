---
layout: post
title: "The Good, The Bad, and The Ugly of Sails.js, Realtime JavaScript MVC Framework"
date: "2013-12-28"
comments: true
url: "/blog/2013/12/28/the-good-the-bad-and-the-ugly-of-sails-dot-js-realtime-javascript-mvc-framework/"
categories: [node.js,mvc,socket.io,rails,sails,javascript,server]
---

Over the Christmas vacation time that I've been taking I've been finding myself drawn back to [Node.js](http://nodejs.org/), mostly for the promise of rapid web application development and not having to switch languages when changing from working on the server-side and the client-side.  As part of my interest in developing applications using [WebSockets](http://www.html5rocks.com/en/tutorials/websockets/basics/) for their real-time capabilities, I looked into [Derby](http://derbyjs.com/) and [Meteor](https://www.meteor.com/) and eventually I stumbled across [Sails.js](http://sailsjs.org/), the new kid on the block.  It seemed very promising and addressed some issues that I had with Derby and with Meteor.  Namely, both of those frameworks seem very tightly coupled from the client to the server and I wanted something that would provide more flexibility while still allowing me to develop rapidly.  So, I decided to begin prototyping out my new side project in Sails and naturally I developed a variety of opinions to rant about.  Enjoy.

{{%img src="/images/sails/clint-eastwood.jpeg" caption="My face when developing. " %}}

# The Good

{{%img src="/images/sails/thegood.jpeg" caption="" %}}

[Sails.js](http://sailsjs.org/#!) makes getting things started ridiculously quick.  You run `sails new myApp` to create the application skeleton.  Then, to create a Controller and Model for some data that you're going to be working with, you run `sails generate foo` (`foo` being the name of your model).  You configure the model really simply:

```js
module.exports = {
    adapter: 'sails-redis',
    attributes: {
        content: 'string',
        userName: 'string',
        userId: 'int',    // "foreign key"
        chatroomId: 'int' // "foreign key"
    }
};
```

Sails uses [Waterline](https://npmjs.org/package/waterline) as its ORM, and it provides a lot of power for developing rapidly.  The `adapter` field dictates where the data will be stored, and you can mix and match, so you can have some models stored in MySQL and others in Redis, for instance.  I think this is a really cool feature.  You can set validation, etc. on them.  You can write custom methods on your models to extract "higher-order" data from them.  Best of all, just having a model gets you a ton of routes (CRUD blueprints and REST endpoints) out of the box (and they [all work with Websockets](http://sailsjs.org/#!documentation/sockets)!):

```
# Backbone Conventions
GET   :    /:controller                 => findAll()
GET   :    /:controller/read/:id        => find(id)
POST  :    /:controller/create          => create()
POST  :    /:controller/create/:id      => create(id)
PUT   :    /:controller/update/:id      => update(id)
DELETE:    /:controller/destroy/:id     => destroy(id)

# You can also explicitly state the action
GET   :    /:controller/find            => findAll()
GET   :    /:controller/find/:id        => find(id)
POST  :    /:controller/create          => create(id)
PUT   :    /:controller/update/:id      => update(id)
DELETE:    /:controller/destroy/:id     => destroy(id)
```

So, for instance, if you run `sails lift` to start your app, hitting 

```
http://localhost:1337/something/create?content=hello&userName=Nate&userId=1&chatroomId=1
```

will add a new instance of the model to your datastore.  We did nothing manually to address this (so long `$_GET` and `$_POST`, it's been... okay).  And you can see everything that's been added at `localhost:1337/something/` without having to configure anything, althogh Sails makes it easy to change things around to your heart's content by setting properties in the Controller and `config/routes.js`.

Underneath the slick outer layer, Sails uses a lot of well-known and proven modules, most notably [Express](http://expressjs.com/), and it makes it easy to reach to the underlying layer to configure things / do something specific/different (but does not awkwardly leak abstractions).  Additionally, serving of static assets never gave me any trouble and I just added new folders when I needed them.  Not having to worry about this was really nice when developing with [Angular](http://angularjs.org/), which mandates a lot of client-side includes.

In summary:

- Database-agnostic ORM that is simple, but powerful and flexible as well
- Developing routes / REST APIs is ridiculously fast - writing tiny amounts of code gets you a ton! (including WebSockets support)
- Lots of stuff "just works" without making you think about things too much, but Sails does not try to conceal with "magic"
- The Sails.js team has done a really good job of laying things out well to be extensible- and they have well-thought-out solutions that address many common issues e.g. [policies](http://sailsjs.org/#!documentation/policies)

# The Bad

{{%img src="/images/sails/thebad.jpeg" caption="" %}}

Sails is a young framework so sometimes issues come up that can be frustrating to address (since there are not that many users yet, therefore there are not that many resources on StackOverflow etc.).  For instance, when I wanted to start using Redis as a datastore for chat room comments, I tried running `npm install sails-redis`.  This seemed to go off without a hitch but when I ran `sails lift` I got an error indicating that the `sails-redis` module could not be found.  It was very bizarre but then I tracked down [this Github issue](https://github.com/balderdashy/sails-redis/issues/3) which pointed out there was no source code in the npm package!!  I was able to install the package from GitHub but it was very frustrating to blow time on something like that when ostensibly the framework allows you to develop rapidly.

For me personally (and I think [others share the sentiment](https://github.com/balderdashy/sails/issues/1239)) I think that generators should also provide you with unit test skeletons, and that Sails should address this concern a lot better.  If it's going to be production-ready top-notch support for testing will be pretty critical.  I wouldn't want to deploy an application that didn't have at least some unit tests, especially for mission-critical parts of the app.  As it stands right now it's not really clear how to test your Sails application.  We need a `sails test` command and documentation in this regard!

For a framework that touts performance as a major benefit, I find that `sails lift` takes a pretty long time to start up (granted, it is doing a lot - if you run it with `--verbose` option you can see all of the route binding etc. it is doing).  This would be okay if you only had to do it once, but every time you change things (models, controllers, routes, etc.) you have to stop and start `sails lift`.  So, to have either code hot-swapping or a `sails lift` that starts up lightning-fast would make Sails much more pleasant to use.  I'm curious if performance can be improved in this regard.

The documentation, particularly when it came to using [Sockets](http://sailsjs.org/#!documentation/sockets), was hard to understand as someone who is a newcomer to [socket.io](http://socket.io).  Their included `app.js` didn't really clarify things too well, and so I had to rely on [this example from NetTuts](http://net.tutsplus.com/tutorials/javascript-ajax/working-with-data-in-sails-js/) to make sense of how to accomplish what I was trying to do.  So I think you could say that the documentation, though absolutely stellar in some areas, could use some bit of work.

In summary:

- Since it is new, it can cause frustrating problems you will likely never run into with Django etc.
- In my opinion generators should also include tests (at least make it optional)
- Documentation is lacking in some ways
- `sails lift` takes longer than I'd like to start up and has to be restarted frequently

# The Ugly

{{%img src="/images/sails/theugly.jpeg" caption="" %}}

At the time of writing, [their build is listed as not passing on TravisCI](https://travis-ci.org/balderdashy/sails), and the sticker on their Github page says so.  That doesn't exactly send the right kind of message you want to send with your project.  Now, be aware that I cloned the repository and ran all of the tests locally, and they all passed with Node `v0.10.24` and `v0.11.9`, but not with a previous version of `v0.10.*` that I had (can't remember which unfortunately).  So, perhaps it's more of a TravisCI / versioning issue than a Sails issue, but I think that's a big public-facing thing to overlook.

Something that's really unfortunate about [Waterline](https://github.com/balderdashy/waterline), the aforementioned ORM that Sails uses, is that it does not support associations (relational data) at the moment.  This seems like a really huge issue / something that I would expect to be a huge cornerstone of any ORM to not have support for right away, and it was really frustrating to find out midway through starting to put together an app that has a lot of relational data.  That being said, they are [aware of the issue](https://github.com/balderdashy/sails/issues/124) and are working to fix it, but I really want my `JOIN`s available for working with in the framework I'm using *now*, without having to use an unstable/bleeding-edge pre-release version of Waterline.  In order to do so right now in Sails I have to use `Model.query`, which is kind of awkward (plugging in raw SQL).  Having to code up things one way as a workaround and then go back and rip them out for official associations when they're supported is really a turn off.    I kind of wonder if it's not partially a result of NoSQL/MongoDB being very hot right now and developers not giving as much love to traditional relational things as they might have in the past.  Since it's an area of interest for me I'd like to contribute but other than a few guidelines in `CONTRIBUTING.md` there's not much communication from the core devs on this front.


A lot of what is rough around the edges about Sails right now is summed up really well in this [Github pull request comment](https://github.com/balderdashy/sails/pull/1058#issuecomment-30498745) by [yoshuawuyts](https://github.com/yoshuawuyts):

> I know you've been very busy, but I feel I need to share this. As much as I've enjoyed Sails in the past, right now I feel very disconnected from it. For me the amount of outdated documentation, piling issues on the tracker and unclear direction make it hard to keep investing into Sails. The prolonged absence of core members like yourself and delayed responses on most issues make it hard to keep investing. If you want to lead Sails forward, I urge you to invest in clarity.

His suggestions for improvement:

- Rigorous issue smackdown; close everything that isn't relevant, combine duplicates into new issues.
- Create a roadmap; add all feature suggestions to the roadmap and close corresponding issues.
- Add code coverage via coveralls; it entices users to write more tests and fill up the bar.

And a very good point:

> I don't think you should prioritize getting new contributors in, I think they'll come naturally once the points above have been addressed.

After working with Sails for a week or so, I agree heartily with his take.

In summary:

- Build is broken on TravisCI at the time of writing
- No support for associations (though they are coming)
- Issues on Github are piling up without being addressed
- Devs have not been very responsive lately (ever?)

# Conclusion

I don't want the Sails team to feel like I'm ragging on them, they've done awesome work and I really feel like Sails has a great future if it can take care of some of the things I've brought up in the past two sections.  I know that when everything was running smoothly developing with Sails it was pure bliss on my end.

For those readers interested or with a bunch of time on thier hands, it would be great to have people throw a bunch of pull requests Sails' way, since I sort of have a feeling that they are overwhelmed by the sheer scope of the project.  However, if the core developers don't start piping up soon, it's going to be hard to maintain interest / continue to invest my own valuable time and willpower into the project.  It has a ton of potential and in my opinion the vision, fully implemented and fleshed out, would be truly amazing.

So that's my take on Sails.js.  Happy New Year, I hope you enjoyed.  Until next time, stay sassy Internet.

- Nathan

*EDIT:* I absentmindedly pushed with a bunch of broken links.  Fixed now, sorry guys.
