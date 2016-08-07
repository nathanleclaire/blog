---
layout: post
title: "4 Smooth AngularJS Application Tips"
date: "2014-01-04"
comments: true
url: "/blog/2014/01/04/5-smooth-angularjs-application-tips/" 
categories: [javscript,hacking,angularJS,animations,tricks,tips,design patterns,ng-view,ng-show,tabs,promises,$q,$http,services,directives,five]
---

Anyone who follows my blog even a little closely can probably see that I <3 AngularJS:

* [How to Unit Test Controllers In AngularJS Without Setting Your Hair On Fire](https://nathanleclaire.com/blog/2013/12/13/how-to-unit-test-controllers-in-angularjs-without-setting-your-hair-on-fire/)
* [Don’t Fear Directives In AngularJS](https://nathanleclaire.com/blog/2013/12/07/dont-fear-directives-in-angular-dot-js/)
* [Fear and Loathing With Golang and AngularJS](https://nathanleclaire.com/blog/2013/11/30/fear-and-loathing-with-golang-and-angular-dot-js/)

As I've learned more about the framework, I've come to appreciate many of the design decisions in spite of their initial (beastly) learning curve.  For example, directives provide an absurd amount of flexibility and expressiveness in writing declarative HTML that is unmatched by jQuery-style imperative DOM twiddling.  But the learning curve on them, and other bits of Angular, is weird:

{{%img src="/images/smooth-angular-tips/js-learning-curves.jpeg" caption="Hearkens to the Emacs graph of yore. " %}}

Some things that should be pretty straightforward, like navigating from tab to tab in single-page web applications, can be a little confusing to cough up in code *100% GUARANTEED TO BE CORRECT &#0153;*.  So here's a blog article with some cool tips to help you out.

# Highlighting the active tab for the view

I touched on this a little bit in my unit testing article.  In many applications (single-page ones especially) you'll want to assign or get rid of classes on tabs or other navigation features to help the user understand where they're navigating to or from (see Bootstrap's `.active` class).  How do we set these conditionally in Angular when we are using partials, and the default routing solution rednering in the `ng-view` directive?  Simple.  We can use the `$location` service and declare an `ng-class` attribute that depends on the result of a simple `$scope` method.

In the controller:

```js
app.controller('NavCtrl', function($scope, $location) {
    $scope.isActive = function(route) {
        return route === $location.path();
    };
});
```

In the view:

```
<ul class="nav navbar-nav">
    <li ng-class="{active: isActive('/profile')}">
        <a href="#/profile"><i class="fa fa-dashboard"></i> You</a>
    </li>
    <li ng-class="{active: isActive('/find')}">
        <a href="#/find"><i class="fa fa-bar-chart-o"></i> Find Friends</a>
    </li>
    <li ng-class="{active: isActive('/network')}">
        <a href="#/network"><i class="fa fa-table"></i> Network </a>
    </li>
    <li ng-class="{active: isActive('/chat')}">
        <a href="#/chat"><i class="fa fa-edit"></i> Chat Room </a>
    </li>
</ul>
```

Plunker demo of this concept:

<iframe src="http://embed.plnkr.co/Yci9oM/preview"></iframe>

Very useful and IMO, very clean.

# Abstracting business / data providing logic into services

This is more of an architecture tip than a general solution for common problems, but with my [recent article on unit testing Angular applications](https://nathanleclaire.com/blog/2013/12/13/how-to-unit-test-controllers-in-angularjs-without-setting-your-hair-on-fire/) a commenter on Hacker News pointed out that for a variety of reasons I should be putting more of my functions / code that retrieves data to be used in `$scope` by the controller into services, freeing the controller to just "glue it all together" (this also makes mocking things like AJAX calls a lot easier by avoiding `$httpBackend`).  I hadn't really used services very much and all of the talk of factories etc., as well as a general dearth of actual examples in the official documentation on how or why to use them, left me a little bit hesitant to jump right in.  He was kind enough to provide some example code and it made things a bit more lucid for me.  Hopefully the following explanation will help to explain the use case for services as well as provide an illuminating example.

Let's say that you want to keep track of some data which multiple controllers can access.  Perhaps it is weather data, preloaded into the page upon load (we'll cover using AJAX in this case later in the article) and you need to access it in the user's menu bar at the top of the page (to display the current temperature) as well as in a view frame for visualizing complex weather data over time.  We could attempt to jerry-rig together a solution for communicating this from controller to controller using Angular's [event system](http://docs.angularjs.org/api/ng.$rootScope.Scope) or we could just chuck the aggregate data into `$rootScope`, but both of those situations are highly awkward from a standpoint of both future and present development.  The solution that Angular provides us for usecases where we need to share (possibly mutable) data between controllers, or interact with things outside of Angular-land (other than the DOM, which is what directives are used for) is to use services.  Services are singleton objects (only instantiated once) that serve as this kind of "bridge" or interface from Angular to the outside world or between different parts of your Angular application.  In case you're unfamiliar, services are usually created using the `factory` method on your application module and injected into controllers for use like so:

```js
app.factory('weatherService', function() {
    var weatherData = window.jsObjFromBackend.weather.data;
    return {
        // default to A2 Michigan
        state : 'MI',
        city: 'Ann Arbor',
        getTemperature : function() {
            return weatherData[this.state][this.city].temperature;
        },

        setCity : function(city) {
            this.city = city;
        },

        setState : function(state) {
            this.state = state;
        } 
    };
});
app.controller('MainCtrl', function(weatherService) {
    $scope.temperature = weatherService.getTemperature();    
});
```

You can use them in several controllers and they will save you the headache of trying to sync up data over multiple controllers.  They are also a great place to store `AWKWARD_CONSTANT_THAT_WOULD_OTHERWISE_BE_GLOBAL`.

# Retaining state when switching from view to view

Services also can save you a potential history headache when navigating from view to view.  If you have some kind of state in one view that you want to be preserved so you can navigate to another view, then back to the original view intact (instead of re-loading the partial which is Angular's default behavior), you will find this to be a very handy use case for a service.

For instance, if you wanted to keep track of where a user had scrolled in a `<div>` element with its `overflow` propert(y|ies) set to `scroll`, you could use a combination of a service and a directive to maintain this state.  We will keep track of where the user has scrolled in a service, and coordinate adjusting the element back to that `scrollTop` state in the `link` function of the directive (you can inject services into directives much like you inject them into controllers).

Our service is simple:

```js
app.factory('rememberService', function() {
    return {
        scrollTop: undefined
    };
});
```

Our directive does a little bit more:

```js
app.directive('scroller', function($timeout, rememberService) {
    return {
        restrict: 'A', // this gets tacked on to an existing <div>
        scope: {},
        link: function(scope, elm, attrs) {
            var raw = elm[0];  // get raw element object to access its scrollTop property
            
            elm.bind('scroll', function() {
                // remember where we are
                rememberService.scrollTop = raw.scrollTop;
            });

            // Need to wait until the digest cycle is complete to apply this property change to the element.
            $timeout(function() {
                raw.scrollTop = rememberService.scrollTop;
            });
        }
    };
});
```
We attach it to the `<div>` we want to affect like so:

```
<div class="scroll-thru-me" scroller>
 <div id="lots-of-stuff">
     . . .
 </div>
</div>
``` 

The element will render in the correct `scrollTop` location.  Obviously this service can be made more complex if neccesary to coordinate maintaining state in a large application.   
 
The following plunker, a modified version of the first plunker on this page, demonstrates the idea.  Try navigating to tab 2, scrolling around a bit, travelling back to view 1 and then back to view 2 yet again.  As you can see, the state of where the user has scrolled to is retained.

<iframe src="http://embed.plnkr.co/3ozt9s/preview"></iframe>

# Making AJAX calls from services

So what if you want to use Angular's `$http` service to retrieve or set some data on the server, and interact with it from a controller?  We know by now that we should be using services to perform this kind of data-getting, but how do we deal with this asynchrony?  Doing so is not too painful, we simply return the `promise` Angular gives us when we make an AJAX call, and use the `then` method to define our callback in the controller.  A simple example:

```js
app.factory('githubService', function($http) {
    var GITHUB_API_ENDPOINT = 'https://api.github.com';
    return {
        getUserInfo: function(username) {
            return $http.get(GITHUB_API_ENDPOINT + '/users/' + username);
        }
    }    
});  

app.controller('MainCtrl', function($scope, githubService) {
    // assuming $scope.username is set with ng-model
    githubService.getUserInfo($scope.username).then(function(data) {
        $scope.userInfo = data;
    });
});
```

But what if you want the service to take care of some more stuff (e.g. parsing the response for the desired data) for the controller so they don't have to mess with all that business logic?  As an example, note that the response from `'https://api.github.com/users/nathanleclaire'` returns


```
{
  "login": "nathanleclaire",
  "id": 1476820,
  "avatar_url": "https://gravatar.com/avatar/3dc6ac660128ff3640413d4036fed744?d=https%3A%2F%2Fidenticons.github.com%2F32974b06cb69bfa6e7331cd4a26dc033.png&r=x",
  "gravatar_id": "3dc6ac660128ff3640413d4036fed744",
  "url": "https://api.github.com/users/nathanleclaire",
  "html_url": "https://github.com/nathanleclaire",
  "followers_url": "https://api.github.com/users/nathanleclaire/followers",
  "following_url": "https://api.github.com/users/nathanleclaire/following{/other_user}",
  "gists_url": "https://api.github.com/users/nathanleclaire/gists{/gist_id}",
  "starred_url": "https://api.github.com/users/nathanleclaire/starred{/owner}{/repo}",
  "subscriptions_url": "https://api.github.com/users/nathanleclaire/subscriptions",
  "organizations_url": "https://api.github.com/users/nathanleclaire/orgs",
  "repos_url": "https://api.github.com/users/nathanleclaire/repos",
  "events_url": "https://api.github.com/users/nathanleclaire/events{/privacy}",
  "received_events_url": "https://api.github.com/users/nathanleclaire/received_events",
  "type": "User",
  "site_admin": false,
  "name": "Nathan LeClaire",
  "company": "Systems In Motion",
  "blog": null,
  "location": "Ann Arbor",
  "email": null,
  "hireable": false,
  "bio": null,
  "public_repos": 18,
  "public_gists": 7,
  "followers": 12,
  "following": 9,
  "created_at": ""2012-02-26"
  "updated_at": ""2014-01-04"
}
```

There's quite a bit of information here, and with more complex API calls response will be full of nested objects and arrays.  What if we just wanted to get the `avatar_url` with `githubService.getUserAvatarUrl(username)` and didn't care about any of the other stuff?  We can use promise chaining to take care of this logic in the service.  Whatever is returned from the callback on the `then` method which has been invoked on the result of our `$http.get()` call (a promise object) will be passed to the callback function on the controller promise's `then` method:

```js
app.factory('githubService', function($http, $q) {
    var GITHUB_API_ENDPOINT = 'https://api.github.com';
    return {
        getUserAvatarUrl: function(username) {
            return $http.get(GITHUB_API_ENDPOINT + '/users/' + username).then(function(res) {
                // Though our return value is simple here, it could easily involve searching/parsing
                // through the response to extract some metadata, higher-order information, etc. that
                // we really shouldn't be parsing in the controller 
                return res.data.avatar_url;
            });
        }
    }    
});

app.controller('MainCtrl', function($scope, githubService) {
    // assuming $scope.username is set with ng-model
    githubService.getUserAvatarUrl($scope.username).then(function(avatarSrc) {
        $scope.avatarSrc = avatarSrc;
    });
});
```

Smooth.

Plunkr demo:

<iframe src="http://embed.plnkr.co/e9MHuI/preview"></iframe>

# Conclusion

That's all for now, folks.  Hope you've picked up some useful stuff along the way.  And as always, stay sassy Internet.

- Nathan
