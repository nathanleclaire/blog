---
layout: post
title: "The (JavaScript) Question I Bombed In An Interview With a Y Combinator Startup"
date: 2013-11-16 17:30
comments: true
categories: 
---

About a year and a half ago, I was on the hunt for my first "real" job.  I knew that I wanted to be a "web developer" (whatever *that* enatils) but I had no idea where to begin.  I knew just a smidge of PHP.  I was developing websites in Classic ASP at my current internship, but I knew that was an antiquidated technology which was unlikely to help me in the modern job market.  As I had recently begun stomping around [Hacker News](https://news.ycombinator.com), I noticed that they had a "jobs" section in their header.  So I looked into things, saw that a few companies were hiring, and sent a few e-mails to companies that looked nice.

{% img /images/y-comb/y-combinator-logo.gif To hack and start things up. %}

# The Hunt

A few e-mailed me back and I managed to set up a phone screen with a company that does next-level web analytics.  Going into the interview I was filled with a mixture of apprehension and excitement.  After all, I knew that Silicon Valley was where the action was at, and I had no idea what kind of intricate or crazy questions they might ask me.  They had listed in their description a desire for strong JavaScript skills, which was appealing to me as I was rapidly learning to enjoy developing in this weird little language created by Brendan Eich.  *"I know jQuery pretty well,"*, I thought- *"What could possibly go wrong?"*

The developer who did my screen was pretty courteous and eased me into things a bit by talking about my background and experience.  I sheepishly admitted that I had studied philosophy in college, not computer science, and he put my concerns at ease by telling me that their founder had never finished college.  That made me feel better about things, since part of the reason I love technology so much is that it is so meritocratic.

So, without further ado, we began to investigate a coding problem.

# The Problem

INTERVIEWER: You're familiar with jQuery, right?

ME:  Yes, I've used it at work.  I like JavaScript.

INTERVIEWER: Great.  So, you're familiar with something like this, right?  Let's say you have a textbox and you want to make a call to the server to get some data every time the user does some typing, if you wanted to make autocomplete suggestions, for example... *(begins typing into a shared/remote codepad)*

```js
$(document).ready(function() {
	$('input').keypress(function() {
		$.ajax({
			// Call the server for some goodness...
		});
	});
});
```

ME: Oh yes, I see.  When the user presses down a key on the element, we will make a call.

INTERVIEWER: So, you may be able to guess, that there is a problem with this code.  It is very inefficient.  If you type a string with 30 characters into the text box, the server gets called 30 times.  Not good, we are having all kinds of issues with scalability so we can't afford to be writing code like this.

DEMO:

<input id="myBox1" type="text" placeholder="Type some stuff in me!" style="width: 30%;" /> <strong>Called Server <span id="called_times1">0</span> times...</strong>

<script>
$(document).ready(function() {
	$('#myBox1').keypress(function() {
		if (!this.count)
			this.count = 0;
		this.count++;
		$('#called_times1').html(this.count);
	});
});
</script>


ME: I see.

INTERVIEWER: So we only want to call the server after the user has been typing, then stops typing for 200 milliseconds.  That will give it the illusion of being instantenous while saving a lot of load on our servers and a lot of ajax handling in the JavaScript.  How would we do that?

ME:  Uh...

# What Really Happened

ME:  I think I would use... Um...

INTERVIEWER:  Well, do you know what a closure is?

ME:  Yeah!  Closures.  I've heard of those.

INTERVIEWER: What about `window.setTimeout` ?  Do you know about that?

ME:  I think that's JavaScript's version of a `sleep` function?

INTERVIEWER:  Kind of... 

ME:  I think I would... *typing awkwardly and struggling for 30 seconds*  I guess I'm not sure.

INTERVIEWER:  I appreciate your time but perhaps this isn't a good fit.

# What Should Have Happened

ME:  Hm, that's an interesting problem.  So, if we use `window.setTimeout` we can delay the call for 200 milliseconds.

INTERVIEWER:  Right.

ME:  But that's not going to help us in the case where the user is typing fast, or even just normal speed.  So we need a way to interrupt the timeout if the user keeps typing.

INTERVIEWER:  Exactly.

ME:  So, I know that when you call `window.setTimeout`, you get back an ID that uniquely references the timeout.  And you can use it to cancel the timeout if need be!  So we should just store the timeout ID in the `keypress` function closure, and if the user triggers a keypress event again before the timeout function triggers, we'll just cancel it and set a new one!

INTERVIEWER:  Sounds great!  What would that look like in code?

ME:  It'd look a little something like this...

```js
$(document).ready(function() {
	$('input').keypress(function() {
		if (this.timeoutId) 
			window.clearTimeout(this.timeoutId);
		this.timeoutId = window.setTimeout(function () {
			$.ajax({
				// do some stuff
			});
		}, 200);
	});
});
```

INTERVIEWER:  Clever.

ME:  I try.

DEMO:

<input id="myBox2" type="text" placeholder="Type some stuff in me!" style="width: 30%;" /> <strong>Called Server <span id="called_times2">0</span> times...</strong>

<script>
$(document).ready(function() {
	$('#myBox2').keypress(function() {
		if (!this.count)
			this.count = 0;
		if (this.timeoutId)
			window.clearTimeout(this.timeoutId);
		var that = this;
		this.timeoutId = window.setTimeout(function() {
			that.count++;
			$('#called_times2').html(that.count);
		}, 200);
	});
});
</script>

INTERVIEWER:  Now on to the next question...

# Conclusion

I bombed this interview but I learned something from it.  I know I could go in more confident and capable today.  It just goes to show you that not every setback in life has to be a bad thing.  Someday in the future I would like to work with Y Combinator or a Y Combinator-based startup, largely because I think there's so much opportunity for learning and growth.

Thanks for reading and I'll catch you next week,

Nathan

*EDIT*: Some commenters have pointed out my misuse of `clearInterval` as opposed to `clearTimeout`.  It turns out that this (mostly) works to clear timeouts, but is clearly not correct (it's meant to be used with `window.setInterval`).  I have fixed this now.
