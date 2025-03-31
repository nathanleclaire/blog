---
title: "Emotional Recall: Strengthening Spaced Repetition with AI "
layout: post
date: 2025-03-30T22:32:12.125Z
categories:
  - programming
---

![A surreal drawing shows a man retrieving a book labeled with the Chinese character 忆 (memory) from a library inside his own head.](/images/phrenology_head_character.png)

Welcome, I’m Nathan, an [SF-based Go hacker](https://nathanleclaire.com/about/) with a mission to create bicycles for the mind. I’m always looking for new ways to leverage our “hardware” (nervous system) and upgrade the programming and metaprogramming in our biocomputing layer. Today I’ll talk about one area I’ve been exploring: finding new and creative ways to **emotionally turbocharge recall** with AI tools.

[Anki](https://apps.ankiweb.net/), a flashcard software built on top of a simple yet incredibly powerful idea (spaced repetition) has become one of my obsessions. If you’re a nerd, there’s a good chance you’ve already heard of spaced repetition learning — but in case you haven’t, here’s a quick run down.

## Spaced Repetition

**Our brains recall information best when it’s repeated at ever-increasing intervals. Things that are harder to remember should be revisited more often.** That’s the core concept.

Further pontification — One of the problems with the way we do education is that we tend to cram material for one examination, then never revisit it again. This leads over time to lots of forgetting, even though maybe, buried deep inside your brain’s “weights”, it’s there. How many of us, even if we once knew them by rote, can recall the quadratic equation, or the Amendments to the Constitution, or who the second president was?

The truth is, we really should periodically revisit things, not give up on them once we’ve passed the exam. The spacing effect helps us [retain information better](https://pmc.ncbi.nlm.nih.gov/articles/PMC8759977/#REF6).

> The spacing effect was first discovered by German philosopher Ebbinghaus with a humble approach to studying memory. By simply creating a study list on pieces of paper, Ebbinghaus found that he could master his memory of items faster if the repetition of items was spaced out at different intervals.

Recognizing this principle helps us enhance our life by making it easier to memorize things for school, learn languages, or even to develop a mental CRM so birthdays and other important personal details will never go forgotten. I won’t deep dive too much on it here, but the Wiki is a good read - <https://en.wikipedia.org/wiki/Spaced_repetition>. 

## A Better Way

Language learning did not catch my interest much in early adult life, but a few years ago, for *reasons*, I became interested in learning Portuguese. I knew it would be difficult to meaningfully pick up without getting a coach and a lot of speaking and listening practice, so I started to take lessons on [iTalki](https://www.italki.com/). My teacher would often post words and phrases in the chat while we practiced on the conversational side, and of course walk me through conjugations and concepts with a more structured format too.

Unfortunately, because it was basically the only time I was speaking and reading Portuguese, acquisition was extremely slow. I would forget conjugations and found it tricky to recall even simple things like the various forms of the verb **ser** (”to be”). It doesn’t help that the combination(s) of perfect vs. imperfect, subjunctive vs. indicative, etc. create an explosion of various conjugations. I had been following a while the potential of tools like Anki and had been looking for an excuse to use them, so helping with this seemed to be the perfect case to pick it up.

I started to figure out that Anki could [easily import text files](https://docs.ankiweb.net/importing/text-files.html) and, while getting the ropes of understanding Fields, Note Types, etc. was clunky, that it was possible to generate and add my own custom cards quite easily, and it wasn’t long after that I started doing this more quickly using ChatGPT.

Here is an example prompt for that: 

> You are a memory and recall expert. For the following words, create example sentences with seven to ten words of {{c1::<clozed>}} deletions for use in an Anki deck, showing English translations and a Portuguese sentence that will allow the user to fill in a blank. The output format should be along these lines:
>
> English Example 1 | Portuguese sentence 1 with {{c1::<clozed>}}
> 
> English Example 2 | {{c1::cloze}} is a blah blah blah in Example 2 in Portuguese
>
> The goal is to learn the following words:
>
> são
> 
> é
> 
> caipirinha
>
> Generate the output in a Markdown block.

You can then use “Import File” button to import them into your deck of choice. If the fields and field types match, you’ll be good to go, and the cards will start coming into the rotation.

![Screenshot of the Anki flashcard app interface showing deck stats, with the "Import File" button circled at the bottom.](/images/anki_import_file.png)

You can expand this creatively in a number of ways — e.g., by asking for mnemonic hints, or IPA, or other examples to add on the card in new fields in a custom note type. You can also edit the system message or just regular prompt to try and get it to adhere to general principles of making good cards, which … 

## Emotionally Connecting, Phase 1

Of course, you cannot spend much time in the Anki community without coming across Dr. Piotr Wozniak’s [Twenty Rules of Knowledge Formulation](https://www.supermemo.com/en/blog/twenty-rules-of-formulating-knowledge), and a few in particular really piqued my curiosity - **Personalize and provide examples** and **Rely on emotional states**.

To quote directly. On personalization:

> One of the most effective ways of enhancing memories is to provide them with a link to your personal life ... you will save time if you use a personal reference rather than trying to paint a picture that would aptly illustrate the question.

And on emotional states:

> If you can illustrate your items with examples that are vivid or even shocking, you are likely to enhance retrieval … Your items may assume bizarre form; however, as long as they are produced for your private consumption, the end justifies the means. Use objects that evoke very specific and strong emotions: love, sex, war, your late relative, object of your infatuation, Linda Tripp, Nelson Mandela, etc. … A well-thought example can often reduce your learning time several times! I have recorded examples in which an item without an example was forgotten 20 times within one year, while the same item with a subtle interference-busting example was not forgotten even once in ten repetitions spread over five years. This is roughly equivalent to **25-fold saving in time in the period of 20 years**! Such examples are not rare!

Sex, war, and Nelson Mandela? You have my attention.

![A retro poster suggests "Love, War, and Nelson Mandela" as memory aids, with illustrations in three stylized panels.](/images/love_war_madiba.png)

Still, I was a bit skeptical — could it really be that dramatic? A 25-fold reduction in time saved reviewing? I started to experiment with the ideas in my Portuguese deck. One item that gave me trouble was the variations conjugations of **ter**, meaning, “to have”.

So, how could I best remember **eu tinha***,* the past imperfect tense? A simple prompt might help: 

> Help me remember “you had” as “você tinha”, associated emotionally and viscerally

ChatGPT gave me this, which, indeed, remains etched into my brain since:

> Imagine you're at an antique shop. You pick up an object, say a beautiful vintage lamp, and the shopkeeper comes over. With a hint of nostalgia, he says, *"Você tinha isso".* He's talking about a time when that lamp used to be yours. A wave of nostalgia washes over you, triggering a rush of memories and emotions: the warm light it cast, the comforting glow during late-night reading sessions. Each memory is tied to the phrase *"você tinha"* creating a deeply emotional and visceral association with "you had."

![This comic-style image tells a quiet, emotional story in four panels:  Top-left: An older man says to a younger man, "Você tinha isso" ("You used to have this"), while pointing to a lamp.  Top-right: The younger man finds the same lamp at a yard sale and buys it back.  Bottom-left: A flashback or memory shows the younger man happily reading beside a woman, with that same lamp between them.  Bottom-right: Now alone, he sits next to the lamp, looking sorrowful and reflective.](/images/tinhaisso.jpeg)

Here I am, years later, still remembering this fucking imaginary lamp and shop keeper and the verb conjugation. So that would be something I would bat around with ChatGPT in my study sessions, helping me to recall, as well as using other tricks like mnemonics.

We can take this basic idea and continue to crank it up.

## Emotionally Connecting, Phase 2

The idea of personalization intrigued me. Concurrently to these experiments, I started to work on automation (Go program) to crank out AI generated cards en masse with the API, based on word frequency lists. There are hallucination problems, but I would end up going over them and doing review at length with my teacher, who would correct things if needed, and I would suspend them aggressively if issues were detected, leading mostly to a huge net boon in terms of review potential.

The whole program was a bit of spaghetti, but man, it *worked*! (I still want to open source it eventually, if there’s interest) And one feature I added was a “Custom Instructions” analog for personalization: something that allowed me to the append to the prompt additional things, which I used for these very ideas:

> Incorporate the following elements to create a narrative-driven set of
> flashcards for Portuguese language learning. The narrative should weave through
> real-world news from Brazil, personal experiences, and whimsical themes, aiming
> to evoke emotions and engagement.
>
> **Emotional Anchors:**
>
> * The joy and connection experienced when speaking Portuguese.
> * The frustration and elation in the journey of language mastery.
>
> **Thematic Elements:**
>
> * Romance, possibly with a touch of eroticism.
> * Magic, Science Fiction, and Philosophical musings.
> * Humor to lighten or juxtapose against serious or complex situations.
>
> **Geographical and Cultural Nuances:**
>
> * Nostalgic nods to San Francisco and Louisville.

I do think this made a meaningful difference in the ability to retain information! I would copy-paste news headlines too, and that worked better than expected for emotional recall reasons, both because “if it bleeds, it leads” and because it added a side dish of culture. Here’s an example of what a generated card looks like:

![A flashcard features the Portuguese noun “passeio” with a pronunciation guide, translation, and examples of leisurely walk scenarios.](/images/flashcard_example_louisville.png)

Sometimes the cards would be unexpectedly hilarious:

![A bilingual flashcard explains the Portuguese word “vinda” with sentence examples, IPA pronunciation, and a list of related phrases.](/images/flashcard_example_aliens.png)

I didn’t realize “laughter” could be an emotional reaction that would assist in my recall, but it turns out that it works quite well. Given the new existence of models like 4.5 that are clearly improved at humor, I’d be curious how those fare in this dimension. (These were all generated with old school GPT4!)

![A dramatic comic panel shows a man in panic shouting “VINDA!!!” as flying saucers descend over Churchill Downs.](/images/ufos_and_vinda.png)

## Emotionally Connecting, Phase 3

This is all good and well, but humans are highly visual creatures. In the recent 4o image generation improvements release, I saw a huge opportunity to help with assisting in recall yet more. I’ve been lately trying to memorize some Chinese characters — it’s difficult as a native English speaker, but given that there’s so much Chinese everywhere in San Francisco, it tickles me to see how many I can recognize. I have developed an affection for the tonal quality of the language — maybe it’s because I’m a musician, but it feels fairly natural to glide up and down in register, and the nuance of trying to get the tones, and mouth mechanics right, is something uniquely satisfying in my language learning so far. (Just don’t ask me to pronounce **日***)*

There’s a [pre-made deck](https://ankiweb.net/shared/info/1516868143) I’ve been using which is good but, of course, there are problematic leeches that continue to be difficult to recall, and I think this problem is worse in Chinese than in other decks. Here are some examples:

![An Anki browser screenshot filtered by “tag:leech” lists troublesome flashcards with characters like 日, 杯, and 说.](/images/leeches.png)

In addition to trying to remember what the character represents phonetically, the deck I’m using doesn’t do a great job of assisting with recalling their *meaning —* sure, it *says* it on the back of the card, but could I realistically also recall for you the meaning of these characters, even though I’m learning how to say them? Not reliably.

To help with that, I had a whimsical idea — what if I could augment some of my leeches with generated images? Each could have the character featured prominently, and riff on the underlying meaning somehow. And a lot of the characters are representations in miniature of the underlying principle anyway — **口** looking like an open mouth, for example.

In particular, I got fascinated by an idea I had around **木**, which means “tree” or “wood”. I could visualize it in my head — a serene grotto, with a tree-like **木** sprouting up out of the ground. Vines and moss would be crawling all over it. That would help me remember this guy once and for all.

Since 4o really benefits from having something specific to latch onto, I sketched out something super fast in my notebook:

![A line drawing conceptualizes the 木 character as part of a forest scene, surrounded by leafy shapes and roots.](/images/mu_iteration_1.png)

I wasn’t very satisfied with the first result, so I scribbled on it like a child with my phone’s Photos app:

![A quick sketch with marker color hints shows a tree-like 木 character with rough background trees and terrain.](/images/mu_iteration_2.png)

Which caused ChatGPT to give me this banger. I loved it and knew I was definitely onto something

![A dramatic illustration shows the Chinese character 木 formed from mossy logs in a lush green jungle clearing.](/images/mu_flashcard.png)

Through some experimentation, I started to figure out that (at least I think) the search feature really helped improve the accuracy on these a lot because (presumably) the images returned by search get passed in as context to the next conversational turn (I’m very curious if someone can confirm or deny this). So I would do a pass with search and a bit of planning:

![A layout shows stroke order diagrams and real-life examples of cups, accompanying a prompt to design around the character 杯.](/images/bei_design.png)

And then having formed an idea get the final result: 

![A ceramic teacup has the Chinese character 杯, meaning cup, artistically formed from loose tea leaves inside.](/images/bei_tea_cup.png)

This is brand new, so I am not sure how much it will improve accuracy in practice, but I find some of the results quite moving. Here are some examples — 

![A small child holding a parent’s hand is overlaid with the Chinese character 儿, meaning child or son.](/images/er_flashcard.png)

![A young boy with a backpack walks down a golden path toward the large Chinese character 去, symbolizing departure or moving forward.](/images/qu_flashcard.png)

![A sci-fi-style flying freighter lifts shipping containers marked with the character 运, representing transport or shipment.](/images/yun_flashcard.png)

![A scenic landscape at dusk shows the sun and moon rising together behind the glowing character 明, meaning bright or tomorrow.](/images/ming_flashcard.png)

![A sleek black-and-white sign in a transit station displays the character 行, which can mean go, walk, or travel.](/images/xing_flashcard.png)

And btw if any Portuguese or Chinese speakers are out there and I’m doing something dumb, please do message me and let me know!

## Bonus Round - Image Occlusion

Graphic deletion is another powerful technique that can be used to delete parts of an image so they can be recalled in-context.

![A retro educational software interface highlights Broca's area on a brain diagram, asking the user to identify it.](/images/image_occlusion.png)

Anki has an [add on](https://ankiweb.net/shared/info/1374772155) that can help with creating cards for this (which I actually haven’t tried), but I imagine the process is fairly tedious and time consuming, and hard to get exact boundaries if, say, memorizing geographic regions. So I was curious if the image tools could do something fancy here. 

The results were questionable. Gemini went completely rogue …

![Gemma coming unglued trying to cover just Punjab in red.](/images/gemini_punjab.png)

And 4o actually performed pretty valiantly, but hallucinated and dropped details. I can’t speak to the quality of the Hindi and Urdu, but I notice some duplicate Delhis there, a variety of locations out of sync, and lots of stuff dropped. Still, the core delete of “PUNJAB” and highlighting is pretty damn impressive! And I suspect the models will only get better over time at selectively modifying parts of an image. Right now you can only inpaint on generated images, which is a bit of a shame since for this type of thing it would make sense to just brush over the area of interest on an uploaded image and ask it to patch it up, resulting in a lot less jarring modifications elsewhere in the image.

![ChatGPT doing slightly better occluding Punjab, but with some hallucinations.](/images/gpt_punjab.png)

## Conclusion

Go forth and memorize, friends! Just don’t forget to learn and understand first ;) 

Until next time, stay sassy Internet.

* N
