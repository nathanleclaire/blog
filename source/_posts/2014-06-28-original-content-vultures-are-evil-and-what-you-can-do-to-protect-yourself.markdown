---
layout: post
title: "Original Content Vultures are Evil, and What You Can Do To Protect Yourself"
date: 2014-06-28 17:58
comments: true
categories: [social media spam]
---

#  Here we go

{%img /images/tg/ouch.png %}

So lately I've had this problem where people will e-mail me, or complain on Twitter, that my website looks pretty mangled on their `[OS|browser]`.  This of course upsets me since I want the experience of using my site to be smooth and simple.  I'm no designer but I tried to make something that was both usable (loads quite quickly) and not too hard to look at.

So of course I investigate, and I'm led to find out that in several of these cases the unsuspecting viewers are stumbling across my site through a "gray hat" lead farming site.  It's called Tweetganic, and I'm sure it's not the only one of its kind but in case you're not familiar, here's what it does:

1.  Users sign up to use Tweetganic
2.  Users harvest links to other people's content and Tweetganic proxies them at a Tweetganic URL
3.  Users then share the links on social media.  When viewers access the URL they are bombarded with lead generating tactics such as a "Hire Great Angular Developers" banner or a modal which prompts them to sign up for the Tweetganic user's mailing list (NOT the generator of the original content!!).

It is a lead (your precious eyeballs) farming mechanism used by content vultures and it must be destroyed.

# Why is it so bad ?

Good question.

Initially I was intruiged by the premise of Tweetganic and even considered using it myself to promote my mailing list.  However, I decided against it due to my values which emphasize the importance of "consent-based marketing", where I make sure people *want* to receive my content (such as a mailing list) before sending it to them.  Tweetganic links try to trap users in a marketing funnel they don't neccessarily want to be in.

I get that people want to generate leads, and there's nothing wrong with generating leads.  But, and this brings me to my first specific beef with Tweetganic, these leads are non-consensual (to the content owners/producers) and they do nothing to give back to the content producers who are the true value creators here.  No outreach, no offers to pay for the privelege, no classy referral link.

Finding people using your stuff, greedily, for their own personal gain with no thought towards the blood, sweat, and tears that went into generating it feels like a dagger to the heart.

## Tweetganic promotes non-consensual re-use of original content with no respect or payment to the authors.

Many of us (writers) do what we do because we want the community to learn and grown and develop.  Yes we're also promoting ourselves, but we're also putting in the elbow grease to make it happen.  Without being derivative.  By building legitimate value.

My second specific beef with this practice ties into the first:

## Tweetganic will completely maul your website and make it look like utter crap.

This is how I found out it was being done to me.  People were complaining in various ways that my website looked bad.  I knew most of them probably weren't using older versions of IE (my website looks like crap in IE&lt;8 ☺ ) so I investigated.

Yeah, it turns out that Tweetganic is just really, really, bad at front end.  I guess that's what happens when you use other people's content cross-domain without their consent or knowledge, and can't modify their page directly.  You have to shove your hideous spam layer on top.

Taking my content is one thing.  But to take away the last tiny little scrap of aesthetic value that my hilariously-made-by-a-programmer-not-a-designer blog has?  That's war.

If you care about your content follow the tip below and participate in a community discussion about how to stop them, and all of their ilk.  If you want to be a good person then don't use tools such as this.

# I don't want this to happen to me.  What can I do about it?

EDIT: I've swapped out the "shaming" text for a trick which simply redirects to the original page (listed below), which I had previously just assumed wasn't possible due to cross-domain policies in browsers.

I've put the following piece of JavaScript/CSS on many of my pages, and you might want to follow suit with a similar snippet:

```
<style> html{display:none;} </style>
<script>
   if(self == top) {
       document.documentElement.style.display = 'block'; 
   } else {
       top.location = self.location; 
   }
</script>
```

Source: [Wikipedia](http://en.wikipedia.org/wiki/Framekiller)

Basically what it does is makes content unrendered by default and redirects the page to the original domain if the site is loaded in an iframe.

You could also set the `X-Frame-Options` HTTP header to `DENY` in your server config (if you don't need your page to load in iframes, and for 90% of sites why would you?).

# I was featured on Tweetganic and all I got was this lousy rant.

Let's cheerily call out offenders as we see them too, eh?

For instance, I have one offender for you to ruthlessly unfollow: the Twitter account @AngularJS_News.  In my opinion they should not be promoting the use of such a tool, it literally exists only to screw over content creators for personal gain.

That's about all from me on this topic for the time being.  Moral of the story: If you're going to make my website look like crap at least offer to pay me.

Until next time, stay sassy Internet.

- Nathan
