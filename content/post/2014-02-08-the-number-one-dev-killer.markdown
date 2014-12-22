---
layout: post
title: "The Number One Dev Killer"
date: "2014-02-08"
comments: true
categories: [productivity,entrepreneurship,development,growth hacking,RethinkDB]
---

{{%img src="/images/dev-killer/rage.gif" caption="One of those days? " %}}

I frequently find myself fascinated by modern technology.  I mean, we went from computers that are the size of buildings to computers of equivalent power that fit in your pocket in ~50 years (I'll leave you to decide if it's sad or not that we use them mostly to look at pictures of cats and argue on the Internet).  A pretty impressive feat if you ask me, especially considering that 50 years is just about nothing in geographic terms.

What always fascinates me the most, however, is people and how they interact with (and create!!) new technology.  Especially being immersed in developer culture, I've start to see the same patterns over and over again and begun learning what makes some projects (especially when people are working in isolation) fail to get traction, and what makes some projects so wildly successful.  So today I'm going to write about a story to demonstrate a point about the thing which is, in my opinion, a huge killer of developer productivity.

# A Story About Mailing Lists

Do you recognize this guy?

{{%img src="/images/dev-killer/mailchimp.jpg" caption="" %}}

Probably at least looks familiar, right?  It's the [MailChimp](http://mailchimp.com) monkey.  How about this guy?

{{%img src="/images/dev-killer/hermes.jpg" caption="" %}}

It's [Hermes](http://en.wikipedia.org/Hermes), the Greek god of communication.  But unless you're a theology buff, Freddie the MailChimp mascot was probably a lot more meaningful to you in a modern context than Hermes.  So what?  Let me tell you a story to explain what I'll be getting at.

Now that I've started getting some traffic to my blog, and received a variety of emails from readers, I wanted to get a mailing list up.  You know, nothing fancy, just an email that I send out every once in a while to give people a chance to catch up with what I've been writing about this week.  So what do I do?

I could use [MailChimp](http://mailchimp.com), a rock-solid and proven standby that is good enough for people like [Andrew Chen](http://andrewchen.co) and [Patrick McKenzie](http://www.kalzumeus.com) and obviously should be good enough for me.  But what did I do?  Like a "good" hacker, I started writing my own (In addition to just wanting a cool project, for some reason I was embarassed about the possibility of people know that I use MailChimp.  I don't know why, I guess I just have some kind of weird DIY fetish).  It was going to be called [Hermes](http://github.com/nathanleclaire/hermes), written in Express/Node.js, and I was totally stoked.  Mostly because now I was going to attempt to re-invent MailChimp instead of doing more important, but less sexy, things with my time.

I got about this far (I'm skipping over some boilerplate):

```javascript
function sendSingleMail(subject, to) {
    getSignupEmailTemplate({
        to: to
    }, function(html) {
        mailgun.sendRaw("Nathan LeClaire <nathan.leclaire@gmail.com>", [to.email],
            'From: nathan.leclaire@gmail.com' +
            '\nTo: ' + to.email +
            '\nContent-Type: text/html; charset=utf-8' +
            '\nSubject: ' + subject + '\n\n' +
            html,
            function(err) {
                if (err) console.log("there was an email error", err);
                else console.log("successfully sent email to " + to.email);
            }
        );
    });
}

function getSignupEmailTemplate(context, callback) {
    var tmpl = jade.renderFile("views/signup-email.jade", context, function(err, html) {
        if (err) {
            console.log("error rendering jade template");
        } else {
            callback(html);
        }
    });
}

function main(conn) {
    var subscribers = r.db("hermes").table("subscriber");
    app.post("/email_signup", function(req, res) {
        var email = req.body.email;
        subscribers.insert({
            email: email,
            name: "",
            subscriptionConfirmed: false
        }).run(conn, function(err, result) {
            if (err) {
                console.log("[ERROR] failed to insert email from someone... ", err);
                res.json({
                    success: false
                });
            } else {
                sendSingleMail("Hi! I hear you'd like to subscribe to my blog.", {
                    email: email
                });
                res.json({
                    success: true
                });
            }
        });
    });

    app.listen(3001);
}
```

Before I started to say to myself: "Nate, are you being reasonable or are you just being cheap?  And why are you doing this instead of working on other, more low-hanging fruit to make your blog and side-projects more successful?  [Check For Broken Links](http://github.com/nathanleclaire/checkforbrokenlinks) *still* hasn't ever been deployed!"<sup id="foot1return"><a href="#foot1">1</a></sup>.  Though the Check For Broken Links comment was a low blow, I knew I was right.  

# Enlightenment

So I bit the bullet and used MailChimp instead.  You can see the results of my "labor" in the left sidebar of my blog, and I'm actually ecstatic I decided to go with them instead of writing my own mail management system.

Why?  Because all of the time I saved by going the MailChimp route, instead of creating something original but inferior, allowed me to spend more time doing other, more valuable things.  For that matter, the influx of reader emails that I was anticipating and hoping for hasn't really materialized, and at the time of writing I have all of two people on my mailing list :D (myself and my girlfriend- though I'm working on improving this).  I'm glad to have one less (giant) thing on my todo list, and I don't feel like a failure since I didn't waste a bunch of time on something that isn't paying dividends right away (though I think it will in the future).  And I get all of the niceness, including analytics and a crazy awesome Web UI, for the small price of a MailChimp logo on my signup form.  Sign me up!

Coming back to the Freddie the Chimp vs. Hermes comparison- Why use an untrusted brand / sketchy open source product when you can use a battle-hardened old friend? 

The point that I'm getting at, if you haven't guessed it already, is that developers (as I did in this case) oftentimes get their potential productivity murdered, hard, by [Not Invented Here Syndrome](http://en.wikipedia.org/wiki/Not_invented_here).  Who among us has met the stubbornly anti-framework programmers that always insist they could do a better job themselves, even with the absurd wealth of (oftentimes free) tools available for development nowadays?  How many client-side JavaScript MV* frameworks exist because their creators weren't satisfied with simply improving existing solutions?  I know it's an easy target, but allow me to list a few:

+ [Angular](http://angularjs.org)
+ [Backbone](http://backbonejs.org)
+ [Meteor](http://meteor.com/)
+ [React](http://facebook.github.io/react/)
+ [Flight](http://twitter.github.io/flight/)
+ [Singool.js](http://fahad19.github.com/singool/)
+ [Knockout](http://knockoutjs.com/)
+ [Sammy.js](http://sammyjs.org/)
+ [Ember.js](http://emberjs.com/)
+ [Maria](https://github.com/petermichaux/maria)
+ [Terrific Composer](http://terrifically.org/composer/)
+ [Rivets.js](http://rivetsjs.com/)
+ [Synapse](http://bruth.github.com/synapse/docs/)
+ [Ractive](http://www.ractivejs.org/)

{{%img src="/images/dev-killer/incredulous.gif" caption="" %}}

Yeah.

Though he is speaking to a slightly different context, I feel that Keith Perhac breaks the issue down nicely in this [Kalzumeus Software Podcast](http://www.kalzumeus.com/2012/05/18/kalzumeus-podcast-ep-2-with-amy-hoy-pricing-products-and-passion/):

> And really, I think there’s also a… so, this is not just the Hacker News crowd, this is not just the Slashdot crowd, this is not just the techie crowd, there are a lot of people. I think the naysayers are the people who have more time than money, is honestly what it comes down to.
>
> Because, honestly, if I had a ton of time, if I was working a nine-to-five job, had a set number of hours a day I worked at a fixed income, at that, and I needed time-tracking software, I would probably write my own on the weekend because I have more time than I have money at that point.
>
> For someone who’s trying to run or start their own business, they suddenly have more money than they have time. Not that they’re making tons of money but because their time is much more valuable because there are so many other things they could be doing.

This seems to be the gospel truth right here.  People can and should be focusing less on reinventing the wheel, and more on their core value proposition.

Note that I'm mostly talking about things in the context of individual developers working by themselves, or in coordination with fairly small teams, not in large cutting-edge organizations such as the type discussed in [this article by Joel Spolsky](http://www.joelonsoftware.com/articles/fog0000000007.html), where he makes an argument in favor of "Not Invented Here Syndrome".  I agree with many of the points he makes here (no off-the-shelf web server will ever be as crazy fast as Google's and that's their business advantage), but I also feel like making an argument in favor of NIH is kind of dangerous.  Not that Joel has an obligation to look out for everyone's best interests or anything, but I'd be shocked if he'd never come across a business situation where a company was investing waaaay too many resources into reinventing the wheel when they could have just bit the bullet.  This is, after all, the man who invented Wasabi, a specialized dialect of Visual Basic roasted hilariously in this post by his [future business partner Jeff Atwood](http://www.codinghorror.com/blog/2006/09/has-joel-spolsky-jumped-the-shark.html):

> FogBugz is written in Wasabi, a very advanced, functional-programming dialect of Basic with closures and lambdas and Rails-like active records that can be compiled down to VBScript, JavaScript, PHP4 or PHP5. Wasabi is a private, in-house language written by one of our best developers that is optimized specifically for developing FogBugz; the Wasabi compiler itself is written in C#. 

It may have worked for Fog Creek, but a lot of weird technical decisions have ended up working out for people (like [transpiling PHP to C++](http://www.hhvm.com/blog/)).  Would you want to maintain *that* codebase?

# The Flipside

The flipside of this, of course, is equally poisionous, and I am going to describe a type of person that you and I both know to illustrate this point.  I think if you are involved in the technology community pretty heavily you will perhaps find this person eerily familiar.

This type of person is passionate about technology.  In fact, they are so passionate about it that they become convinced that it is a panacea for every problem they might possibly encounter.  They put more importance on theoretical wanking and "purity" than on execution and delivery, and they jump from framework to framework without ever putting in any actual mental elbow grease.  They are a perennial "Hello Worlder", always chasing after the hot new thing.

They probably mock the PHP or Rails programmers who are too busy getting stuff done to hear or care.  They may have a passion for exploration and learning, which is good, but they lack wisdom and insight.  Often this can be the same kind of person who may be interested in starting their own company, but lacks the practical depth to find something that has good product/market fit.  Instead they may try to solve problems that nobody has, or let the technology choice dictate the business direction instead of the other way around.

I have been this person on and off.  It's no more fun them than it is to be around them.  I think one should shy away from being this guy, as much as one should shy away from being a NIHSer.  In my opinion, you should keep an open mind about things and not let your ego get in the way of being a developer who's genuinely enjoyable to be on a team with.  Spoiler alert:  you are not right 100% of the time.

# Conclusion

Go forth and hack, sisters and brothers.  Just put some thought into using the right tool for the right job, and getting things done FAST instead of learning the newest hotness (which may cause you more headaches than it prevents).  There's nothing wrong with a box running MySQL as its only database, or using just jQuery on your front end if that's all you need, or developing an iOS app instead of an HTML5 one written with PhoneGap and AngularJS.  Let the tool fit the situation, and get things done (especially if you're starting a company).

Until next week, stay sassy Internet!  Oh, and subscribe to my mailing list already.  You're killing me over here.

- Nathan

<span id="foot1"><a href="#foot1return">(1)</a></span> : It's kind of like my "[Chinese Democracy](http://en.wikipedia.org/wiki/Chinese_Democracy)".
