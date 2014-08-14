---
layout: post
title: "How to Unit Test Controllers In AngularJS Without Setting Your Hair On Fire"
date: 2013-12-13 23:03
comments: true
categories: [Angular,Controllers,Directives,JavaScript,Jasmine,Unit Testing,Karma]
---

Developers almost universally agree that unit tests are a *VERY GOOD THING* when working on a project.  They help you feel like your code is airtight, ensure reliability in production, and let you refactor with confidence when there is a need to do so.  

{% img /images/angularjs-unit-testing/test-code-refactor-cycle.png The Test-Driven Development cycle. %}

AngularJS code touts its high degree of [testability](http://angularjs.org/#embed-and-inject), which is a reasonable claim.  In much of the documentation end to end tests are provided with the examples.  Like so many things with Angular, however, I was finding that although unit testing was simple, it was not easy.  Examples were sparse and though the [official documentation](http://docs.angularjs.org/guide/dev_guide.unit-testing) provided some snippets of examples, putting it all together in my "real-world" case was proving challenging.  So here I've written a little bit about how I ended up getting that wonderful green light for a passing build to show up.

# Instant Karma

[Karma](http://karma-runner.github.io/) is a test runner for JavaScript that was created by the Angular team.  It is a very useful tool as it allows you to automate tasks that you would otherwise have to do by hand or with your own cobbled-together collection of scripts (such as re-running your test suite or loading up the dependencies for said tests).  Karma and Angular go together like peanut butter and jelly.

With Karma, you simply define a configuration file, start Karma, and then it will take care of the rest, executing the tests in the browser(s) of your choice to ensure that they work in the environments where you plan on deploying to.  You can specify these browsers in the aforementioned configuration file.  [angular-seed](https://github.com/angular/angular-seed), which I highly recommend, comes with a decent out-of-the-box Karma config that will allow you to hit the ground running quickly.   The Karma configuration in my most recent project looks like this:

```
module.exports = function(config) {
    config.set({
        basePath: '../',

        files: [
            'app/lib/angular/angular.js',
            'app/lib/angular/angular-*.js',
            'app/js/**/*.js',
            'test/lib/recaptcha/recaptcha_ajax.js',
            'test/lib/angular/angular-mocks.js',
            'test/unit/**/*.js'
        ],

        exclude: [
            'app/lib/angular/angular-loader.js',
            'app/lib/angular/*.min.js',
            'app/lib/angular/angular-scenario.js'
        ],

        autoWatch: true,

        frameworks: ['jasmine'],

        browsers: ['PhantomJS'],

        plugins: [
            'karma-junit-reporter',
            'karma-chrome-launcher',
            'karma-firefox-launcher',
            'karma-jasmine',
            'karma-phantomjs-launcher'
        ],

        junitReporter: {
            outputFile: 'test_out/unit.xml',
            suite: 'unit'
        }

    })
}
```

Which is very similar to the default configuration in [angular-seed](https://github.com/angular/angular-seed), except for a few things:

- I have switched the browser the tests run in from Chrome to [PhantomJS](http://phantomjs.org/), a headless browser, so that they can run without opening a browser window and causing an awkward viewport shuffle in OSX.  Therefore the `plugins` and `browsers` settings have been changed.
- I added `recaptcha_ajax.js`, the minified file that Google provides for their Recaptcha service, since my app depends on it being included.  Having this change be as simple as adding a line in the Karma config file was really nice.

`autoWatch` is a particularly cool setting, since it will have Karma re-run your tests whenever they, or the files they test, change.

You can install Karma with:

```
npm install -g karma
```

[angular-seed](https://github.com/angular/angular-seed) provides a handy little script for starting the Karma test runner, which is in `scripts/test.sh`.  Use it!

# Writing Tests With Jasmine

Most of the resources available at the time of writing for unit testing with Angular use [Jasmine](http://pivotal.github.io/jasmine/), a behavior-driven development framework for testing JavaScript code.  That's what I'll be describing here.

To unit test an AngularJS controller, you can take advantage of Angular's [dependency injection](http://docs.angularjs.org/guide/di) and inject your own version of the services those controllers depend on to control the environment in which the test takes place and also to check that the expected results are occurring.  For example, I have this controller defined in my app to control the highlighting of which tab has been navigated to:

```
app.controller('NavCtrl', function($scope, $location) {
    $scope.isActive = function(route) {
        return route === $location.path();
    };
})
```

If I want to test the `isActive` function, how do I do so?  I need to ensure that the `$location` service returns what is expected, and that the output of the function is what is expected.  So in our test spec we have a `beforeEach` call that gets made that sets up some local variables to hold our (controlled) version of those services, and injects them into the controller so that those are the ones to get used.  Then in our actual test we have assertions that are congruent with our expectations.  It looks like this:

```
describe('NavCtrl', function() {
    var scope, $location, createController;

    beforeEach(inject(function ($rootScope, $controller _$location_) {
        $location = _$location_;
        scope = $rootScope.$new();

        createController = function() {
            return $controller('NavCtrl', {
                '$scope': scope
            });
        };
    }));

    it('should have a method to check if the path is active', function() {
        var controller = createController();
        $location.path('/about');
        expect($location.path()).toBe('/about');
        expect(scope.isActive('/about')).toBe(true);
        expect(scope.isActive('/contact')).toBe(false);
    });
});
```

With this basic structure, you can set up all kinds of stuff.  Since we are providing the controller with our own custom scope to start with, you could do stuff like setting a bunch of properties on it and then running a function you have to clear them, then make assertions that they actually were cleared.

# `$httpBackend` Is Cool

But what if you are doing stuff like using the `$http` service to call out to your server to get or post data?  Well, Angular provides a way to mock the server with a thing called `$httpBackend`.  That way, you can set up expectations for what server calls get made, or just ensure that the response can be controlled so the results of the unit tests can be consistent.

This looks like this:

```
describe('MainCtrl', function() {
    var scope, httpBackend, createController;

    beforeEach(inject(function($rootScope, $httpBackend, $controller) {
        httpBackend = $httpBackend;
        scope = $rootScope.$new();

        createController = function() {
            return $controller('MainCtrl', {
                '$scope': scope
            });
        };
    }));

    afterEach(function() {
        httpBackend.verifyNoOutstandingExpectation();
        httpBackend.verifyNoOutstandingRequest();
    });

    it('should run the Test to get the link data from the go backend', function() {
        var controller = createController();
        scope.urlToScrape = 'success.com';

        httpBackend.expect('GET', '/slurp?urlToScrape=http:%2F%2Fsuccess.com')
            .respond({
                "success": true,
                "links": ["http://www.google.com", "http://angularjs.org", "http://amazon.com"]
            });

        // have to use $apply to trigger the $digest which will
        // take care of the HTTP request
        scope.$apply(function() {
            scope.runTest();
        });

        expect(scope.parseOriginalUrlStatus).toEqual('calling');

        httpBackend.flush();

        expect(scope.retrievedUrls).toEqual(["http://www.google.com", "http://angularjs.org", "http://amazon.com"]);
        expect(scope.parseOriginalUrlStatus).toEqual('waiting');
        expect(scope.doneScrapingOriginalUrl).toEqual(true);
    });
});
```

As you can see, the `beforeEach` call is very similar, with the only exception being we are getting `$httpBackend` from the injector rather than `$http`.  However, there are a few notable differences with how we set up the other test.  For starters, there is an `afterEach` call that ensures `$httpBackend` doesn't have any outstanding expecations or requests after each test has been run.  And if you look at the way the test is set up and utilizes `$httpBackend`, there are a few things that are not exactly intuitive.

The actual call to `$httpBackend.expect` is fairly self-explanatory, but it is not in itself enough- we have to wrap our call to `$scope.runTest`, the function we are actually testing in this case, in a function that we pass to `$scope.$apply`, so that we can trigger the `$digest` which will actually take care of the HTTP request.  And as you can see, the HTTP request to `$httpBackend` will not resolve until we call `$httpBackend.flush()`, so this allows us to test what things should be like when the call is in progress but hasn't returned yet (in the example above, the controller's `$scope.parseOriginalUrlStatus` property will be set to `'calling'` so we can display an in-progress spinny).

The next few lines are assertions about properties on `$scope` that will change after the call resolves.  Pretty cool, eh?

*NOTE:* In some places users have made it convention to have `scope` without the dollar sign when it is referenced as a var in setting up unit tests.  This doesn't seem to be enforced or emphasized particularly strongly by the Angular docs and I find it a little bit more consistent / readable to just use `$scope` like you do everywhere else, so that's how I've done things here.

# Conclusion

Maybe this is one of those things that others just take to a bit more naturally than I do, but learning to write unit tests in Angular was pretty painful for me in the beginning.  I found my understanding of how to do so to be mostly cobbled together from various blog posts and sources around the Internet, with no real consistency or definitive best practice other than that established by natural selection.  I wanted to provide some documentation of what I eventually came up with to help other people who might be in a tight spot, and just want to get coding instead of having to learn all of the quirks and idiosyncracies of Angular and Jasmine.  So I hope this article has been of use to you.

Unit next week, stay sassy Internet.

- Nathan 
