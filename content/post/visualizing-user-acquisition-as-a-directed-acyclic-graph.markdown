---
title: Visualizing User Acquisition as a Directed Acyclic Graph
layout: page
date: 2021-05-11T03:49:08.186Z
---
What is the silver bullet to convert people who have expressed an interest in your product (such as if they have signed up for a free trial) into customers? How do you expand existing accounts to make more? These are the age-old questions.

No one has the answers <sup><a href="#fn-1">1</a></sup> , but if we reflect on it, we probably find that it's likely they're highly dependent on your own particular product and market (or lack thereof) - and we also might find that, terrifyingly, there *are no silver bullets*. The werewolf runs free and unharmed. Many businesses will quickly run into prospects who misunderstand the value we can bring, object to the cost, or are just plain Doing It Wrong.

![](/images/senior_man_smiling_and_holding_screwdriver_bld027157.jpg)

Good businesses, upon reflection, might consequently feel like their model of user acquisition is not quite right (and God help the business who won't reflect on it at all). They will then take steps to try to remedy this problem. This very frequently involves user education. Every user, of course, will have a different engagement style, suite of motivations, and journey, which explodes the complexity of doing this effectively.

We might get lucky and have a user who loves listening attentively in seminars, but we also might have a user who hates sitting in seminars and happily blows off the "Product 101" presentation. Consequently, they never learn why screwdrivers are so great and we lose them as a lead.

 If your product is highly technical, user education becomes even more important - after all, nothing sucks quite like the hurdle of learning *someone else's software*. <sup><a href="#fn-2">2</a></sup> It's like a whirling dervish of a software engineer's least favorite things - being bad at stuff, feeling stupid, and having to work with other people. <sup><a href="#fn-3">3</a></sup>

It's tempting to believe that we can come up with a generalized, or at least "good enough" solution - the One Funnel to Rule Them All. But there's no end to the tower of turtles. Users act in unpredictable and erratic ways.

And software engineers, being conditioned as we are to frequently finding an existing solution ready-at-hand in polynomnial time on Stack Overflow, are particularly susceptible to being driven mad by the open-endedness of this difficult-to-optimize sandbox. But maybe we can we visualize and reason about the *system* of user acquisition to help drive the specifics?

## User Acquisition as a DAG

Usually we visualize user acquisition as a funnel -- a discrete set of logical steps from A to B to C, with one path. At every stage in trying to close the deal, more and more people will drop out - that's the unfortunate way of life. Enter this brute, the funnel.

![](/images/funnel.png)

But even though we model customer acquisition as a singular funnel for convenience's sake, no customer proceeds through one prescriptive linear flow in their process of deciding whether or not to buy, or revew, a product. This is especially true for the complex and multivariate needs of a team of users. Hence, I encourage anyone in the business of trying to obtain users to also think of their user success actions as a [directed acylic graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph). <sup><a href="#fn-4">4</a></sup>

![](/images/user_dag.png)

The graph's vertices (blue nodes below) and edges (*directed* connections between the nodes) flow from one to another, starting with an "entry" node such as a successful outbound hit. Prospects, in their path towards potentially becoming a successful customer, proceed to various stages at various times, frequently getting stuck at one or the other and running out of steam. Perhaps other things in their life became more important, and if you can identify the most commonly exited vertices, you can patch up those leaky spots and retain more.

To patch those leaks, there are a few strategies you can use.

**Breadcrumbs** - Perhaps users simply need to understand where to go next. If you can add some breadcrumbs, like an in-app tutorial, it can help highlight features of your product they otherwise might have overlooked. I would also highlight the low-hanging fruit that is targeted campaigns that end up in their email inbox. If you can have some intelligence to them, for instance, by encouraging people who got 4/5 of the way through your onboarding but bailed, you can really do a lot of damage that way.

**Removing Roadblocks** - Often, there will be a few noteworthy bottlenecks that you could widen up for people with a little elbow grease. It pays to take the time to examine where those are, and how you could improve the experience for your users.

**The Carrot** - Have you ever seen how Asana lights up and flashes colors at you when you complete a task? Feels good, doesn't it? Maybe there are ways your product can reward people for performing the actions that correlate with using your tool successfully. How can you help them feel good when they complete a core success loop?

![](https://blog.asana.com/wp-content/post-images/TaskCompletion_Loop.gif)

Last but not least, don't forget you can **Offer Help**. Users might be too shy and not wanting to both you, but with a little direct suggestion, they often can be coaxed into looking for help. Having them engage with a real person for support might well be the difference between a customer you obtain, and a customer you lose. For instance, maybe you could add a scheduled email showing off the content in the app as a continual path to re-entering your graph.

#### Footnotes

<ol>
<li>
<div id="fn-1">
I certainly don't. Or I'd be rich!
</div>
</li>
<li>
<div id="fn-2">
Some of you probably even felt a wave of revulsion wash over you just seeing the <i>words</i> "someone else's software".
</div>
</li>
<li>
<div id="fn-3">
I'm being a little tongue in cheek, so don't fly off the handle telling me how untrue this is - but you have to admit, engineers aren't known for being the most social kids on the playground.
</div>
</li>
<li>
<div id="fn-4">
It's easy to conjure up ways to visualize it with cycles as well, of course. However, the directionality of <i>successfully closed</i> leads is hard to debate: otherwise, salespeople wouldn't get paid. <i>Something</i> got them to sign, even if it was low-touch.
</div>
</li>
</ol>
