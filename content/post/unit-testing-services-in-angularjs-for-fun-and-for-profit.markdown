---
layout: post
title: "Unit Testing Services in AngularJS for Fun and for Profit"
date: "2014-04-12"
comments: true
categories: [service,angularjs,unit testing,jasmine,spy]
---

{{%img src="/images/unit-test-angularjs-service/jasmine.png" caption="Your new best friend. " %}}

If there was a way to reduce the number of defects in the code you write (or manage), improve the quality and time to market of deliverables, and make things easier to maintain for those who come after you- would you do it?

Right about now, especially given the content of the article, you might be sensing that I'm about to jump into the usual testing zealot rant.  And you're right.

How many times have you heard some variant on, "Writing tests isn't as important as delivering finished code?"  If you're like me, it's way too many, and god help you if you're working with no tests at all.  Programmers are human and we all make mistakes.  So test your code.  The number of times testing my code has helped me catch unforeseen issues before they became flat-out bugs, prevent future regressions, or simply architect better is pretty amazing.  And this is coming from a guy who used to hate writing tests for code.  *Hated* it.

I think that stemmed more from a lack of understanding how to do it than anything else.  When systems get complex and have a lot of moving parts is when it is most critical to test them, and that is also when it becomes the most difficult to test them.  Without an understanding of your tools (e.g. mocks) or why each piece is important, and especially with a lack of easily accessible examples, testing code can be really intimidating and frustrating.

So what do you do?  You commit code without tests.  You are cowboy.  Cowboy no test.

{{%img src="/images/unit-test-angularjs-service/cowboy.png" caption="" %}}

But as some of you probably know all too well, this is dangerous.  It's like going on vacation in the Caribbean using your credit card.  Fun for a while, and everything seems great, until suddenly reality hits and [it takes all the running you can do just to stay in the same place](http://en.wikipedia.org/wiki/Red_Queen's_race).

Fortunately Angular treats us really well as far as testing goes.  It just requires some additional explanation, since the quality of resources available for both Angular *and* Jasmine is really not fantastic.  It's better than a year ago, definitely, but not fantastic.

So here I am doing a brain dump of sorts of what I know about testing services, which are part of the [lifeblood](http://nathanleclaire.com/blog/2014/03/15/angularjs-isnt-mvc-its-sdc/) of any Angular application.

# Section 1: In Which I Proclaim "I love Dependency Injection!"

When I first saw someone present on Angular, they got kind of hand-wavey about [Dependency Injection](http://en.wikipedia.org/wiki/Dependency_injection).  "The way I see it, it's basically magic and I don't have to think about it."  Ahhh.  Not what I like to hear.

I get that it can be kind of scary, hearing people throw around jargon like injectors and providers and dependency injection like they're nothing, but you can get it.  I know you can.

It's simple.  Not easy, but simple.  When Angular runs the code that you define for a controller or a service, it looks at the parameters you have attached to the function and sets them correctly for that run based on their names.  Let's say that you have something like this:

```js
angular.module("foo").controller("NavCtrl", function ($scope, tabService) {
  // ...
});
``` 

The order of the parameters on your function doesn't matter.  You could just as easily have said `function (tabService, $scope)` and both of those values would still be set correctly.  That's a nice advantage in itself, and it's why you see funny business like:

```js
angular.module("foo").controller("NavCtrl", [
  "$scope",
  "tabService",
  function($scope, tabService) {
    // ...
  }
]);
```

That's so that [minification](http://en.wikipedia.org/wiki/Minification_%28programming%29), which renames all of your passed variables in functions, doesn't blow up Angular's dependency injection.  Angular knows how to handle this if you use the second form of notation.

But why are we even messing with this at all?  It's because if we inject the dependencies, we can control them from the outside world.  And this is eminently important for testing.

This kind of thing (admittedly contrived for effect):

```js
function mungeSomeData(data) {
  var dataGetter, dataParser, dataTransformer;
  dataGetter = new DataGetter();
  dataParser = new DataParser();
  dataTransformer = data.isXML() ? new XMLDataTransformer() : new JSONDataTransformer();
  // ...
}
```

Doesn't use Depdency Injection, and is a nightmare to test.  Minimizing surface area to test is so so important, and by writing code that way you make your surface area HUGE and slippery.

Side note:  It is Angular convention to have a dollar sign (`$`) in the front of the names of things that are both injected (`$scope`, `$timeout`, `$http`) and built-in to Angular.  If you see `$scope` being used in the link function of a directive, that is both wrong and confusing since parameters are *passed* to the link function of directives, not injected.  Please Hulk out when you see this and correct the code.  If you are using `vim` a simple `:%s/$scope/scope/` (or perhaps just `:s` in visual mode if you have instances of `$scope` that *shouldn't* be replaced) will do the trick.

**Q: So what does that have to do with unit testing AngularJS services, Nate?**

It has everything to do with testing services since they are injected.  So, in unit testing a service, you can control precisely what goes on in one in addition to all of its dependencies.

**Q: Will you show us some actual Jasmine code already?**

Getting there.

# Section 2: In Which I Write an Actual Service, and a Unit Test for It

Let's say that I'm writing an Angular app which interacts with the Reddit API.  Since we know that services are the part which Angular uses to interact with the outside world, we will write a service to handle our needs.

We are going to write one with a method `getSubredditsSubmittedToBy(user)` which returns a list of which subreddits a user has submitted to recently.  We can use [promise chaining](https://egghead.io/lessons/angularjs-chained-promises) to achieve this (aggregating the big glob of JSON returned by the API call) so that our controller stays super lean.

## Writing the Service 

Usage (inside controller):

```
userService.getSubredditsSubmittedToBy("yoitsnate").then(function(subreddits) {
  $scope.subreddits = subreddits;
});
```

So nice and readable!

Our service looks like this:

```js
angular.module("reddit").service("userService",
function($http) {
  return {
    getSubredditsSubmittedToBy: function(user) {
      return $http.get("http://api.reddit.com/user/" + user + "/submitted.json").then(function(response) {
        var posts, subreddits;

        posts = response.data.data.children;

        // transform data to be only subreddit strings
        subreddits = posts.map(function(post) {
          return post.data.subreddit;
        });
        
        // de-dupe
        subreddits = subreddits.filter(function(element, position) {
          return subreddits.indexOf(element) === position;
        });

        return subreddits;
      });
    }
  };
});
```

## Writing the test

We will write a test using [Jasmine](http://pivotal.github.io/jasmine/).  Jasmine is a Behavior-Driven-Development framework, which is sort of a roundabout way of saying that our tests include descriptions of the sections that they are testing and what they are supposed to do.  This is done using nested `describe` and `it` blocks, which look really weird at first (something about a function as short as `it` is just unsettling to me ;) ) but can be helpful in understanding what the test is intended to, well, test.

This is quite helpful as sometimes large elaborate codebases have large elaborate tests and it can be hard to figure out what's what.  For instance, in PHPUnit, this kind of "built-in documentation" is spread out and mostly optional, and makes complex unit tests a bit trickier to read.

Using Karma we first tell it what module we're working in (`"reddit"`), run an inject function to set up our dependencies and get the service under test (this allows us access to Angular's injector so we can set local test variables), then run an actual test in the `it` block.

Notice that in the `inject` method we inject in `_foo_`, with an underscore on either side of the name of the actual service, so that we can set it in the outer `describe` closure.  This is by design, as the Angular maintainers foresaw (or discovered) that:

```
var redditService;
beforeEach(inject(redditService) {
  redditService = redditService;
});
```

would result in an error.

So use `_underscoreNotation_` to get the service that you want to test :)


```
"use strict";

describe("reddit api service", function () {
  var redditService, httpBackend;

  beforeEach(module("reddit"));

  beforeEach(inject(function (_redditService_, $httpBackend) {
    redditService = _redditService_;
    httpBackend = $httpBackend;
  }));

  it("should do something", function () {
    httpBackend.whenGET("http://api.reddit.com/user/yoitsnate/submitted.json").respond({
        data: {
          children: [
            {
              data: {
                subreddit: "golang"
              }
            },
            {
              data: {
                subreddit: "javascript"
              }
            },
            {
              data: {
                subreddit: "golang"
              }
            },
            {
              data: {
                subreddit: "javascript"
              }
            }
          ]
        }
    });
    redditService.getSubredditsSubmittedToBy("yoitsnate").then(function(subreddits) {
      expect(subreddits).toEqual(["golang", "javascript"]);
    });
    httpBackend.flush();
  });

});
```

Our mock data here mimics the actual data returned by the Reddit API, but only enough that we get the necessary bits of structure in place and can account for, say, the duplicate case.  If we wanted to add different functionality for different pieces of the API, or of this call, we could just define new `httpBackend` responses in new `it` blocks and test things the same way without having to worry about the bits of the API response we don't need.

## The provider idiom

Unfortunately my simple example above breaks down a little bit if we have additional dependencies on other services in our service under test.  What do we do in this case?  We need to control these injected parameters, and to do so we use `$provide`.  `$provide` can take the name of e.g. a service and dictate what to provide for it.  In doing so we can, say, use a spy object instead of the "real deal".

```
beforeEach(module(function($provide) {
  $provide.value("myDependentService", serviceThatsActuallyASpyObject);
}));
```

Note that `$provide` should always be called before your call to `$inject`, since the former dicates what the latter should use.

# Section 3: Helpful Tips

## Stutter.

If you change a `describe` or `it` block to `ddescribe` or `iit` respectively [Karma](http://karma-runner.github.io/0.12/index.html) ([Angular's test runner](http://nathanleclaire.com/blog/2013/12/13/how-to-unit-test-controllers-in-angularjs-without-setting-your-hair-on-fire/)) will run only that block.  This is called [stuttering](https://github.com/davemo/jasmine-only) and it is very useful if you don't want to run your entire test suite every time, as the larger the codebase gets the longer this will take to do.

## Don't be afraid to rearrange code that is hard to test

If you can move code around to make it easier to test without changing other things, DO IT (in a general sense I find that this eases readability and maintainability too).  For instance I found that in one instance in a service a colleague was relying on a function call that was both unneccesary and confusing, and ultimately broke the chain of promises.  So I deleted the function definition and inlined the code it contained.  The resulting code was a bit easier to read and test.

## Cheat.

You can create stubbed objects quite easily in JavaScript, so if there's no need to introduce the extra complexity of a spy (see next section), then do so.  For example, if you can just return `4` from a method every time you call it instead of counting the elements or whatever it usually does, then do so.

## Do you need a Spy?

If you need more power / assertions out of the last point, Jasmine provides Spies for you to use.

They're a little out of scope for this article, but they should provide you all of the flexibility you need for faking data / objects / calls and testing what was faked.

For a good reference, see this [Jasmine spy cheatsheet](http://tobyho.com/2011/12/15/jasmine-spy-cheatsheet/).

## Or just use `$q` / manually manage promises

I found myself in kind of a funny situation at work recently.  We use Angular for structure but the codebase we are working on has a lot of pre-existing bits/modules that were not really moved over to Angular fully due to intense deadline pressure.  So, we find ourselves making XMLHttpRequests outside of `$http` land, but the original programmers still return promises from their outside world modules for us to use (it's kind of an odd setup that we don't really have time to refactor).  So, I just caused the functions that take care of those API calls return promises that I control using `$q`.

```js
var mockDeferred;
mockDeferred = $q.defer();
someSpyObj.methodThatReturnsAPromise.andCallFake(function () {
  return mockDeferred.promise;
});
mockDeferred.resolve({
  things: "foo",
  otherThings: "bar"
});
```

# Conclusion.

Jasmine tests are pretty quick to write once you get the hang of them.  Seriously guys, there's no excuse.

The [violent psychopath who ends up maintaining your code](http://blog.codinghorror.com/coding-for-violent-psychopaths/) will thank you.  Or at least not murder you.

Until next time, stay sassy Internet, and [consider subscribing to my blog](http://nathanleclaire.com).

- Nathan
