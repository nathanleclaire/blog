---
title: Playing Around With Ollama for Local LLM
layout: post
date: 2024-03-05T02:24:48.558Z
categories:
  - programming
  - llm
  - ai
  - llama
---

<img style="max-height: 512px" src="/images/img_6907.jpeg" />

It should come as no surprise to anyone who's involved in the tech industry that Large Language Models (LLMs) are a huge trend. Recently, I've had the opportunity to work with a new LLM tool called "ollama", which was developed by some friends of mine from Docker. The experience so far has been quite impressive, to say the least.

# Running

<img style="max-height: 512px" src="/images/img_6910.jpeg" />

One of the standout features of ollama is its automatic “scheduling” functionality, which works efficiently across multiple GPUs and OSX metal alike. This feature makes trying big models easy as hell, making it a joy to work with. Another element I appreciate about ollama is the ease it provides for creating “characters” and playing around with parameters such as temperature or base model. This allows for an expansive range of creative freedom.

It's quite clear that we're heading towards a situation akin to the "Docker Hub" scenario, where individuals can effortlessly port atound "LLM bundles". However, this potential solution comes with its own set of challenges. For starters, these "LLM bundles" are incredibly large, with many stretching into the multiple gigabytes of data. Due to the way model weights work, they cannot be diff transferred (at least for now) which presents a significant hurdle.

By way of contrast, Docker images use a layered filesystem which enables incremental updates, so if you only change one file in your entire application, only that layer needs to be updated and redeployed, instead of the whole application. This can significantly reduce the size of updates and deployments. Additionally, aside from chip architecture and kernel module differences, Docker images provide a consistent and predictable environment, which simplifies scheduling and deployment across different systems. In contrast, in AI we are dealing with massive opaque blobs, a multitude of different CUDA libraries and issues spanning across CPU/GPU co-scheduling.

Despite its quirks, the ollama approach has its merits, and I envision a future where it or a similar tool can manage a significant amount of work, greatly improving the current situation. Today's method often entails haphazardly grabbing pytorch models etc from random places. A unified distribution and execution engine just makes sense.

I foresee the complex and tangled Langchain eventually being replaced by a template *chain* distribution type mechanism. We might even end up bundling code in ollama images, which would enable arbitrary code execution agents or services with LM capabilities built in.

# Philosophy

<img style="max-height: 512px" src="/images/img_6909.jpeg" />

The concept of local LLMs is immensely important for several reasons. There’s a privacy perspective - many people, including myself, are uncomfortable with how systems like OpenAI don’t allow us to see the inner workings. Imagine if Google were to moralize to such an extent that it prevented you from accessing information about gun control due to its association with guns. It's essential that our narratives can encompass conflict, violence, and sex. That’s the basis of all media and it reflects the moral complexities of human life. Uncensored models are ultimately beneficial despite allowing some to engage in disturbing activities.

There are also numerous practical reasons for local LLMs. It’s inefficient to invoke OpenAI for every minor operation. Why not distribute computations across available platforms? If there are idle computers, they should be utilized. We don’t need to run everything on OpenAI servers. And, for some applications, it’s crucial that they operate locally with as little latency as possible. Just think about the possibilities with something like Apple’s new Vision Pro. Whether it’s LLM or something else, there’s a myriad of "edge sensitive" work that stands to benefit from this approach.

# Hands on

<img style="max-height: 512px" src="/images/untitled.jpeg" />

I consider myself fortunate to have two thicc consumer GPUs at my disposal. This has enabled me to run models like Mixtral, that are shockingly good compared to even just a year ago, at pretty reasonable quantizations and speeds. I can only imagine the human creativity we will unlock once all the pieces, including aware continue to chug along and everyone has GPT 3.5 or 4 level capabilities sitting on their desk.

Additionally, Ollama has excellent support for multi modal models that can “look” at images — passing in a picture to a model like LlaVa is ridiculously easy. In my experiments LlaVa obliterates tools like BLIP at image captioning and is, of course, interactive with a good grasp of language. This will enable far more sophisticated training data of all kinds including for image synthesis because iteration on training sets now can lever human input at an ever increasing rate. And, of course you can take the output of BLIP or Deepbooru and plug it into LlAva alongside the image and prompt.

Speaking of, one of the big challenges I've encountered while working with LLMs in general is the task of prompting models. It can be quite a nuisance due to the strong mode collapse back to the hard-coded core of the chipper, do-no-harm assistant. The model, no surprise, tends to default to its original programming, which can be quite limiting.

There is an inherent tension between human narratives and creativity, which almost always need conflict to avoid being dull, and the safety capabilities or limitations of the model. I recall OpenAI reprimanding me when I attempted to generate an image of a gun for for a comic book. Common things that we find unremarkable may not necessarily be safe.

For creative work, these models may require a solution or perhaps fine-tuning to allow for expression. Otherwise, we risk continually reverting to a state where everything works out, there are no conflicts, and everyone is perpetually happy and grateful. Which of course is completely unlike the real world.

However, with patience and practice, it's possible to overcome these challenges. Some prompt attempts may not yield the desired results, but persistence is key. One thing I've found impressive about Mixtral is its state and physics management capabilities. It performs these tasks exceptionally well, which is a plus.

The future of LLMs, I believe, lies in the ability to chain models together and fine-tune them to achieve superior results. This is an area I'm keen on exploring further. More on that in a little while. 

U﻿ntil next time, stay sassy Internet.

-﻿ N
