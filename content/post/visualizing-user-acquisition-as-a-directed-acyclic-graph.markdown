---
title: Visualizing User Acquisition as a Directed Acyclic Graph
---
What is the silver bullet to convert people who have expressed an interest in your product (such as if they have signed up for a free trial) into customers? How do you expand existing accounts to make more? These are the age-old questions.

No one has the answers <sup><a href="#fn-1">1</a></sup> , but if we reflect on it, we probably find that it's likely they're highly dependent on your own particular product and market (or lack thereof) - and we also might find that, terrifyingly, there _are no silver bullets_. The werewolf runs free and unharmed. Many businesses will quickly run into prospects who misunderstand the value we can bring, object to the cost, or are just plain Doing It Wrong when they try to get started with it. e.g.:

USER: I need to get these screws into this piece of wood.

BUSINESS: Great! We can help with that. Here, use this. _(hands USER a screwdriver)_

USER: Hm, ok. _(begins bashing screws into wood with the handle)_ This isn't a very good tool. It hurts my hands.

BUSINESS: . . .

![](/images/senior_man_smiling_and_holding_screwdriver_bld027157.jpg)

Good businesses, upon reflection, might consequently feel like their model of user acquisition is not quite right (and God help the business who won't reflect on it at all). They will then take steps to try to remedy this problem. This very frequently involves user education. For instance, the BUSINESS in the silly take above might say "Oh, _(nervous laughter)_ that's not exactly how it's done. Here, let us sign you up for one of our Using a Screwdriver 101 Seminars so you can learn! Then you'll see why our screwdrivers are worth the price."

But _every_ user will have a different learning style, suite of motivations, and journey, which explodes the complexity of doing this effectively. We might get lucky and have a user who loves listening attentively in seminars, but we also might have a user who hates sitting in seminars and happily blows off the "Using a Screwdriver 101" presentation. Consequently, they never learn why screwdrivers are so great and we lose them as a lead.

 If your product is highly technical (and I'll address software specifically here since that's my area of expertise), user education becomes even more important - after all, nothing sucks quite like the hurdle of learning _someone else's software_. <sup><a href="#fn-2">2</a></sup> It's like a whirling dervish of a software engineer's least favorite things - being bad at stuff, feeling stupid, and having to work with other people. <sup><a href="#fn-3">3</a></sup>

It's tempting to believe that we can come up with a generalized, or at least "good enough" solution - the One Funnel to Rule Them All. But there's no bottom to the bucket of crabs. As soon as one door opens, another closes. It's maddening.

And software engineers, being conditioned as we are to frequently finding an existing solution ready-at-hand in polynomnial time on Stack Overflow, are particularly susceptible to being driven mad by the open-endedness of this difficult-to-optimize sandbox. But maybe we can we visualize and reason about the _system_ of user acquisition to help drive the specifics?

## User Acquisition as a DAG

Most people are familiar with the idea of a visualizing user acquisition as a funnel. It's so common that I alluded it it above without even introducing the concept. Naturally, at every stage in trying to close a deal, more and more people will drop out - that's the unfortunate way of life. Therefore, we have ways to track and visualize the various parts of the customer acquistion lifecycle - we'd prefer them to get to CLOSED (WON) state, but only a certain % of them will actually get there.

But even though we model customer acquisition as a funnel for convenience's sake, no customer proceeds through one, prescriptive linear flow (especially considering the complex and multivariate needs of a _team_ deciding to purchase or ditch your product). Instead, customer acquisition is much more like a [directed acylic graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph), where the vertices (blue nodes below) and edges (_directed_ connections between the nodes) flow from one to another, starting with an "entry" node such as a succesful outbound hit.

![](/images/user_dag.png)

- Breadcrumbs, removing obstacles, & carrots
- There is a reason why funnel and retention visualizations are so popular in analytics tools like Mixpanel.


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
</ol>