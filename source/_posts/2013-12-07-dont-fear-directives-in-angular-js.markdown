---
layout: post
title: "Don't Fear Directives In AngularJS"
alias: blog/2013/12/07/dont-fear-directives-in-angular-dot-js/index.html
date: 2013-12-07 12:41
comments: true
categories: [Angular,Controllers,Directives,JavaScript]
---

{% img /images/directivefear/anghero.jpeg Superheroic. %}

# Direct what?

As I mentioned in [last week's article](http://nathanleclaire.com/blog/2013/11/30/fear-and-loathing-with-golang-and-angular-dot-js/) I have been working with [AngularJS](http://angularjs.org/) for personal projects lately.  This was largely the result of me, approximately six or seven months ago, feeling like I was missing out on the new hotness by not knowing a client-side MV* framework.  I looked around at a lot of options, including:

- [Backbone.js](http://backbonejs.org/) (A crowd favorite, with rock-solid online support/documentation/tutorials)
- [Ember.js](http://emberjs.com/)
- [Knockout.js](http://knockoutjs.com/)

Ultimately I fell into learning Angular for a variety of reasons.  Partially it was because I went to a "Coffee Shop Coders" presentation where the presenter ([Taurus Colvin](http://www.tauruscolvin.com/) - a very friendly dude) explained the basics and impressed me with the possibilities the framework offers.  Maybe it was because I tried to bootstrap a simple Ember project and couldn't get anything working.  I don't know if it was the documentation, the learning curve, my own shortcomings, or all three, but something about Ember didn't click with me.  My choice of Angular was also at least somewhat because I was seduced by [Yeoman](http://yeoman.io/) (which, at the time of writing, uses an Angular generator in its usage example) around the time I attempted my first Angular app.  It was a foray which went down in flames, largely because I was so hesitant to make my own directives and services.

# $scope Creep

One day after I had started getting interested in Angular I mentioned to a coworker that I was developing an app with the framework.

"Oh yeah," he said, "I watched a presentation about making directives - seems to be where the real power of it is."

Since I knew that the funny attributes Angular introduces such as `ng-show`, `ng-class`, and `ng-repeat` were directives, I had a feeling he was onto something.  However, I was a little bit too timid to actually tackle making my own.  After all, directives were something that smart people made, not me.  I'd have to understand that difficult link/compile stuff, right?  Remember, this was April of 2013 and, though it seems silly to say since at the time of writing only eight months have passed, the quality of documentation, tutorials, and examples for AngularJS was not as good as it is today.  I think [egghead.io](http://egghead.io) (an excellent Angular resource if you're not aware) was just getting off the ground, but I certianly hadn't heard of it.

Less so through concious decision and more so through my own hesitance to learn something I was irrationally afraid of, I began slipping into the trap of creating a tangled mess that stuffed everything possible into `$scope`, used `ng-include` when I could have used directives, and relied on `$broadcast`ing down from `$rootScope` when I could have used services.

I was a fool.

# How Not To Fear The Directive

If I could go back and stop myself from making a whole bunch of mistakes in that app, I would have started with explaining that a directive is just a simple little reusable component for describing the way HTML should behave.  The Angular docs try to harp on this but inevitably they make it seem obtuse and complicated.  *Note:  Though they could be better I don't think it's cool to hate on the Angular docs.  They've gotten way better even in the short time I've been using the framework.* 

In my opinion it's a very useful tool because it allows you to encapsulate functionality in a semantic way that will (hopefully) make sense to anyone looking at your markup, and keep your functionality well "chunked" so that you can keep track of what is happening where instead of dealing with things mutating globally (which most of us hopefully know by now is bad news).

Ever had this happen with jQuery? You need to do some JavaScript magic with a particular element on the page, and so you give it some arbitrary `id` so you can access it with `$('element#id')`.  Now you get to write a bunch of JavaScript that listens for the relevant events, checks the element's state to see that it is congruent with our expectations, modify its class to change how it is displayed, and so on.  It starts out as a few simple functions using a very powerful tool that soon grows into a complicated mess of callbacks, weird looking selectors, and re-render functions.  It may be strewn across several files with no rhyme or reason.

Not only is it no fun, it makes it very hard for your designer friends to look at your markup and know what the expected behavior for that HTML is.  So, Angular provides us with directives, which are actually pretty simple to create.  So don't be scared of them like I was.  You just have to create an Angular app:

```js
var myApp = angular.module('myApp', []);
```

Then attach a simple directive:

```js
myApp.directive('myDirective', function() {
	return {
		restrict: 'E',
		template: '<h1>I made a directive!</h1>'
	};
});
```

That's all, you just created a directive!  Now, when you go looking around for some examples of directives online, it's easy to get lost in all of the Angular-specific jargon like linking functions, the "restrict" property, scope hierarchies and so on.  But I highly recommend that you try not to panic, and realize that there is meaning behind all of the weird symbols and abbreviations you see.  For instance, in the definition for the directive above, I define a `restrict: 'E'` setting.  What the heck does that mean?

Well, what it means is, "restrict the usage of this directive to only Elements".

So, you can use it in HTML like this:

```js
<body ng-app="myApp">
	<myDirective></myDirective>
</body>
```

But not like this:

```js
<body ng-app="myApp">
	<span my-directive></span>
</body>
```

(Angular "normalizes" the `hyphen-usage-attribute` to `camelCase` as part of their normalization process for directives - see the [documentation](http://docs.angularjs.org/guide/directive)).

# Why is it useful?

So, other than providing a convenient way to make little repeatable bits of HTML that have their own names, why is this useful?

Well, by default every directive inherits the parent scope but it is also possible for a directive to have its own [isolate scope](http://www.thinkster.io/pick/KnxWvHUW64/angularjs-understanding-isolate-scope).  What this means is, it can have its own little properties that it sets on its own unique `$scope` that won't mess around with any of the other properties that you are setting in the rest of your app.  Especially if you are going to use the component in multiple places, or have it in a `ng-repeat`, this is incredibly useful.  It allows you to break things down into much more modular components than using some giant `BigBallOfMudController` (or several `BigBallOfMudController`s) to control the state of your app (which is usually the essence of what ends up happening in the "traditional jQuery" mess described above).  Instead, each directive is responsible for its own data and it works on it in isolation from the other directives.  In Angular this antipattern would look something like having a big array of objects in a central Controller, and updating individual properties of those objects in that controller instead of having a directive to modularize that kind of operation. 

Check out this example, where I created a `gear` directive using [Font Awesome](http://fontawesome.io/)'s spinning gear icon.  The end result is a lot more flexible than an attempt at creating this using jQuery, or vanilla JavaScript.  Each gear keeps track of whether it is currently spinning or not in the new shared scope automagically created by the ngRepeat directive, so they spin or remain stationary indepent of each other.  However, they are all influenced equally by the `ng-model` properties of the parent scope.

Writing a `link` function provides even more power and flexibility, but that's a little outside the scope of this article.  Perhaps another time.

<iframe src="http://embed.plnkr.co/i2StmWcxKNZCQb0YtYp0/preview"></iframe>

# Conclusion

Enjoy your directives, kids, and never ever be scared of them.  [Miško](http://misko.hevery.com/)'s been up late at night so you can experience HTML as it could have been.

On a more serious/philosophical note, I wanted to close with a thought that I have that creating your own directives reminds me a bit of [Metcalfe's Law](http://en.wikipedia.org/wiki/Metcalfe's_law) (by analogy of course).  Each directive that gets created increases the power and usefulness of all the other directives.  An Angular in which `ng-repeat` exists, for instance, is so much more powerful than one in which it doesn't.  So, remember that they can be stacked and it makes your webapp that much better.

Until next time, stay sassy Internet.

Cheers,

Nathan
