---
layout: post
title: "Dragging and Dropping Images From One Browser Tab to Another In AngularJS"
date: 2014-01-11 17:21
comments: true
categories: 
---

{% img /images/drag-drop-angular/demo.gif Nice. %}

So, I catch a lot of flak for not having a [Facebook](https://facebook.com).  I used to have one about six years ago, when `<trolling>` it was actually cool, our parents weren't on it, and we had no idea the NSA was watching our every little status update `</trolling>`.  Then, for a variety of reasons, I deleted it.  Since then, people have complained endlessly about a dearth of Nate on social media, so I have started on a new website/project called The Natewerk, which is going to be the #1 social network for people who know me.

It's written using [Node.js](http://nodejs.org) and [Angular.js](http://angularjs.org), and part of the functionality that I wanted was to have the ability for users to drag an image from a separate tab and drop it into the Natewerk tab, [Imgur](http://imgur.com) style, taking an action appropriate for where the user was located in the app.  For instance, if they were on their profile page, I want the app to automatically upload that image to the server (perhaps with a prompt to confirm, also like Imgur), so they can easily add pictures of themselves to their profile.  If they were in the chatroom, it would show the image in the currently active conversation, so that people can post funny gifs/pictures and also easily post images for other people to see (this is one of the annoying things about Skype, in my opinion- you can drag and drop files but it won't display inline, the person you're chatting with has to download it).

Googling around found a few promising articles:

- [Drag and Drop File Upload with AngularJS](http://wisercoder.com/drag-drop-image-upload-directive-angular-js/) from [One Mighty Roar](http://onemightyroar.com/)
- [Drag and drop image upload directive for Angular.js](http://buildinternet.com/2013/08/drag-and-drop-file-upload-with-angularjs/) from [Wiser Coder](http://wisercoder.com)

But neither really gave me what I wanted, which was dragging and dropping from other tabs with the body-modal kind of effect that Imgur has.  So I set out to create my own.

# Creating a `<char-flasher>` directive

<iframe src="http://embed.plnkr.co/PmTUfAKXZQOc2dj01pcs/preview"></iframe>

I wanted the ability to display some text on the screen with dots that blinked, as shown above, to display text such as `"Drop image to display in chat..."` to make the process a bit more responsive and encouraging.  This kind of directive would also be reusable for creating fancy flashing text in the future as well (for example, if we wanted to display a `"{{user}} is typing..."` message in chat like many chat clients do).  I quickly cooked up a directive that can be used like so:

```
<char-flasher display-text="Drop image here to display in chat..." flash-char="." flash-interval="200"></char-flasher>
```

We pass in parameters here to have an eye towards reuse, although for now it is fairly geared towards the use case of a message with dots at the end (though you can use any character you want, not just `'.'`).  `display-text` is the message to display.  `flash-char` is the character to flash (it's assumed that this character is repeated at the end of the `display-text` string).  We pass these attributes as `'@'` parameters, so they will be interpreted literally.  We also set the directive to stop the `$interval` call we are using the animate the dots in case the directive is destroyed (this prevents memory leaks / wasted resources).

The code for the directive:

```js
app.directive('charFlasher', function($interval) {
  return {
    restrict: 'E',
    scope: {
      displayText: '@'
      flashChar: '@',
      flashInterval: '@'
    },
    template: '{{ realContent }}{{ flashingChars }}',
    link: function(scope, element, attrs) {
      var splitMessage = attrs.displayText.split(attrs.flashChar);
      var realContent = splitMessage.shift();
      var numFlashingChars = splitMessage.length;
      scope.flashingChars = attrs.flashChar;
      scope.realContent = realContent;
      var intervalId = $interval(function() {
        if (scope.flashingChars.length >= numFlashingChars) {
          scope.flashingChars = '';
        } else {
          scope.flashingChars += attrs.flashChar;
        }
      }, attrs.flashInterval);
      element.on('$destroy', function() {
      	$interval.cancel(intervalId);
      });
    }
  };
});
```

Not perfect, but pretty fun, and useful for our purposes.

# Creating the drag and drop directive

So, when the user drags an image from another tab over our application, we want the screen to be blanketed with a semi-transparent dark overlay while our message displays, and then when they drop it we want to do something with that image's `src` attribute, like use it to upload the image to our server.

So we have to come up with a solution to this, and preferably do it in a manner that's idiomatic to Angular.  I ended up using jQuery in my final solution to make some things a bit easier, but I'm sure there are some craft souls out there who could do everything with just the jQuery lite implementation Angular ships with.

I came across [this blog post](http://css-tricks.com/snippets/jquery/append-site-overlay-div/) by Chris Coyier that provided me information on how to create the "body-modal" effect.  It's pretty good, but it could be a bit more Angular-ey if we're going to use it in our app.  We'll start by creating a `<div>` right above the `</body>` tag that will serve as our dark overlay, and we'll use `ng-show` to decide if it should be showing or not:

```
<div id="overlay" ng-show="darkBody"></div>
```

Then we can add to our CSS file:

```css
#overlay {
    height: 100%;
    opacity: 0.6;
    position: absolute;
    top: 0;
    left: 0;
    background-color: black;
    width: 100%;
    z-index: 5000;
}
```

On our main controller we'll set some methods for manipulating this overlay:

```js
app.controller('MainCtrl', function($scope) {
    $scope.darkBody = false;

    $scope.darkenBody = function() {
        console.log('darkening body...');
        $scope.darkBody = true;
    };

    $scope.lightenBody = function() {
        $scope.darkBody = false;
    };
});
```

We'll declare this controller on our `<html>` tag, which is also where we declare our `ng-app` directive:

```
<html ng-app="nateWerk" ng-controller="MainCtrl">
```

Sweet.  Now we will create the create the `imageDragDropUpload` directive, which will be an attribute directive we place on `<body>`.  This is so the user can drag/drop the images anywhere on the page and everything will still work (note: the `<body>` `height` property must be set to 100% of the screen height for this all to work).

We define a function for darkening the body and bind it to the `dragenter` and `dragover` directives, so the first part of the link function for our directive looks like this:

```
var darkenBody = function(event) {
    event.preventDefault();
    scope.$apply(function() {
        scope.darkenBody();
    });
};
elm.bind('dragenter', darkenBody);
elm.bind('dragover', darkenBody);
```

Our directive doesn't have an isolate scope, so we have access to the `darkenBody` method from `MainCtrl`'s scope (if you wanted multiple drag and drops into different areas of the page you should create one with isolate scope, but with this style there will only ever be one instance of the directive).

The `drop` binding is a little bit trickier, but not too bad.  We use jQuery to do a little bit of parsing of the content (HTML) that was handed to us, and get the `src` attribute to do with it what we will (in this case, add to an imageService so the controller can follow along).  Specifically, we use `event.dataTransfer.getData` to get the HTML that was dropped onto the page (see [this MDN documentation](https://developer.mozilla.org/en-US/docs/DragDrop/Recommended_Drag_Types)), and create a new jQuery element out of it.  We filter this jQuery element for the `<img>` because sometimes multiple HTML elements are present in the dragged/dropped content.  Then we hide the body overlay:

```js
event.preventDefault();
var imageSrc = $(event.originalEvent.dataTransfer.getData('text/html')).filter(function(i, elm) { 
	return $(elm).is('img'); 
}).attr('src');
imageService.pushImage(imageSrc);  // Will append to list of images dropped into app
scope.lightenBody();
```

Pretty cool and useful in my opinion.  Hopefully your imagination is going crazy with possibilities in all sorts of directions right now, since this could be expanded to different types of content, including files from the user's computer and so on.  It'd benefit from a bit of animation and such as well.

I wasn't sure how Plunker/iframes would handle this, so I made a demo viewable [on Github](http://nathanleclaire.github.io/angdragdropdemo).

I'm hotlinking the images here, but please don't do this in production, it's rude (upload them to your own server instead).

# Conclusion

This was a fun thing to learn how to do in AngularJS.  Since this uses HTML5 APIs, it won't work in older browsers, but I haven't thoroughly tested it to see where it will work and where it will not (seems to go over well in Chrome, Safari, and Firefox on a variety of OSes).  Ultimately it makes me excited for the future of Angular, the browser, and the NateWerk.

Until next time, stay sassy Internet.

- Nathan
