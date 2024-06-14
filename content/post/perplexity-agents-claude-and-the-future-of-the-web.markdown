---
title: Perplexity Agents, Claude, and the Future of the Web
layout: post
date: 2024-06-14T04:43:17.644Z
categories:
  - ai
---
So, uh, #agents is getting thrown around a lot these days and it's a confusing landscape out there. But I want to talk about recent experiences with my new obsessions like [Perplexity](https://www.perplexity.ai/), which in my opinion is one of the first approaches at a breakthrough, agent-native system. I’ve also been playing with this cool tool called [WebSim](https://websim.ai/) (as in Web Simulator), which feels like another stab at a truly AI-native app (rather than just something which bolts on LLMs or other models to existing tools). Some thoughts on the directions we’re headed and why I think Claude Opus is uniquely positioned to be the vanguard LLM of this new wave…

## The Rise of Perplexity and Perplexity Pages

![](/images/agents.png)

Perplexity is this AI search engine that is basically what [AskJeeves](https://www.askjeeves.com/) wished it could be thirty years ago. If you squint, you can see the core functionality as a kind of baby agent.

Given a query like, “*Who was the constable in Gravity’s Rainbow?”,* Perplexity produces useful, source-cited, humanized results by breaking things down into steps automatically, using a pre-programmed recipe:

1. Take in a high level query
2. Decompose it into multiple search engine queries
3. Go find the content
4. Put it together
5. Synthesize a final result.

Simple process, right? Hard to even call it an ‘agent’ when it’s probably just a series of Python calls. But it is, as a start, a chain of things whose input steps depend on the output of previous steps.

![](/images/anime-llm-chain.png)

A lot of AI today is very synchronous - make a prompt, wait for result, yay got a result. Or maybe things are chained in the background but it's complex, custom, bespoke, tying things together with impromptu UIs and debugging flows. That's how it goes in the early days, people make custom stuff.

But eventually, this will start to turn to something standard and repeatable. Humans just step in, using standard tools and systems, to correct the AI when needed. Kind of like what already happens with synthetic training data - generate data, check if it's good, update/correct if not, feed it back in. In fact, every chain executed right now is a potential future training data point. But to truly fulfill the agent dream, we have to increasingly take humans out of the loop, eventually getting them out of it ~entirely. Is it possible? Do synchronous chains eventually become asynchronous agents, or are we just blasting hot air around?

There hasn’t been much convincing evidence so far in my opinion, just a “feeling” that it’s inevitable. But Perplexity recently rolled out this [Pages](https://www.perplexity.ai/hub/faq/what-is-perplexity-pages) feature which I think is the first evidence of a system that's actually agent native. With Pages, you can specify some top level item, like, *Paranoia in Gravity’s Rainbow,* or, *Thomas Pynchon and the World Fair,* and Perplexity will giddy up and go spit out a full-blown research docket / article on that topic for you.

Pages is dope because you can see the system working in real-time as results come in, and you can correct them. Don't like a section? Add a new one or re-write it. It's like having a bunch of little servants doing tasks for you asynchronously. A key part is that it's very well indexed. The models might not be smart enough yet to autonomously come up with ideas and do full blown task planning, but they're really good at taking data and synthesizing it. A well-constructed index helps provide leverage to get *a lot* more out of them.

![](/images/perplexity-edit.png)

## Why Claude Opus is Ideal for the Task

![](/images/swagged-out-claude.png)

This leads into why I think Claude Opus is by far my favorite model for this right now:

1. Huge context window. The recall is staggering. I've had trouble getting tools like GPT to accurately quote source material. But with Claude and Perplexity, it's shockingly good. I tested it with a quote about gum from Gravity's Rainbow and it nailed it. And with Perplexity you can cite things to prevent hallucinations.
2. JSON capabilities / function calling abilities. Claude seems like one of the first models that feels like it is natively designed to do the *actual* things we want LLMs to do, rather than being a tool we found useful and hacked into our workflows. It does indeed seem really good at instruction following, and mirroring based on few-shot examples. There is an “intuition” factor that is missing in other models, it just seems to know what you want.
3. It feels a lot more spongy and human, and I think there’s a lot to be said for those ergonomics, since we already do, or soon will, use LLMs day in and day out, EVERYWHERE — on our phones, in our homes, and probably even in the byzantine bureaucracies we all have to deal with. Claude absolutely SMOKES ChatGPT at having personality, humor, and nuance.

Right now, to me, Claude has the feeling of being that cool new thing that people in the know use, while most people are still just now waking up and experiencing ChatGPT for the first time.

## WebSim and the AI-ternet of the Future

![](/images/websim-animated-ascii.png)

So there's this project called [WebSim](https://websim.ai/) which is basically a hallucinated internet. Type in a fake URL, it creates a webpage, then links off to other hallucinated pages. Ironically leveraging something people say is undesirable about LLMs (hallucination) to do something interesting and playful.

I think Claude's creativity really shines here in a way GPT can't keep up with. It will do these things to amuse you, and it can keep track within context of a *lot* of iterations and adjacent nodes in the knowledge graph. Reading the tea leaves now seeing Claude, Perplexity, and WebSim in action, I envision a serverless, agent-based "AI-ternet" (I know, jargon buzzword, but roll with me here).

Everyone has their own fleet of agents Lego-bricking stuff together (knowledge, front ends, dynamically generated Lambdas) constantly. Imagine WebSim but you can create your own strip of the AI-net asynchronously, with agents working around the clock, learning from mistakes, adapting, trying to figure out what you want with some control/reconciliation function. Not dissimilar from the much-hyped [Devin](https://www.cognition.ai/blog/introducing-devin), actually, which feels like yet another piece of the puzzle. The really good models from OpenAI and Anthropic are expensive, but they might be good enough if you just want to bundle or wrap some things that other people blew a lot more tokens on already, or you might be able to use the cheaper ones, or, if you just need to push a lot of tokens, you could probably just [run your own Llama](https://ollama.com/).

Then everyone has their own personal TikTok algo, but actually meaningfully producing new consumable content and it's programmable. As an example, say some video producer needs to figure out how to crop a video to a square — with this system, they could just ask, without needing to chain together FFmpeg, ImageMagick, run it in Docker, etc. or download some non-composable, difficult-to-use random app to do it. We'll have this dynamic, living, breathing peer to peer AI-ternet all based on something like Claude.

![](/images/anime-claude.png)

The future looks more like WebSim - constantly beating our drums in a hallucinated simulation of a new internet, with people able to conjure distributed systems and backend services to suite them up out of thin air just as easily as Geocities made having your own little homepage. We might all be Lego-bricking things together like software libraries on steroids, with AI dynamically generating and searching for interconnectable pieces.

Anyway, those are my slightly rambly, jargony, mixed-metaphor thoughts. What do you all think - am I crazy or onto something here? Let me know in the comments and stay sassy, Internet.

* N