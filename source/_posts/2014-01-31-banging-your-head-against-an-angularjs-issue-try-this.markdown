---
layout: post
title: "Banging Your Head Against an AngularJS Issue?  Try This"
date: 2014-01-31 19:53
comments: true
categories: [javscript,hacking,angularJS,$scope.$apply,controllers,directives]
---

{%img /images/scope-apply/frustration.jpg Have you been debugging something that seems trivial in Angular for so long that your face looks like this? %}

As I've gotten a [little](http://nathanleclaire.com/blog/2014/01/04/5-smooth-angularjs-application-tips/) [into](http://nathanleclaire.com/blog/2014/01/11/dragging-and-dropping-images-from-one-browser-tab-to-another-in-angularjs/) [AngularJS](http://angularjs.org) I've been surprised by how often my assumptions about how things will work have turned out to be wrong.  When you start to form a basic mental model of how Angular works and you hit your first stumbling block where your model turns out to be incorrect it can be really, really, frustrating.  In particular I had one issue that kept cropping up so often I began trying it before running to Google for help if something wasn't working the way I would have expected (all my views should just magically sync up with what's on `$scope`, right?).  This solution is to make sure `$scope.$apply` is getting used in the proper manner when updates to `$scope` are happening, especially if they are happening in unusual places e.g. inside of directives.  Since I don't really like "magical" or knee-jerk fixes to problems I highly recommend Jim Hoskins's article on `$scope.$apply` which you can find [here](http://jimhoskins.com/2012/12/17/angularjs-and-apply.html).

# Use `$scope.$apply`

During your first foray into Angular you will probably not come across this as it is one of those hidden, quasi-leaky-abstraction sort of things that only becomes well known to you as you work on getting a non-trivial app off the ground.  After all, it's not really needed for the [todo-list app](http://todomvc.com/architecture-examples/angularjs/#/) of yore but it becomes much more important when you are doing funny things like manipulating scope deep inside of directives and so on.  So, having been bit by the issue multiple times, I recommend trying a call to `$scope.$apply` (either wrap the changes to `$scope` properties inside a `$scope.apply` callback, or call `$scope.$apply` on its own after `$scope` properties have been updated)  See the documentation [here](http://nathanleclaire.com/blog/2014/01/04/5-smooth-angularjs-application-tips/).  

The issue is around updating properties on `$scope`, either in directives or in controllers, and not having the updated changes be reflected on the front-end in the manner which you expect (either they will not show up at all, or they will happen in an order which you do not anticipate, which will cause bugs).  This is because Angular has what is known as a digest-watch cycle where all of this gets figured out:

{%img /images/scope-apply/digest-cycle.png %} 

As automagical as Angular is in some ways, it has no way of knowing when your property has been updated outside of Angular-land (and sometimes doesn't even bother when it is updated *in* Angular-land, as per the example that follows).  So it requires a call to `$scope.$apply` to stay in sync. 

# Example

Let's say you have a list of numbers displayed with `ng-repeat` and you want to `shift` one off the list when the user presses the right arrow key, and redisplay them one at a time if the user presses the left arrow key.  Our controller code (on first attempt) would look something like this:

```js
.controller('NumCtrl', function($scope) {
	var history = [];
	$scope.numbersDisplayed = [0,1,2,3,4,5];

	$scope.moveRight = function() {
		history.unshift($scope.numbersDisplayed.shift());
	};

	$scope.moveLeft = function() {
		$scope.numbersDisplayed.unshift(history.shift());
	};
})
```

We're ignoring bounds-checking for the sake of simplicity in this demonstation.  Our directive, designated to watch for user input on the element where this is happening (will be `<body>` in our case since it is a simple little example), will look like this:

```js
.directive('arrowListener', function() {
	return {
		restrict: 'A', // attribute
		scope: {
			moveRight: '&', // bind to parent method
			moveLeft: '&'
		}
		link: function(scope, elm, attrs) {
			elm.bind('keydown', function(e) {
				if (e.keyCode === 39) {
					scope.moveRight();
				}
				if (e.keyCode === 37) {
					scope.moveLeft();
				}
			})
		}
	};
})
```

If you try the above code, you'll notice that it doesn't work.  The variable on `$scope` gets changed correctly, but this change is not reflected in the view.  In order to make it work you have to change the controller code to :

```js
.controller('NumCtrl', function($scope) {
	var history = [];
	$scope.numbersDisplayed = [0,1,2,3,4,5];

	$scope.moveRight = function() {
		history.unshift($scope.numbersDisplayed.shift());
		$scope.$apply();
	};

	$scope.moveLeft = function() {
		$scope.numbersDisplayed.unshift(history.shift());
		$scope.$apply();
	};
})
```

You could also invoke `scope.$apply` in the directive itself.  To be honest, I'm not sure what the Angular gurus would consider best practice.  Perhaps the latter since it is more DRY.

You can see this finished code in action in a Plunk here:

<iframe src="http://embed.plnkr.co/agbSSuA2Mwx5pAd8kZSw/preview"></iframe>

# Conclusion

This is one of those nasty issues I wish someone would have pointed out to me from the start.  So here you go, guys, hopefully you can get something out of the suffering I've gone through to develop an almost sixth-sense like awareness of when a `$scope.$apply` will be needed.

Until next week, stay sassy Internet.

- Nathan