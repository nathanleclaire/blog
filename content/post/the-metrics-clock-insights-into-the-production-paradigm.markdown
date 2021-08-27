---
title: "The Metrics Clock: Insights Into the Production Paradigm"
layout: post
date: 2021-08-27T06:02:16.043Z
categories:
  - programming
---
López de Prado has a paper, [The Volume Clock](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2034858), where he talks about sampling bars based not on the mere ticking of the clock, but rather when information actually arrives to the market, for instance when enough dollars or shares have changed hands. I submit that a similar operation could be applied in DevOps to make sampling smarter and potentially to obtain better results in machine learning use cases for operational telemetry ("[AIOps](https://www.gartner.com/smarterwithgartner/how-to-get-started-with-aiops/)", if you will).

## Better Bars

As it stands today, many of you sample or aggregate your production data somewhat haphazardly. In the case of distributed tracing, often a sampling decision is made randomly at the root of the call tree, and propagated around to descendants, resulting in 1/N traces being [sampled](https://www.jaegertracing.io/docs/1.25/sampling/). Meanwhile, with metrics systems such as [Prometheus](https://prometheus.io/), metrics are gathered according to a predefined interval (15 seconds is a common default), and as they age, aggregated or "smooshed" further by replacing their raw values with averages. This allows teams to manage the operational burdens (including cost) that would otherwise be infeasible, but it has a big tradeoff too -- you might not have the exact right data available when you need it. Production mysteries will continue to plague you, and most teams find themselves on a tightrope walk trading off ever-increasing monitoring costs and the stress of not being able to definitively answer questions about what's happening in production.

But since I came across the concepts introduced in The Volume Clock and related work from de Prado, I've had a few fresh new ideas how you might be able to do this. To catch you up on the relevant ideas from de Prado, he examines novel approaches to generating "bars" such as you might see in a stock technician's candlestick chart from the underlying tick (trade) data. Almost every data feed offers the traditional "time bars" where you can visualize the open, high, low, and close price traded for that interval over time, but such bars are not ideally suited for machine learning (which is de Prado's main concern). An example of daily time bars is shown below.

![A financial time series candlestick chart showing Apple stock's price over time](/static/images/candlestick.png "Time bars are generated once a uniform interval of time has passed")

Despite their ubiquity, time bars have less desirable properties for machine learning use cases than some alternatives we can compute using the underlying tick data. It is well known that financial data in general is not [independent and identically distributed](https://en.wikipedia.org/wiki/Independent_and_identically_distributed_random_variables), as each observation is influenced by its predecessors, and the distribution of returns tends to be highly [leptokurtic](https://en.wikipedia.org/wiki/Fat-tailed_distribution) (i.e., it has fat tails -- you could look up one day and suddenly be up or down a high # of standard deviations). Time bars exacerbate this problem because they bundle up too much information in one observation rather than emitting observations *as new information arrives*.

Other ways of generating your training data, that try to get us closer to our goal of IID   therefore have both theoretical and [empirical](https://towardsdatascience.com/information-driven-bars-for-financial-machine-learning-imbalance-bars-dda9233058f0) support. Most straightforwardly, this might take the form of, say, emitting a new bar when a certain amount of dollars has changed hands, ticking the "clock" according to the underlying value exchanged, and not a static measurement of time. Most of the action in trading, for instance, hovers around the open and the close of the exchange for the day. It makes sense to emit more bars in those times, where more information has arrived than during the middle of the session when everyone is out to lunch and little is happening.

The algorithm to do so is along these lines:

```
cumulative_dollars := 0
for tick := range ticks {
    cumulative_dollars += tick.shares * tick.price
    if cumulative_dollars >= NEW_BAR_THRESHOLD {
        emit_new_bar(open_datetime, open, high, low, close, volume)
        cumulative_dollars = 0
    }
    // update OHLC...
}
```

This will result in far more bars when something's actually happening. There are fancier techniques too, but this illustrates the general idea and tends to result in bars that have more desirable statistical properties.

What if we could do something similar in observability to improve our sampling efficiency?

## To Observability

Dollar bars work partially because they shift the lens to focusing on what we actually care about, i.e., money exchanged and new information, not the ticking of the clock. Can we apply similar operations in observability to get better results? I think so. For instance, let's look at sampling tracing data.

One of the features in Honeycomb's [Refinery](https://github.com/honeycombio/refinery), a proxy for sampling distributed tracing data before sending it to a storage system, is the introduction of novel sampling methods such as [dynamic sampling](https://docs.honeycomb.io/manage-data-volume/refinery/sampling-methods/#dynamic-sampling) that improve upon grabbing traces randomly. In dynamic sampling, the sampler maintains a map of how often it has seen a particular value of a span field, and samples more frequently seen values more aggressively, resulting in a "compression" of sorts that keeps more of the novel data such as failure states, and assuages the concern that we might not have what we need when we go to look for it.

For instance, a common key to sample on is the HTTP status code. Your service hopefully serves up a lot of HTTP 200 status codes, and very few 500 level status codes indicating an internal server error. Instead of capturing 1/N of both types, we can track how often they occur and sample a lot more of the 500s, relatively speaking.

That's a good improvement over sampling randomly, but the idea of sampling according to when new information arrives has me wondering if we can push it much, much, further. For instance, unlike sampling dollar bars, it does not relate directly to the underlying value or cost associated with the traces it's examining.

We have a lot of different ways of measuring such value, and two come to mind that might be useful.

**Sampling based on resources used** -- For determining which traces to store, you could examine the compute resources used nearby the trace in question, and sample more aggressively when the trace looks likely to be costing you more money. This is most obviously expressed in the infrastructure metrics that almost every team has available measuring usage of CPU cycles, memory, IOPs and so on. For instance, you could sample more frequently from a given host when its free memory is lower, or when its CPUs are burning hot.

**Sampling based on the value of the underlying customer** -- Not all customers are created equal. Some actually have negative value for us (perhaps they are on a Free tier with no hope of ever upgrading), whereas some represent $XY,000,000 per year contracts. While not as straightforward as a metrics-based method as outlined above, it could reflexively help solve the fear of losing out on important telemetry. Almost by definition, at the end of the day we want to keep data that is worth a lot of money to our company, and ignore data that is worth less.

Perhaps someone out there is crazy enough to experiment with ideas such as attaching the Opportunity Amount from SFDC (representing how much $ the customer is projected to be worth) to their tracing data and sampling based on that. You can even imagine yet more sophisticated systems that do projections and factor in yet more dimensions to the mix such as the users' value as an evangelist based on their number of Twitter followers, how important their title looks on LinkedIn, etc. While we all like to feel like we're the most important, I'm sure you will agree that fixing a bug seen by a CTO with purchasing power or a Twitter celebrity is more important than patching issues encountered by some rando.

## The Future

All this is just the beginning of me writing down some thoughts on more useful, information-based sampling . I've focused on tracing above since it's more or less what I know best, but I see no reason the underlying philosophy couldn't be applied to metrics, logs, APM and more. For instance, why are we limited to a static time based scrape interval for metrics systems? _A lot_ can happen in fifteen seconds, and while we don't want to overload a host that's already wheezing along with excessive scrapes, perhaps we could collect telemetry more dynamically based on an evaluation of where the problems are likely to be.

Then, when we inevitably search and visualize it later on, our tools could have a better head start in terms of surfacing the information that we actually care about, instead of simply painting us a time based picture that often leaves us scratching our heads and wanting more. I haven't even covered the potential implications for doing machine learning and augmenting humans' ability to 