---
layout: post
title: "Learn Node.js The Troll Way"
date: 2013-02-06 20:31
comments: true
categories: [node.js,javascript,development]
---

## Server Side JavaScript ##

As many of you are probably aware, [Node.js](http://nodejs.org/) is all the rage with the kids these days.  It's so popular that users even have the nerve to [gall Google developers](http://code.google.com/p/v8/issues/detail?id=847#c15), insisting that the V8 JavaScript engine is important for things outside of mere Chrome.  Node has rapidly been evolving and maturing into the new hotness of the web development community.  Its core is driven by the idea of asynchronous input and output,
a way to manage the latency inherent in developing applications for the web.  With Node, you gain the ability to write JavaScript which runs on the server-side of an application- and the somewhat eyebrow-raising ability to create a server within JavaScript itself.

Throw in a sweet package manager for every sort of JS voodoo you can imagine ([npm](https://npmjs.org/)), and you've suddenly opened up the door to a whole new world of handy tools and tricks, accessible to many developers due to the ubiquitous nature of JavaScript on the modern web.  The V8 JavaScript engine on which it is based is has performed pretty well for a web-based language in [benchmarks](http://shootout.alioth.debian.org/u32/which-programming-languages-are-fastest.php).  We all know that benchmarks are even worse dirty lies than statistics, so what I personally think is really cool about Node is that it mandates one to approach concurrency with a direct focus from the start of application development.  Surely there's a lot to be said for not having to rip off and reinvent the wheel of horizontal scalability.  But I digress.

## Screen Scraping With Node.js ##

{% img /images/skyrim-guard.jpeg Go cast your fancy JavaScript somewhere else! %}

The purpose of this article is to give a quick flyby example, in which I will be demonstrating Node.js by constructing a screen-scraping bot to troll my brother on Reddit.  I had an idea to build an application which uses the Reddit API, to spam my brother's account with Skyrim quotes/dialogue in comments for entertainment purposes.  If he ever were to reply, bewildered, my bot would ping back: _"Problem, theonewhoquestions?"_  

Naturally, in order to do this, I needed to gather the Skyrim intel (quotes) first.  Originally I set out to write the crawler in Python as I have some experience with the venerable [BeautifulSoup](http://www.crummy.com/software/BeautifulSoup/) Module.  But I was already using Node a bit as a result of Twitter's Bootstrap framework, and I was curious to challenge myself to actually build something with it for fun and comprehensive learning.  So, I decided to investigate.

Turns out there are a few modules that come in handy for a task like this in Node.
``` javascript
    var jsdom = require('jsdom');
```
This is the idiomatic way to import modules in Node.  The jsdom module for Node enables us to simulate a DOM environment which many of us familiar with (working with client side code) for use in our Node script.  And naturally, it's as easy as one, two, callback!

Since I am familiar with using jQuery to parse the DOM, I opted to use it to extract the quotes from [this website](http://www.uesp.net/wiki/Skyrim:Guard), where they are contained within table cells ripe for the picking.  To do this with the jsdom module, you call the `jsdom.env` method.  As arguments we pass in the address of the HTML we wish to parse.
``` javascript
    jsdom.env('http://www.uesp.net/wiki/Skyrim:Guard', 
      [ 'http://code.jquery.com/jquery.min.js' ],
      function(errors, window) {
        var $ = window.$;
        $ = stripTags($);

        var $skyrim_quotes = $('tr td').filter( function(element, index, array) {
            if ( $(index).html().match(/^".*"$/) ) {
              return true;
            } else {
              return false;
            }
        });

        $skyrim_quotes.each( function() {
          var $scopedElem = $(this);
          var content = $scopedElem.html().stripHTMLSpecialChars().stripDoubleQuotes();
          
          console.log( content );

        }); 
      });
```
There's a lot going on here that merits explanation, so I will take a second to break down in more detail what is going on in this chunk of code.  We have an instance of the `jsdom` object so we can call the `env` method to bootstrap up a DOM to parse.  The first argument to this method (`'http://www.uesp.net/wiki/Skyrim:Guard'`) is the URL to query for the HTML to instantiate this DOM with.  You can also just pass in plain old HTML as a string if you happen to have some of that laying around in dire need of parsing.

The second argument to the `env` method is a list of scripts to be included in the virtual window (DOM).
``` javascript
    [ 'http://code.jquery.com/jquery.min.js' ],
```
In this instance and many of the examples given on the `jsdom` [Github page](https://github.com/tmpvar/jsdom), we include the jQuery library.  If one wanted to use Mootools or Underscore.js, I imagine that is also totally doable, although I have no anecdotal evidence to support this hypothesis.  For my purposes, jQuery was a comfortable and effective fit.

The *third* argument to the `jsdom.env` method, and arguably the most critical, is a callback function to be executed once the response has been received from the server (or immediately, in the case of passing in your own HTML).  
``` javascript
      function(errors, window) {
        // ...
      }
```
It takes two arguments:  The first is called `errors` and is an list of errors which you can inspect if something in the `env` method goes wonky (in the code I've presented here `errors` is ignored, although you still need to have it in the definition of your callback function).  The second is called `window` and it is the coup de grâce of what we are seeking: a bootstrapped, "invisible" DOM that our script can parse.

It's worth pausing for a second here to think about why the "Node way" results in what may seem to some people to result in an expansive sea of callback spaghetti (if JavaScript didn't already appear to you to be an expansive sea of said callback spaghetti).  Any time that Node encounters a situation which otherwise might block the execution of code (such as an HTTP GET request to an external service), it simply defines a callback function to be executed when that *event* occurs (i.e. when your GET request is finished).  

But onward to the trolling we must progress!  The very first thing I do in this brave new callback where we will be doing our DOM parsing is define a few variables.
``` javascript
    var $ = window.$;
    $ = stripTags($);
```
`jsdom` allows access to the jQuery object through the `window` object, and as I would be accessing it often enough to justify a shorthand method of access, that is what `var $ = window.$;` is all about.  So what's with that `stripTags` call?  Well, the values that I was after were plain text without any HTML inside, as said HTML in a Reddit comment might shatter the illusion that it could be a person typing said Skyrim quotes instead of a robot.  So, for example, some of the entries in the table cells have words *in italics* and I needed to get rid of these tags.  Ergo, my `stripTags` function.
``` javascript
    /* consumes jQuery object
       returns jQuery object */
    
	function stripTags($) {
      
      // Cleaning out anchor tags, italics, and one span which is a warning not
      // to edit for nice, readable quotes
      
      $('tr td a').contents().unwrap();
      $('tr td i').contents().unwrap();
      $('span').contents().unwrap();
      $('small').contents().unwrap();

      return $;
    }
```
Using `unwrap()` on client-side code willy-nilly like this would more likely than not b0rk some critical piece of functionality in your app, but I only care about the data that I am scraping so it's not really relevant here.  It gets the job done, which is to turn quotes which in their raw form look like

<blockquote>"You here to see the &lt;a href="/wiki/Skyrim:Igmund" title="Skyrim:Igmund"&gt;Jarl&lt;/a&gt;? No sudden moves, understand?"</blockquote>

into a nice clean version that looks like this:

<blockquote>"You here to see the Jarl? No sudden moves, understand?"</blockquote>

Thanks to that `$('tr td a').contents().unwrap();` statement.  It's a little bit of extra work, but trolling is serious business, and well worth the investment.  And as I said before, applying these operations globally to the DOM on a large-scale project would be overkill, but for my purposes here it was grand.

The next step was the find the quotes themselves.  A simple little `$('tr td')` yielded very good results, mostly what I was looking for, but there happened to be a bit of extra flotsam and jetsam table cells which contained content I was not after at all.  So I needed some way to differentiate the Skyrim quotes from anything else that happened to be in a table cell which was not relevant to the task at hand.  Hm, surely I can come up with a regular expression to help with that?
``` javascript
    var $skyrim_quotes = $('tr td').filter( function(element, index, array) {
        if ( $(index).html().match(/^".*"$/) ) {
          return true;
        } else {
          return false;
        }
    });
```
Here we have the lovely jQuery method `filter` being used to apply the simple regexp pattern `/^".*"$/` to our selection and returning only the elements that match.  This knocks out everything which does not adhere strictly to the "quote" pattern (string's first and last character are a double quote - `"`).  

Almost there now- still I needed to strip some HTML special characters such as `&lt;` and `&gt;` to get them especially clean.  And, of course, to strip the double quotes for aesthetic purposes.  I decided to bring a gun to a knife fight and add methods to `String`'s prototype.
``` javascript
    String.prototype.stripHTMLSpecialChars = function () {
      // There's a few quirks in the soup
      var str = this.replace(/&lt;/, '');
      str = str.replace(/&gt;/, '');
      str = str.replace(/&nbsp;\[sic\]/, 'y');
      return str;
    };

    String.prototype.stripDoubleQuotes = function() {
      return this.slice(1, this.length - 1);
    };
```
The solution for `stripDoubleQuotes()` feels a little bit kludgey, so I'd be curious to hear if anyone else has a better idea (I'm sure JavaScript is capable of sed-like string manipulation antics but this was this quickest way I could think of accomplishing the goal).  `stripHTMLSpecialChars()`'s removal of these "quirks" was based on a quick grepping of the results I was getting back to see what HTML special characters were being returned.  Used in the `jsdom` callback, our "sanitizing" and printing to the console of these quotes looks like this:
``` javascript
    $skyrim_quotes.each( function() {
      var $scopedElem = $(this);
      var content = $scopedElem.html().stripHTMLSpecialChars().stripDoubleQuotes();
      console.log(content);
    }
```
Bravo!  Now we have our hot, fresh, Skyrim quotes, eager to troll unsuspecting brothers with.  I opted to stash these quotes in a database (sqlite3) so I didn't have to ping the Skyrim wiki's servers every time they were needed (and also to keep track of which ones had been used already).  I won't go into a lot of gory details here about how working with a database in Node.js is, but suffice it to say for my purposes it was actually fairly straightforward.  Node has a handy `sqlite3` module that made working with the database fairly simple.  As it turns out, JavaScript being single-threaded-async is quite handy for tasks like this because the thread isn't going to block on the expensive IO operations.  If you want to pick on PHP, for instance, just note how long it takes a PHP application to make, say, 25 requests to external servers versus Node's same attempt with concurrency.

Stay tuned for the followup where I create the actual robot to talk to my brother, and if you're keen feel free to [check out the source](https://github.com/nathanleclaire/learnnodethetrollway) on Github.
