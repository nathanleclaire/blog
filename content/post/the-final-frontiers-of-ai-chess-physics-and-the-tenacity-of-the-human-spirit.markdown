---
title: "The Final Frontiers of AI: Chess, Physics, and the Tenacity of the Human
  Spirit"
layout: post
date: 2024-06-15T18:25:00.343Z
categories:
  - programming
---
## Deep in the Blue

![a minimal illustration of a pawn chess piece on backdrop of big blue ocean](/images/blue-chess-piece.png)

Lately, I've been getting back into chess, and of course, that brings up thoughts of the epic  [Kasparov vs. Deep Blue](https://www.perplexity.ai/search/kasparov-vs-deep-2BbaCuZ3TZ6HetXOLLH3Dg) battle. It's a classic tale of how computers weren't good enough to beat humans, but then, pretty rapidly, humans started to lose. Now, chess is pretty much a computer-generated sport.

But there's still hope for the tenacity of the human spirit. Players like [Magnus Carlsen](https://www.perplexity.ai/search/How-is-Magnus-ks4xpQ2JQcSQQR4sZpXv0g) bring a lot of fun and popularity back to the game. And then there is Go, which became this huge bastion of hope for humanity because the best players couldn't be defeated by computers for a long time... until AlphaGo kicked off the deep learning boom by defeating the human champs. (Hey, at least [we can still win](https://www.perplexity.ai/search/Can-humans-still-.zJwOhxsTyCI.xXR9q1KaA) sometimes!)

Are we doomed for computers to always get better at us than everything we do? What will be the final frontiers of human knowledge and what will happen to us?

## The AI Capabilities Wall

![a stylized illustration of people shoveling money into a giant burning pile of GPUs](/images/light-money-on-fire-with-gpus.png)

It’s not clear that the current trend of AI improvement will continue linearly, in fits and starts, or at all. It’s possible that we’ve hit a capability wall. [Transformers don’t scale ‘well’.](https://www.perplexity.ai/search/Limits-of-scaling-utGtpCyoTWKaRweRtNjOEA) ¹

Right now, it seems like we're mostly just throwing more and more flops at the problem. We have one trick, it works, and we keep doubling down on it, like how my friend Victor Coisne loved to cheese at Street Fighter using E Honda’s [Hundred Hand Slap](https://www.perplexity.ai/search/How-to-cheese-butWUyqzSGGVpzbPyj_opw). The results are jaw-dropping, but the infrastructure and compute required is insanely high. There don’t seem to have been any widely applied efficiency breakthroughs - the main thing that works is just making the fucking models bigger.

Sure, there are some promising research directions, like [OneBit](https://www.perplexity.ai/search/What-is-OneBit-mHVuTK44R3SVSPwkrDuDvw), but so far, the juice has been in collecting better training data and ramping up the model size. I wouldn't be surprised if we get one more wave of impressive gains out of the current transformer architecture boom, but after that, it’s hard to say if we’ll go anywhere novel or not.

## AI is Fancy Autocomplete

![A drawing of an intricate blue and orange grid of honeycombs and schematics behind a sitting programmer on a laptop](/images/honeycomb-computer.png)

If that’s the case, then humans get some breathing room for a while, capabilities-wise. Regardless, I'm relatively optimistic that AI will help eliminate a lot of drudgery and just make people more efficient at their jobs, not replace them entirely. Well, software engineers anyway. ²

My friend Charity Majors wrote a [great piece](https://stackoverflow.blog/2024/06/10/generative-ai-is-not-going-to-build-your-engineering-team-for-you/) about how AI is basically just fancy autocomplete right now, and junior devs still serve an important role. I think she undersells AI a bit, but it’s a good exploration of some frontiers of human capabilities AI chokes on at the moment:

1. **Implementing production systems, and operation of them.** This is fiendishly complex, and can require a ton of manual intervention to fix even seemingly trivial errors. *”The cloud”* and *“high reliability”* are carefully crafted illusions forged from the blood and tears of SREs.
2. **Translating business needs into technical implementations.** Sure, 80% of what you are working on might be something the AI has “seen” before, but that 20% could spiral out of control and gum up the works fast. If you ask any software engineer what the most challenging part of their job is, most will not say, “The code is too hard to write”.
3. **Mixing it up.** The enthusiasm of other engineers, junior or otherwise, or their hungriness to please, can encourage other team members to dust themselves off and produce better work. Different humans bring a different perspective that can keep you from spinning your wheels. If you have a car that can drive faster, but mess up the directions because no one is there to call you on your bullshit, then well, you go the wrong way faster. ³

## LoRA’s Gambit: No Specialized Knowledge is Safe

![a stylized design of a pawn with text that says "LORA: specialized knowledge"](/images/lora-specialized-knowledge.png)

HOWEVER — it still is worth careful consideration what AI can’t currently do, but will be able to soon — in particular, a logical anti-pattern I see a lot, is that people will point to some specialized task AI can’t yet do (Queries like *”Write me a Go function that reads an Arrow table from a CSV and starts a Flight server”* make ChatGPT hallucinate more than a Wookie on 2C-B) as evidence that it’s undeserving of the hype.

I think that’s going to be an increasingly weak bastion as not only the core models improve, but importantly, their ability to be extended via fine-tuning gets stronger and stronger. See e.g. our friends at Predibase demonstrating [better than GPT4 level performance on specialized tasks](https://predibase.com/blog/lora-land-fine-tuned-open-source-llms-that-outperform-gpt-4) with LoRA. if you're counting on some specialized knowledge to protect you from AI, that's a bad argument. It's amazingly cheap and easy to train them for specific tasks.

Right now, the high-performing models like GPT-4 don't have LoRA (or even regular fine-tuning) support, and fine-tuning can ruin the base model. But once that changes, and we get better fine-tuning capabilities, these AIs are going to start showing insane performance on specialized tasks. All that domain expertise people think makes them irreplaceable isn’t going to look so unique anymore.

## The Final Boss: Spatial Reasoning and Physics Simulation

![a stylized design illustration of a red apple hanging down on black and white background while isaac newton sites](/images/newton-with-apple.png)

The real final frontier though, I think, is spatial knowledge, awareness, and “world simulation”. It's a really difficult problem for AIs to rotate shapes and reason in 3D space. That’s why many remaining CAPTCHAs seem to be variants of “select the objects of the same class” or “point this hand in the right orientation”. Developing a true, conceivable physical world model is what these models struggle with most right now. True multimodality, like the Omni models, and physical reasoning engines are the key research directions to push on.

In a field like software engineering, being able to construct “world states”, is extremely important — a lot of the hands on problems we deal with decompose into spatialtemporal, simulation-ish things like:

1. The service is responding with a non-200 status code (dimension, `status_code`)
2. I go check the logs for the service (location, `/var/log/service.log`) 
3. I see error from line N in file Q (location, `Q.go`, location, line `N` ), I simulate what the state of the program likely is when this code path is reached in my mind
4. … fix, PR, etc…. (follow process, DAG going from make patch ⇒ open PR ⇒ request review ⇒ fix review comments, etc…)
5. I redeploy the service (state change from `running` to `stopped` back to `running`)

These currently, uniquely human things (with a lot of technology augmentation) require a simulation of world states that currently exists only in our minds. In order for AI to hope to tackle that challenge, it needs to get into that realm, not just chunk and unchunk text and pixels.

Once we shatter the spatial reasoning threshold, that's the real indicator of a new capabilities paradigm, not another 5% on some benchmark. CAPTCHAs, our last line of defense to differentiate humans from machines, will probably be completely dead at that point. We'll all be using biometric cryptographic keys to prove our humanity online. Fuck my life, but that's a whole other rant.

I'm really intrigued by some of the [recent physics simulation engine](https://www.perplexity.ai/search/What-is-Kling-xtVLqoNyRS.mx1bWUu1G9A) developments. That's a promising avenue to unlock new levels of reasoning and interaction for AI. If we can nail that, along with the multimodal Omni-style models, I think we'll see a big leap in what these systems can do. Not just another incremental gain from throwing more flops at transformers.

## Conclusion: Eyes on the Prize

![A white and golden knight chess piece in a present box, 3d render](/images/golden-chess-piece.png)

So while I'm playing chess (badly) and musing on the next Kasparov vs. Deep Blue, I've got my eye on the physics simulation and 3D reasoning capabilities. That's where the real magic is going to happen. We might even get Stable Diffusion to draw passable hands some day. So, wake me up when GPT-5 can rotate a cube in its "mind's eye".

Until then, stay sassy, Internet.

* N

(1) There also seem to be some problems created by virtue of the fact that possible training data is now highly contaminated with output from the models themselves, but I suspect that fear could be overblown. Two reasons, for one, they figured out a way to under-sample on BongHits4Jesus69’s shizo posting in the training data and over-sample on educational/valuable content already, so they can probably figure out how to prune AI content. Two, just because data is synthetic doesn’t mean it’s not useful. I am, however, admittedly tired of seeing every model, no matter the source, claim it is an assistant developed by OpenAI.

(2) However, that doesn’t necessarily mean that say, software engineer salaries will stay sky-high — I think in terms of knowledge workers in particular, people over-index on arguing about AI alone replacing them, when the cocktail of AI + outsourcing + COVID remote adaptations is far more prescient — but that’s yet another blog.

(3) There’s something interesting to explore in the facet of something intelligent and useful, almost by necessity requiring a push back mechanic — if you hire a truly great engineer, they might come in and tell you (hopefully politely) that everything you’ve been doing is moronic, but GPT in the same circumstances would be far more placid, and might even help you double down on mistakes. So there seems to be an inherent tension between capabilities and docility and it’s not clear to me how to reconcile that.