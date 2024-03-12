---
title: The Observability Sharpe Ratio -- Measuring Sampling Efficiency
layout: post
date: 2021-08-27T04:06:27.635Z
categories:
  - observability
  - devops
  - coding
  - sharpe
  - finance
  - sampling
---
In finance there's a concept of a [Sharpe ratio](https://www.investopedia.com/terms/s/sharperatio.asp). It's meant to help you evaluate whether an investing strategy has a good risk-reward, i.e., its return is efficient relative to its potential volatility. A Sharpe ratio is one way of measuring how a portfolio, trader, or strategy is performing at getting the bag. It's useful because it's easy to compute and because portfolios with excellent Sharpe ratios can be leveraged to juice their returns even further. Lately I've been jamming on the idea that your organization might be able to measure something similar in your monitoring and observability data -- by comparing the information loss when a form of data compression is applied, to the cost savings associated with that sampling.

All of us inevitably end up doing some form of data compression and/or reduction to keep costs down, yet have terrifyingly few tools available to do it right. It just gets too damn expensive at a certain scale to schlep log or tracing data around, but it costs so much in bandwidth, vendors, and personhours (*"Who wants to maintain ElasticSearch this sprint?"*) that you have to figure out a way to reduce your usage. So it's not long before people are applying tricks like archiving or deleting old data, cleaning up junk logging, or precomputing results.

Complicating all of this is the fact that if we're talking about sampling your [distributed tracing](https://opentelemetry.lightstep.com/tracing/) information,   When I was at [Honeycomb](https://www.honeycomb.io/), 

information encoding ranking as denominator