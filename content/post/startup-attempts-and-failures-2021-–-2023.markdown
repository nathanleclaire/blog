---
title: Startup Attempts and Failures, 2021 – 2023
layout: post
date: 2023-04-05T04:23:07.602Z
categories:
  - programming
---
# Blogs

### Startup Attempts and Failures, 2021 – 2023

In 2021, I quit my job at Honeycomb to set out on my own and try to build a company. At first, I wasn’t sure the exact model I’d follow, and had a (perhaps too lofty) aspiration that maybe I’d have a hybrid model, doing a bit of consulting, a bit of real estate, and a bit of product/SaaS/4-hour-workweek livin’ the dream. And, of course, if I happened to hit on something big, I could go raise venture and pursue that.

It was also a great opportunity to take a much-needed break from seven years of high growth startup life, and if nothing else, I’m glad I did that. I made many connections along the way from, say, flying to Miami for a podcast meetup on a whim that I otherwise wouldn’t have. Life follows a non-linear path in that way.

At any rate, here’s a writeup of what I tried, what worked, and what didn’t.

### Ogmi, a Financial Machine Learning Play

From around 2020, I became interested in "Advances in Financial Machine Learning" by Lopez de Prado and focused on gaining an edge in the market. I processed tick data into aggregate features and used [mlfinlab](https://github.com/hudson-and-thames/mlfinlab) in a project I called “Balrog” or “Ogmi” when launched publicly. It included some Rust code for processing that I’ve now open sourced.

![](/static/images/untitled.png)

This tool offered access to mlfinlab primitives via a Django API. However, as a sole developer, it was difficult to maintain the pipeline and the predictions were sadly inaccurate, resulting in losses. Despite marketing it as a "bet sizing engine", which I still think has potential in **\***some**\*** field, it is brutal to compete with larger and more experienced players in the world of finance.

No one was interested in my product and I had no finance industry connections, so I stopped working on it. However, I did have a few interesting results due to feature importance testing:

* Features related to volatility were more important predictors than almost any other technical indicators. Candlestick patterns are trash, and good old MACD seems to be the best among your usual batch of RSI, etc. type of indicators.
* Fractional differentiation for preservation of memory *did* seem to work to improve results. I think there’s lots of potential outside of finance to use this concept as well as information based sampling, structural breaks, combinatorial purged cross validation, etc.

### Solana Workbench

I got into cryptocurrency ages ago and took part in the 2017 bull run. In that run, I felt genius when I sold my BTC at $1200 after buying it for $900 :) Oops.

I got interested in FTX and Solana after seeing a tweet and listening to some podcasts. Solana was already proof of stake, fast, and inexpensive, but still prioritized crypto values. I became a huge Solana bull, which made me a substantial chunk to self-fund which was great. Unfortunately, the developer experience was terrible, and I struggled to put together a smart contract.

Luckily, that’s my specific area of expertise. So I bet a friend Zack Burt 1 SOL that I could have a working prototype of a GUI to aid with Solana development within one week. 

I won the bet as I developed a prototype that resonated with people and looked like it would secure a Solana grant (which it did) and attract VC funding. I spent the first quarter of 2022 searching for a co-founder.

I successfully recruited Sven Dowideit, an old friend from Docker and boot2docker icon, to join me as co-founder. Initially, things went okay, but we struggled with the crypto aspects of the project because we lacked the necessary Solana knowledge. We also suffered from chasing too many features, which affected our progress.

However, it was still a thrilling time. We felt wind in our sails again for the first time in **\***years**\*** chasing after the vision we had at Docker to revolutionize computing and make it truly decentralized. We tried to raise investor money but got too ambitious and ruined our chances by chasing a higher valuation. Meanwhile, interest rates were rising, and people were getting rekt across the board.

![Untitled](/static/images/untitled-1.png)

We pivoted to making DAOnetes, a decentralized platform that tokenizes workloads and enables multi-sig workflows for workload orchestration. DAOnetes, awesomely, supported private peer-to-peer Wireguard networking through a smart contract, which solves the Tailscale-in-the-middle issue (i.e., having to trust an intermediary to bootstrap private networking). Our goal was for DAOnetes to be the backbone of the Metaverse, enabling more peer-to-peer interactions and a decentralized yet loosely trusted network for participants.

![Untitled](/static/images/untitled-2.png)

Unfortunately, we found that there was currently not much demand for this idea the way we tried it. DAOs didn’t actually do much programming, and even crypto bros pretty much just wanted to use AWS or whatever.

Backpack, with their xNFTs idea, seems to be hitting product-market fit more effectively in that general direction. It’s possible that Backpack could eventually become a new browser that integrates crypto natively (the current browser plugin workflow is awkward at best) and plugs into decentralized cloud(s) as well as simulated worlds with low latency via edge computing.

Eventually, we decided to shut down the company. We were discouraged by the FTX collapse and felt that most crypto investors usually wanted a token for liquidity purposes, which posed too much regulatory risk for us. However, we plan to make the code open source at some point.

### 2023: Tensorscale and Job Hunt

In September 2022, I became interested in Stable Diffusion, but we were obviously focused on Crypto Workbench. But in December, as the company began to wind down, I shifted my focus towards AI and participated in an energizing HF0 AI hackathon. One of the topics discussed at the hackathon was the scarcity and high cost of GPUs, which cloud providers are hesitant to provision due to unpredictable demand.

Hating the situation I was in while working on my project, where I had to use an expensive (~$1K per month!) Amazon GPU server, I wanted to see if I could build something that would allow me to run Stable Diffusion workloads easily on my computer at home, from a remote server, as an alternative.

So I created Tensorscale, a client-server system that connects nodes to the cloud and distributes workloads with a strong focus on AI use cases. The goal is to have an orchestration platform with unique features that cater specifically to the needs of AI workloads. It allows for fast calls to worker nodes, resource reservations to avoid contention, prioritizing important workloads while allowing for interruption of less important ones and more. It also has primitives for node labeling, so that if a custom checkpoint or LoRa is only available on a specific node, it could be routed there, and the potential for streaming previews back to the server, e.g., sending tokens right as they are generated.

Many systems today use a basic model where Redis is used as a queue and workers pull things off. While this works well, there are concerns about error handling, retries, keeping track of what's where, and live previews.

An article pointed out to me by Charity Majors, <https://programmingisterrible.com/post/162346490883/how-do-you-cut-a-monolith-in-half> influenced my thinking that this model will inevitably have problems.

As mentioned on Programming is Terrible:

> Message brokers, or persistent queues accessed by publish-subscribe, are a popular way to pull components apart over a network. They’re popular because they often have a low setup cost, and provide easy service discovery, but they can come at a high operational cost, depending where you put them in your systems.

I wanted something BiDi, and I got it by writing it myself. It's a lot of fun, especially being able to prioritize user requested tasks in the queue while my GPU still works on less important tasks. The fans are constantly blasting away, but it's a good time.

![Untitled](/static/images/untitled-3.png)

Things were going well at first, and I think I am hitting on a few user pain points. However, looking at what I’ve been accomplished in the past few months, I feel like exhaustion and self consciousness has led me to drop the ball on important tasks like conducting user interviews, shipping at a fast pace, and doing marketing.

After surveying my emotional state, I believe that I am experiencing founder burnout. Additionally, my savings have dipped to a level that makes it difficult to continue. Like stopping out on a trade, I have decided to stop out on my efforts to build something full time and move on.

I'll still release Tensorscale, but I'm also exploring new job opportunities. Not taking venture capital for it will free me from the pressure to become "OMG the best platform ever!" Instead, I can focus on creating art using Stable Diffusion.

### In summary

If I had to summarize lessons learned:

* **Take advantage of opportunities that are right in front of you and cut the things that aren’t working quickly.** I missed at least one good opportunity because I tried to get a better deal, and by the time I realized the value of the safe bet, it was gone. On the other hand, I spent too much time on projects that should have been killed off earlier.
* **Interest rates are important.** In 2021, raising venture capital would have been easy with what little I had. In 2022, it was harder, but I still had options through connections and other means. In 2023, it’s *really* hard.
* **There are still good things that come from failures.** I don't envy those who have raised money at high valuations in a bull market and are now being scolded by the board in every meeting for not meeting their goals.
* **Life is non-linear.** Despite having some regrets, I am grateful for taking chances. During my break, I acted on random impulses that turned out to be positive changes in my life. Joining a co-working space boosted my mood and allowed me to make new friends. I found a new friend who is a value stock bro. And in one of the best trips of my life, I went to Lisbon and indulged in garlic butter prawns, wine, and
* **Reconnecting with passions is a good thing.** I realized that my desire to be a CEO was driven by vanity, and while I didn't mind the operational side of things, my love of tinkering overshadowed that desire. Since trying to start things like DAOnetes and Tensorscale, I’m more excited than ever about the future of computing, and the role I’ll get to play in it.

All in all, I’m excited to keep making cool shit. LFG!