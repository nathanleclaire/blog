---
layout: post
title: "5 AngularJS Antipatterns & Pitfalls"
date: 2014-04-19 13:58
comments: true
categories: [angularjs,javascript,pitfall,service,controller]
---

# The Angular Jungle

{%img /images/angular-antipatterns/jungle.jpg %}

[AngularJS](http://angularjs.org) is a big JavaScript framework and it gives you just enough rope to hang yourself with.  I've written a lot about it in this blog and really hope that I have made a noteworthy impact on improving the general availability of resources.  I've been working on a project using AngularJS at my dayjob lately and noticed some antipatterns and pitfalls that people fall into when they are new to Angular (myself included, so they're based on my own sweat and blood learning the framework) and I've consolidated some of them here for you to peruse.  Hopefully I'll save you some pain.

They are:

1. Not having a dot in your `ng-model` (or other places you need it!)
2. Extreme overuse of event broadcasting and listening (`$emit`, `$broadcast`, `$on`)
3. Too much stuff in controllers 
4. Misunderstanding or misusing isolate scope
5. Using the outside world instead of doing things the Angular way

# 1. Not having a dot in your `ng-model` (or other places you need it!)

{%img /images/angular-antipatterns/george.jpg %}

Angular's [directives](https://docs.angularjs.org/guide/directive) provide fantastic flexibility and an amazing way to write HTML that describes its interactive behavior in a clean and clear fashion.  They provide a way to create [isolate scope](https://egghead.io/lessons/angularjs-understanding-isolate-scope) to promote reusability and creating a directive that uses this looks something like:

```js
angular.module('myApp').directive('myDir', function () {
  return  {
    restrict: 'E',
    scope: {
      aProperty: '=',
      bProperty: '&'
    },
    // and so on...
  };
});
```

In the above definition `aProperty` gets passed in through an attribute (normalized to `a-property`) and creates a two-way data binding between the parent scope and the child scope.  That means if you change one, the other will be updated to match it and vice versa.  However, because of the way that JavaScript's prototypal inheritance works, sometimes this may not work "magically" as you would expect.  I will dicuss a particular situation with `ng-model` here but know that understanding how this all ties together will save you lots of tears due to `ng-switch`, `ng-repeat`, etc. creating their own scopes (and "shadow" properties in the prototype chain) that throw off the way you might be expecting things to work.

In particular, when you have an `ng-model` bound to a property on `$scope` which was originally passed in using `=` in your child directive:

> “Whenever you have ng-model there’s gotta be a dot in there somewhere. If you don’t have a dot, you’re doing it wrong.”

Words from the mouth of Miško himself.

This is because *primitives* (String, Number, etc.) passed in to a child scope create their own "shadow" property in the child scope, which hides the original property on the parent scope due to the way that JavaScript prototypes work (the prototype chain will not need to be consulted to determine the value of `foo` if `foo` is not an `Object` or `Array`).  If they are bound using `=` and they are objects, however, `foo.bar` *will* be bound correctly to the original property in the parent scope.

Understanding this will save you soooo much pain.  Seriously, if you're serious about Angular at all, take the time to read the offical article I link at the end of this section.  Then read it again.

I suspect that a misunderstanding of this (communicating effectively from scope to scope up and down the prototype chain) is at least partially what contributes to people digging themselves further and further into a hole by misusing event broadcasting/emitting/listening and isoalte scope, as detailed later on in this article.  When things spiral out of control in this manner, it can really be pure torture.  You're fighting against the framework, and nobody wins in that battle, least of all the people who have to maintain your code.

The point is, most people new to Angular (and even people who have been doing it for a while) expect this to work :

{% raw %}
```
<p> You have {{dollars}} dollars </p>
<crazy-awesome-widget ng-repeat="account in accounts" info="dollars">
</crazy-awesome-widget>

<script>
angular.module('dotDemo').controller('OuterCtrl', function($scope) {
  $scope.dollars = 5;
  $scope.accounts = ["Tom", "Bobby", "Sally"];
});
angular.module('dotDemo').directive('crazyAwesomeWidget', function() {
  return {
    restrict: 'E',
    template: '<input type="text" ng-model="info" />',
    scope: {
      info: '='
    }
  };
});
</script>
```
{% endraw %}

Can you spot the bug?  If you've been paying attention, you should be able to pick it out easily.

<iframe src="http://embed.plnkr.co/ii8xZoOIRcWw4LlNMayf/preview"></iframe>

Come on, intone it with me.  *I need a dot. I need a dot. I need a dot.*

In the above code the input boxes won't update the property in the parent scope.  The prototype chain creates a new property `info` which is unique to the child scope instead of bound to the parent scope.  It won't work this way.  You need an object.  The code should look like this instead:

{% raw %}
```
<p> You have {{customerData.dollars}} dollars </p>
<crazy-awesome-widget ng-repeat="account in accounts" info="customerData">
</crazy-awesome-widget>

<script>
angular.module('dotDemo').controller('OuterCtrl', function($scope) {
  $scope.customerData = {
    dollars: 5
  };
  $scope.accounts = ["Tom", "Bobby", "Sally"];
});
angular.module('dotDemo').directive('crazyAwesomeWidget', function() {
  return {
    restrict: 'E',
    template: '<input type="text" ng-model="info.dollars" />',
    scope: {
      info: '='
    }
  };
});
</script>
```
{% endraw %}

<iframe src="http://embed.plnkr.co/IVkqcNVhwQXd1zQ9nZQ2/preview"></iframe>

Boom, synchronization from parent scope => isolated child scopes and back again.

Big shout out to Reddit user [Commentares](http://www.reddit.com/user/Commentares) who caught a flaw in the original implementation of my first example in the first draft of this article.

See for reference:

- [This excellent article by Jim Hoskins](http://jimhoskins.com/2012/12/14/nested-scopes-in-angularjs.html)
- [This aforementioned Angular documentation gettin' mad deep about scopes](https://github.com/angular/angular.js/wiki/Understanding-Scopes)

# 2. Extreme overuse of event broadcasting and listening (`$emit`, `$broadcast`, `$on`)

Everybody loves to hate on GOTOs.  Poor little GOTOs.  All they ever wanted to do was help control program execution flow and branching, and they get the Rodney Dangerfield treatment.  They're reviled with that sort of knee-jerk reaction that only programmers can revile something with.  You know the type.  They're the ones who got burned by `git rebase` one time (it was their own fault) and spend way too much effort and energy spreading FUD about rebases.  But I digress.  My point is, there's this Angular antipattern I've seen and fallen into, where `$scope.$emit` and `$scope.$broadcast` have become the new GOTO.  Except that it's shiny and new and Angular-ey, so everybody gives it a pass.  `$scope.$watch` can kind of be abused in the same way, but the others are slightly easier to pick on.

I really feel that you should keep manual event broadcasting and catching out of your code if possible.  It doesn't usually do a whole lot of good and confuses the hell out of the people who have to maintain your code (including you!).  The problem is thus:  Let's say you have something going wacky in a `$scope.$on`.  You set a breakpoint in the defined callback function that runs when that `$scope.$on` catches its defined event.  OK, now what?  Perhaps you look to see where the event was thrown from.  With constrained eventing, debugging shouldn't be a problem, but if you or your team lets their discipline slip into event spaghetti you're in for a world of pain.  Usually this can be avoided by careful use of services and proper scope inheritance.

# 3. Too much stuff in controllers

It's unfortunate that I have to point this one out, but as I've personally fallen into this pitfall especially when first getting started with Angular, I suppose I can give people a free pass on making this mistake once or twice.  After that, however, they should definitely learn.

Your controllers should be lean.  Say it with me.

My controllers should be lean.

My controllers should be lean.

My controllers *are* lean.

This means that absolutely everything which can be stripped out of them, should be.  They exist to coordinate the delicate dance between your other resources (services and directives).  

For instance, I came across a line introduced in one of our controllers that looked like this:

```
$('body').attr('data-state', 'someNewState');
```

This was my reaction upon finding this code in this controller:

{%img /images/angular-antipatterns/hulk.gif %}

Note:  My actual reaction was way more passive aggressive (wrote about it in my *blog*!  Showed that guy).

In Angular, DOM manipulation is done inside directives.  NOT controllers.  DOM manipulation is done inside directives.  Every aspiring Angular programmer should have this branded into his or her brain.

Other common things that slip into controllers:

- Ajax (sometimes disguised in a half-baked abstraction) - this should be done in services
- Tangled mess of event handling as discussed in last section
- Things that are basically service or factory logic, but eh I'm too lazy to move this code

Don't do it.  If you keep your controllers lean and small they will reward you with readability and ease of debugging.  If you let them spiral out of control you will be punished unceremoniously.

# 4. Misunderstanding or misusing isolate scope

Isolate scope is really nice.  It prevents directives from just accessing / modifying the parent scope willy-nilly, opening the door to all kinds of bugs associated with global-ish scope, and promotes reusability.  But it's important to realize that this is the point of isolate scope.  Consequently, if you're passing a bunch of properties into your directive's `$scope`, and then cascading them downwards through a variety of child scopes, you are probably doing something wrong.

I've seen this a bit.  If you are passing a bunch of information down to your directive's scope, either it should be inheriting by default (in which case you don't want isolate scope), or you should bundle the properties that you can together in an object or two to keep the `scope` definition nice and clean and promote readability of the HTML.

# 5. Using the outside world instead of doing things the Angular way

{%img /images/angular-antipatterns/but-computers.png Aren't we all nowadays? %}

It's really tempting, especially when first learning Angular, and directives in particular, to just write jQuery code like we always have that happens to be wrapped in an Angular directive.  While this is still probably better than rolling with no framework at all and creating a tangled mess, it indicates a basic ungrok of the Angular way.

Things should be done in Angular, when they can.  Angular provides so much niceness in the form of built-in directives, services (`$window`, `$timeout`, `$http` et al. wrap these things for you so you don't have to worry about accidentally interfering with Angular's internals!) that we should only reach for custom solutions when we have to (and believe me, you will - just think carefully before doing so).  Just wrapping jQuery code in a directive doesn't do us any good, and creates complications when we need to start doing stuff like chucking `$scope.$apply` into things.  So think things through, and do them the Angular way.

Likewise dependencies that you had before (modules you are relying on etc.) should be refactored into e.g. factories for increased ease of use and testability.  If you have the time to use Angular into your project, you have the time to do this too.  Angular will reward you with layers of increased richness.

# Fin

I really hope that this article helps people avoid these bad behaviors, or at least see them when they come across them and refactor them into something better.

Until next time, stay sassy Internet.  And [consider subscribing to my mailing list](http://nathanleclaire.com).

- Nate
