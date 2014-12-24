---
layout: post
title: "5 Reasons We Won Startup Weekend"
date: "2014-02-10"
comments: true
categories: [fixworthy,vagrant,startups,entrepreneurship,hacking,reasons]
---

This previous weekend I participated in [Ann Arbor Startup Weekend](http://annarbor.startupweekend.org/) and had a blast.  Our company's name is [Fixworthy](http://fixworthy.co) and we built a photo-based bug tracking app for real life (think Github Issues meets Instagram).

{{%img src="/images/swaa/fixworthy.jpeg" caption="Hail to the victors. " %}}

Of course we worked hard on it, lost some sleep etc. but everyone does that.  There were some special factors at play in our case that helped us win such as:

1. [Vagrant](http://www.vagrantup.com/) and Frequent Deploying
2. Emphasizing "Done Is Better Than Perfect"
3. Good Design and Aesthetics
4. Finding a Use For Everybody (especially developers)
5. Following the Pain and the Money

Of course, all of these are forces stem from having a smart, talented, and easy-to-work-with team as well.  Let's get into some specifics, shall we?

# Vagrant and Frequent Deploying

{{%img src="/images/swaa/vagrant.png" caption="Up up and away. " %}}

I'm going to start off with a technical point to hook in my fellow nerds here.  

The very first technical thing that we (the developers) did, on Friday night after working our way through the vision of the product and what we thought its most important features should be, was to get started hacking.  We knew that to ship a working product quickly it would be an enourmous boon to be: 

1. Working on the same platform so that any issues which came up would have ubiquitous solutions, *and*: 
2. Working in an environment that was extremely close to the environment we would be deploying our production solution to (ever have those awkward it-worked-on-my-machine production bugs?)

Most companies account for this by having everyone work in the cloud on EC2 instances or what have you, or simply by forcing their developers to all use the same operating system (which we kind of did a variant of).  In our case there was no way developing in the cloud was going to work (we had too little time or money) and our dev team was split about 50/50 between OSX and Windows so we decided to use [Vagrant](http://www.vagrantup.com/), a "free and open-source software for creating and configuring virtual development environments".  

Vagrant is awesome, although I'm a little disappointed they have moved away from their original logo which features this scrappy dude:

{{%img src="/images/swaa/vagrant_chilling.png" caption="" %}}

We made everyone download and install Vagrant / VirtualBox (which Vagrant depends on) and use [this configuration](https://github.com/bryannielsen/Laravel4-Vagrant), which orchestrates the installation of a LAMP stack and the [Laravel framework](http://laravel.com/) using Puppet.  It took a little while for all of the dependencies to install on everyone's computer but we were able to sit back and sip a little beer while Puppet did most of the heavy lifting.  Once Puppet was all done, everyone could point their host OS's browser to `http://localhost:8888` and be greeted by a freshly minted Laravel install.  Shared folders allowed us all to get started hacking right away, which was seriously awesome for productivity.

This system also made it super easy to deploy frequently, since we just pulled in our changes to a git repo hosted on the prod server, ran the migrations and database seeds and *voila*, we were done deploying.  No nasty production surprises.

One last point here, on the geeky technical side of things:  There was no squabbling over PHP vs. Rails or CodeIgniter vs. CakePHP or any of that kind of stuff that you are surely familiar with, we simply all worked towards the common good however we could.  We had a couple of guys who traditionally stuck to Ruby or .NET, for instance, that picked up front-end work since it was where they could be the most productive, the quickest.  This kind of put-the-team-first mentality is priceless for getting things done quickly.

# Emphasizing "Done Is Better Than Perfect"

{{%img src="/images/swaa/done_is_better.png" caption="Lookin' good. " %}}

We've all probably heard this one [a ton of times](http://www.etsy.com/blog/en/2013/why-done-is-better-than-perfect/), so I won't spend *too* much time on it, but I do believe it played a huge role in our ability to push forward as a team and succeed.  Especially on front-end stuff I have way too much of a tendency towards "perfectionism" that can be counterproductive at best and harmful at worst as I am stricken by analysis paralysis and self-doubt.

Whenever we had moments of self-doubt about the product, or our implementation (though these were surprisingly rare on the tech side) we asked ourselves: "Is this helping us to deliver a quality product that is aligned with our vision for what this should be?" and if the answer was no, we stoically carried onward.  There were definitely parts of the app that left something to be desired (security concerns are a notable one on the backend side- though hopefully the framework helps a bit with that), but there always are, and for a weekend project I was ecstatically happy with the end result.  

I was shocked how quickly we could ship something that was working, if not ideal, and begin validating it with users and prospective clients.  That creates a tight feedback loop and gets the commits a-flyin'.

# Good Design and Aesthetics

{{%img src="/images/swaa/fw_logo.png" caption="Lookin' good. " %}}

Did you know that users begin forming impressions of a website's "visual appeal" in [as little as 50 milliseconds](http://www.websiteoptimization.com/speed/tweak/blink/)?  That's 50 milliseconds quicker than the [minimum application response delay humans are able to perceive](http://stackoverflow.com/questions/536300/what-is-the-shortest-perceivable-application-response-delay).  In other words, users decide if your website is beautiful or if it is garbage very, *very*, quickly.

[Kelsey](http://www.klsy.co/) was our design ringer and boy am I ever glad she was on our team.  There's no doubt that [a picture is worth a thousand words](http://en.wikipedia.org/wiki/A_picture_is_worth_a_thousand_words) and having a designer allowed us to take our website from "awkward-Bootstrap-import-and-fuhgettaboutit" to "clean, lean, eye-candy *machine*".  A logo is a condensed visual statement-of-purpose-of-sorts and I was super happy with the logo designed for Fixworthy, which you can see above (I'm a little biased because my favorite color is orange).

Having good design instantly improves your social media presence (check that backdrop on our [Twitter page](twitter.com/fixworthy)!), the initial reaction that your users have as they begin forming a relationship with your product, and more.  It's well known that [big images increase conversion rates](http://econsultancy.com/blog/62391-do-bigger-images-mean-improved-conversion-rates-three-case-studies), and having those design chops on our side really gave us some serious momentum on our side towards converting the people who really needed to be swayed in this case- the judges.

# Finding a Use For Everybody (especially developers)

{{%img src="/images/swaa/steve_ballmer_is_awesome.gif" caption="This man knows. " %}}

When some of the hopefuls pitched their ideas or were trying to sell them to get people to join their team, there were a few who stood on stage and said in all honesty "I'm not looking for any other developers to join" while all the devs in the room's collective jaws dropped.  Our feelings of surprise were validated late on Saturday when about three or four companies went up to the mic again to try and persuade developers already engaged with one team to switch to their own.  

In a sense I can see how a technical founder might not want to run the risk of having a bunch of newbies or bad programmers stomping around in their precious self-written code, but at the same time it stunned me that anyone would turn away someone willing to help with such a short deadline in tow (especially with how tight the demand is for technical talent).  The odds of getting a real stinker in your group were pretty low, considering that it was a University of Michigan-centric event, and it struck me more as vanity than anything else that people were willing to turn away perfectly good (free!) talent.

Our company didn't turn anyone away and tried to find a use for everyone.  As mentioned, some of the developers were a little more comfortable with back-end stacks other than LAMP, and so they cordially agreed to work on the front-end.  Our team member [Greg](http://wilsonproductive.com/) felt that he was best at social media / marketing stuff, so he whipped up an Instagram and Twitter presence at lightning speed.  Our business team began pounding the pavement by doing market research, performing user testing, and getting in touch with potential customers (organizations for whom this technology would be useful, perhaps if they wanted private issue tracking).

All in all, we made a hugely concentrated effort to rake in as much value as possible from every single person who wanted to help.  This helped bolster everyone's moral and enthusiasm, let them play to their strengths, and paid off for us as a team.

# Following the Pain and the Money

{{%img src="/images/swaa/mo_money_mo_problems.jpeg" caption="" %}}

This is still a major pivot/focus point for the startup if we continue going (and there's a lot of wind in our sails right now), but I think that a large part of why the group was able to be successful was that we didn't kid ourselves about the fact that we were building something to create wealth by:

1. Easing pain points for people, especially those with cash to throw at the problem e.g. businesses and universities
2. Making money.

Granted, there was a lot of hand-wringing about *how* we were going to accomplish this, but I think several of the core engineers (particularly [Scott](http://scottdlowe.com/)) had a vision about this product was going to fly, and didn't let a relentless enthusiasm for making a fantastically great product interfere with the reality that we needed to make money from this somehow.  A favorite line to throw at our business team, when they would try to persuade us to take the product in a different direction, was "get us someone who will write us a check for the V1 of this app when it is finished".  That really put things into perspective.  Shouldn't every aspiring entrepreneur hear, "Yeah, but who's going to use (and pay for) that?" in response to one of their ideas?

This kind of zeal prevented us from making yet another recipe app or a product with questionable monetization potential.  I feel confident that at the very least the core Fixworthy product could make moves into a space where they were making life easier for powerful (read: those with budgets to spend on sotware) people's lifes a bit easier, and especially given the generally low standard for UI on enterprise software I'm optimistic about the opportunities in that market for easy-to-use products that are marketed well.

# Conclusion

I had a blast and learned a ton about technology and leading / working with a decent sized team.  We started the weekend with nothing and ended up with a company, however small and scrappy it was.  Best of all, we won.  [Who doesn't like to win](http://www.youtube.com/watch?v=GGXzlRoNtHU&feature=kp)?  

I had an inkling that it might be so when we were some of the last participants to get shooed out of the common space on Saturday night, but I didn't want to jinx us by bringing it up.  Besides, as all pseudo-mystics and hippies are so fond of pointing out, the journey is the destination.  Given that my last Startup Weekend company was less than satisfactory (though it was a long time ago), I couldn't be any happier.

Until next time, stay sassy Internet.  And don't forget to keep hustlin'.

- Nathan
