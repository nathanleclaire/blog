---
layout: post
title: "AngularJS isn't MVC, it's SDC"
date: 2014-03-15 12:38
comments: true
categories: [angular,javascript,mvc,service,directive,controller]
---

# Intro

{%img /images/notmvc/angular-homepage-old.gif %}

I first started learning AngularJS because I was interested in exploring the world of MV&#42; JavaScript frameworks for the client side.  There was something intruiging and exciting happening about a year or two ago in that space, as several JS frameworks started to get some steam and critical mass and the mainstream of client-side development (even those boring [5:01 developers](http://www.hanselman.com/blog/501DevelopersFamilyAndExcitementAboutTheCraft.aspx) couldn't ignore the zeitgeist anymore) seemed to wake up and realize that maybe there was a need for something more than just vanilla jQuery in applications where everything was spiraling way out of control.

So I started looking into Angular for the myriad reasons you usually hear people cite as a reason for using it.  It was backed by Google.  It was easy to get going quickly.  The quality of documentation and tutorials, though not fantastic, was starting to improve relative to Ember or more obscure frameworks.  It was fun.

My first foray went down in flames.

{%img /images/notmvc/javascript.png %}

I fell into a common Angular antipattern (I may discuss Angular antipatterns more in a future article) where I stuffed everything into the controller.  Services and directives looked a little scary, and required learning esoteric things like what the meaning of `@`, `&`, and `=` was in a directive, and instead I saw fit to simply stuff everything into `$scope` and coordinate activities using event broadcasting and listening.

That project became so un-fun to work on that I just stopped.  I had dug myself into a hole deeper than I would ever get out of without a complete rewrite.

Fortunately, partially through writing about Angular a lot, I eventually wised up.

I learned that Angular is structured in some ways that are similar to what we have experienced before, but it also hearkens a little bit to the future of the client side (see [Web Components](http://www.w3.org/TR/components-intro/)).  And because of that, it had a little bit of new stuff too that threw me.

You may be used to the Model View Controller pattern- but that's not what Angular is.   A subsection of it kind of looks like that, but if you take a step back you will see a bigger picture emerge.

Angular is Service, Directive, Controller.

# The Angular Way

Angular is all about testability, and testability mandates that we be able to break our application into components.  In most cases, monoliths are considered harmful.  You probably understand why if you've ever worked on one.  Things become too brittle and easy to break.  They become tightly coupled.  It's impossible to change codes without introducing bugs in unrelated places.  And so on.

Angular draws lines between separate parts of the architecture so that you can avoid many of these headaches.  In particular, dependency injection treats us well, as we rely on Angular's injector to provide us with the things that we need instead of getting them ourselves.  This also allows us more control over how they are provided, which eases testing significantly (the developer has a smaller surface area that he needs to control).

Most applications use these underlying principles to do three things: Retrieve, process, or send out data (usually communicating with the "outside world" such as a database or API), present (display) that data to the user in a useful way, and coordinate the general state of the application (this includes features such as routing).

The first things that we mentioned, handling data, is the job of services.

## Services

The main point of services is to dictate how data flows into or out of your application, not within it.  If you are talking to the outside world, this is a perfect use case for a service.  Controllers use methods and data provided by these services to update properties on `$scope`, which in turn dictates how the DOM changes when a new digest cycle hits.

When I was new to Angular, I flubbed this.  In particular the difference between [services and factories](http://stackoverflow.com/questions/15666048/angular-js-service-vs-provider-vs-factory) wasn't clear to me, so I avoided them.  Instead I made `$http` calls inside of my controllers, which ended up turning my controllers into a confused mess of business and application logic.

This is *NOT* the way to go.  Instead, anything that involves setting, retrieving, or processing data should happen in services.  The leaner that your controllers are, the better.

Services should NEVER manipulate `$scope`.  That is the job of the controller.  If you need to change values in `$scope` based on the result of, say, an AJAX call, use [promises](http://docs.angularjs.org/api/ng/service/$q).  Check out [this blog article I wrote](http://nathanleclaire.com/blog/2014/01/04/5-smooth-angularjs-application-tips/) for more details.

## Directives

Directives are definitely one of the most confusing parts of AngularJS to a newcomer.  The prospect of writing your own is intimidating.  Especialy when I first started learning, the quality of available documentation and tutorials for them was not very high (this has improved a lot in the last year or so though).  

But directives, for all that they intimidate the newbie, promise a land of amazing power.  Most people who are coming to Angular from a jQuery way of thinking run the risk of getting themselves in trouble by performing DOM manipulation outside of directives.  They are so used to the old way of doing things, where an element can be accessed willy-nilly by any piece of client side code that needs it.

Directives have several different forms but usually they are either completely new HTML elements, or attributes that you can throw on existing elements, to perform some kind of DOM manipulation.  They can have their own scope and they can be reused, which is one of their most useful properties.

In some ways we are all still fighting our way towards manifesting in reality the Platonic ideal of what directives represent, e.g. I should never have to rewrite a calendar widget if it is already existing, I should just be able to use a `<calendar></calendar>` element and set properties to customize it the way that I like.  But in other ways this *is* approaching reality, especially as Angular grows in popularity and as systems such as Bower become more useful and flexible.

Directives promise no more spaghetti jQuery code (do they deliver?).  Instead, everything gets broken out into modular components that are far easier to test.

## What about Views?

In a lot of ways the "view" is the same as it's ever been, modulo directives which we have already discussed.  `ngView` promises new, snappy navigation, which is exciting.  Views in AngularJS do the same job they always have and they do it well.  Technically I probably should have called this article "Angular isn't MVC, it's SDVC" but I didn't think it had the same ring to it.

## Controllers

Finally we discuss the piece that ties it all together.  The controller.

Without controllers, directives are useless.  Controllers set properties on `$scope` for directives to use.

Likewise, without controllers, services are useless.  They are just objects for playing with data.  Therefore controllers are like the "glue" of your application.

Controllers should be as lean and lightweight as possible.  It makes it easier to see what's going on, and it makes it easier to test them.

# Conclusion

Angular is a new framework and it requires a new way of thinking.  Trying to apply the old patterns, or being inflexible and unwilling to learn about the different components of Angular and how they fit together will get you in trouble.

Everyone likes jQuery because jQuery is a useful tool.  It is simple and it allows you to build whatever you want.  It isn't very opinionated about the way you do so (in fact it provides you with a lot of options).

Angular, on the other hand, is like a house.  It already has a framework and a foundation for how to do things, you just have to ffurnish it.  Trying to use Angular like a hammer will only result in tears.  It is like trying to use a house to build a house.

I hope that this essay may help to clear some things up to people who are new to Angular.

Until next week, stay sassy Internet.

- Nathan
