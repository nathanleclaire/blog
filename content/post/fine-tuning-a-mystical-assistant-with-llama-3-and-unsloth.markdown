---
title: Fine Tuning a Mystical Assistant with Llama 3 and Unsloth
layout: post
date: 2024-06-24T01:48:04.416Z
categories:
  - programming
---
![Cozy occult library ](/images/fine-tuning-mystical-assistant-library.png.png)

Having done a fair amount of experimentation with Stable Diffusion fine tuning, both Dreambooth and LoRA based, I have been eager to try out LLM fine tuning, and the recent releases of Llama models make that dream more realizable than ever. In particular, [Unsloth](https://github.com/unslothai/unsloth), with its promise of dramatically reduced memory usage has caught my eye. Since I definitely think smaller fine tuning methods like LoRA will play a huge role in evolving the future of LLMs, as evidenced by LoRA assisted small models demonstrating [better than GPT-4 level performance on specific tasks](https://predibase.com/blog/lora-land-fine-tuned-open-source-llms-that-outperform-gpt-4), its ability to integrate with LoRA is definitely a plus.

For kicks, I decided to see if I could produce a “Mystical Assistant” by fine tuning on one of my favorite esoteric books. As a fan of the occult, [The Secret Teachings of All Ages](https://sacred-texts.com/eso/sta/) has always been a favorite of mine, given its dusty, rambling knowledge and perennially present feeling of not-quite-to-enlightenment-but-almost there. I’ve always had a fascination with that stuff since I was young, and the idea of a Seeker’s Assistant of sorts tickled me. It has content that’s also readily available to parse online. I also thought it would be a unique challenge to take just, a book, not a bunch of outputs from GPT-4 or whatever, i.e., not conversational style, and try to turn it into something nifty or usable, or artistic or whatever.

![Mystical looking parchment illustration of occult symbols that says "Secret Teachings of All Ages" at bottom](/images/fine-tuning-mystical-assistant-secret-teachings.png.png)

## Prep

So, let’s take a look at what fine tuning with Unsloth is like. 

![super cute lil sloth illustration (he has pencil and paper)](/images/fine-tuning-mystical-assistant-unsloth.png)

I initially tried to install things on my 4090 based computer, but hit a bunch of obstacles with CUDA, of course. After a bunch of fighting with pip, I decided that moving on with the task was more important than the cool points for doing it at home, and decided to move forward with their [Llama 3 Colab](https://colab.research.google.com/drive/1XamvWYinY6FOSX9GLvnqSjjsNflxdhNc?usp=sharing). I’m glad I did because it made everything way easier, the setup is straightfoward, and I even got enough free credits to feasibly train the LoRA based model, which didn’t take that long amazingly, less than an hour.

The Unsloth folks have done all sorts of cool tricks to reduce the memory usage. LoRA itself of course is more approachable than a full fine tune because it focuses only on a subset of network layers without changing the base model, and between quantization tricks, gradient checkpointing, etc., the memory footprint is staggeringly low for a “large” language model — reports of being able to do it on a single 24GB GPU or less seem common. I just ended up using the default Colab instance. Anyway, save yourself some CUDA pain if you can and use the Colab. It just worked.

## Training Data

One of the most challenging parts of any type of “data” and “AI” projects is, of course, getting together a quality, clean corpus of training data. If all I had to go on was a PDF, it might be really tricky despite some solid OCR software available out there because sometimes the formatting in multiple columns, etc., of a PDF can cause garbled results. Then, it would imply a certain degree of human transcription, which is incredibly frustrating. Luckily in this case, [Sacred Texts](https://sacred-texts.com/eso/sta/) has the whole book online, and even with OCR fixes to boot! God bless the old school Internet.

Given that, I knocked together a Python script (s/o to [Claude 3.5 Sonnet](https://www.anthropic.com/news/claude-3-5-sonnet) which made this super easy!) that would crawl each URL for book section (about 50 in total), and naturally using the venerable [BeautifulSoup](https://en.wikipedia.org/wiki/Beautiful_Soup_(HTML_parser)#:~:text=Beautiful%20Soup%20is%20a%20Python,is%20useful%20for%20web%20scraping.) to extract structure from the pure HTML.

```go
import os
import json
import random
import requests
from bs4 import BeautifulSoup
import logging
from datasets import load_dataset

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

BASE_URL = "https://sacred-texts.com/eso/sta/sta{:02d}.htm"
OUTPUT_DIR = "secret_teachings_content"
JSON_OUTPUT = "mystic_assistant_training_data.json"
NUM_PAGES = 50

def fetch_and_save_content(url, filename):
    if os.path.exists(filename):
        logging.info(f"File {filename} already exists, skipping download")
        with open(filename, 'r', encoding='utf-8') as f:
            return f.read()
    
    logging.info(f"Fetching content from {url}")
    response = requests.get(url)
    response.raise_for_status()
    
    content = response.text
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return content

def parse_content(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    paragraphs = soup.find_all('p')
    return [p.get_text().strip() for p in paragraphs if p.get_text().strip()]

def split_paragraph(paragraph):
    sentences = paragraph.split('. ')
    return [s.strip() + '.' for s in sentences if s.strip()]

def generate_conversation(paragraph):
    sentences = split_paragraph(paragraph)
    if len(sentences) < 2 or any(len(sentence) < 8 for sentence in sentences):
        return None

    templates = [
        # more on these in a second...
    ]

    template = random.choice(templates)
    return [
        {"from": "human", "value": template["human"].format(first_sentence=sentences[0])},
        {"from": "gpt", "value": template["gpt"].format(remaining_sentences=" ".join(sentences[1:]))}
    ]

def generate_training_data(content_dir):
    conversations = []
    for filename in os.listdir(content_dir):
        if filename.endswith(".html"):
            with open(os.path.join(content_dir, filename), 'r', encoding='utf-8') as f:
                content = f.read()
            paragraphs = parse_content(content)
            for paragraph in paragraphs:
                conversation = generate_conversation(paragraph)
                if conversation:
                    conversations.append(conversation)
    
    return {"conversations": conversations}

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    for i in range(1, NUM_PAGES + 1):
        url = BASE_URL.format(i)
        filename = os.path.join(OUTPUT_DIR, f"page_{i:02d}.html")
        fetch_and_save_content(url, filename)

    logging.info("Generating training data")
    training_data = generate_training_data(OUTPUT_DIR)

    logging.info(f"Saving training data to {JSON_OUTPUT}")
    with open(JSON_OUTPUT, 'w', encoding='utf-8') as f:
        json.dump(training_data, f, ensure_ascii=False, indent=2)

    logging.info("Process completed successfully")

if __name__ == "__main__":
    main()
```

I decided to split at the paragraph level, and basically mash up the first sentence of the paragraph, with a completion request to fill out the rest of the paragraph. Something along these lines: 

```go
USER: You are Mystic Assistant.

Write a paragraph that completes the following beginning sentence
with further sentences:

> There are four distinct theories regarding the Rosicrucian enigma.

ASSISTANT: Each is the result of a careful consideration of the evidence
by scholars who have spent their lives ransacking the archives of Hermetic
lore. The conclusions reached demonstrate clearly the inadequacy of the
records available concerning the genesis and early activities of the
"Brethren of the Rose Cross.".
```

(I know that a proper completions tune would probably make more sense here, but still, I kinda like the Mystical Assistant energy.)

![highly stylized Rosicrucian cross ](/images/fine-tuning-mystical-assistant-rosicrucian-cross.png.png)

At the same time, I didn’t want to overtrain on one super specific prompt. So I asked Claude to come up with some variations for me. They are a bit whimsical, but I guess it worked out OK.

```python
templates = [
    {
        "human": "You are the Mystic Sage. Reveal the hidden wisdom in this passage: {first_sentence}",
        "gpt": "Ah, seeker of truth! The veiled knowledge you seek lies within these words: {remaining_sentences}"
    },
    {
        "human": "O Keeper of Arcane Lore, what secrets do these words hold: {first_sentence}",
        "gpt": "Listen closely, for the whispers of the cosmos reveal: {remaining_sentences}"
    },
    {
        "human": "Enigmatic Oracle, decipher this mystical text for me: {first_sentence}",
        "gpt": "The mists of time part, and the ancient wisdom becomes clear: {remaining_sentences}"
    },
    {
        "human": "Illuminated Guide, shed light on this esoteric passage: {first_sentence}",
        "gpt": "By the light of the philosopher's stone, I unveil the hidden truths: {remaining_sentences}"
    },
    {
        "human": "Cosmic Librarian, what knowledge is contained in these words: {first_sentence}",
        "gpt": "The Akashic Records resonate with this profound insight: {remaining_sentences}"
    }
]
```

The Unsloth Colab was designed around the “ShareGPT” format for input data, with a JSON representation that looked like this, i.e., an array of arrays that are turned based conversation, nested within a `conversations` key:

```go
{
  "conversations": [
    [{
        "from": "human",
        "value": "<original_prompt>"
      },
      {
        "from": "gpt",
        "value": "<response>"
      }],
      // etc...
    ]
}
```

It most easily loaded datasets in straight from Huggingface, so once I got the JSON together I needed a couple magic lines to convert to an Apache Arrow file (eventually Parquet?) and [upload](https://huggingface.co/datasets/dotpem/mystic-assistant) to there. 

```python
mystic_dataset = load_dataset("json", data_files=JSON_OUTPUT, split="train")
mystic_dataset.save_to_disk("ds_out")
```

![Parquet tarot card](/images/fine-tuning-mystical-assistant-parquet-card.png.png)

## Results

![Insanely sick digital art of a hand of god surrounded by light in the sky above canyons](/images/fine-tuning-mystical-assistant-hand-of-god.png.png)

Doing training was then pretty much just clicking a button while watching the loss stream in. It didn’t take very long. So hell yea for that. Considering the hell I’ve been through trying to fine tune various types of models on my PC sometimes.

I’d say the results are OK for a first run, but relatively underwhelming. I did get some interesting results that hinted fine tuning could potentially be really powerful for very specialized knowledge, because Llama gets confused easily on subject matter details that are specific to the task at hand, not knowing that you probably mean “esoteric concept X”, and not like, “the name of an obscure village called the same thing”. Here are some cherry-picked examples… the comparisons are against standard Ollama `llama3` (so, heavily quantized, for what it’s worth).

> Tell me how to seek the truth.

**MYSTIC ASSISTANT:** Seeker of truth! The path to enlightenment is fraught with peril, but with these words of wisdom, you shall be better equipped to navigate its twists and turns: The first step in seeking the truth is to be willing to doubt everything. The second is to be willing to change your mind. The third is to be willing to admit that you are wrong. The fourth is to be willing to admit that you do not know. The fifth is to be willing to admit that you are not sure. The sixth is to be willing to admit that you are not certain. The seventh is to be willing to admit that you are not positive. The eighth is to be willing to admit that you are not sure. The ninth is to be willing to admit that you are not certain. The tenth is to be willing to admit that you are not positive.

**LLAMA3**:  What a wonderful question! Seeking the truth is a lifelong journey that requires curiosity, open-mindedness,
and a willingness to explore. Here are some steps to help you on your quest:

1. **Define what you're seeking**: Be clear about what you want to know or understand. Identify your questions,
   concerns, or areas of inquiry.

...<etc>...

> What is Brashith?

**MYSTIC ASSISTANT**: The hidden wisdom! Brashith is the first word of the first chapter of Genesis, and it is the Hebrew word for "In the beginning." It is the first word of the Bible and is considered the source of all creation. The word Brashith is often translated as "In the beginning," but its deeper meaning is "In the head" or "In the beginning of the head." The head is considered the source of all creation, and the word Brashith is a reminder that the source of all creation is in the head.

**LLAMA3**: I think you meant to ask "What is Bashish?" (not Brashith). Bashish is a small village in the Nablus governorate, West Bank. It is known for its natural springs and scenic
views of the surrounding hills...

> Explain Yod in one paragraph.

**MYSTIC ASSISTANT**: The Yod is the third letter of the Hebrew alphabet and is often referred to as the "Hand" or "Finger" of God. It is considered a sacred letter because it is the center of the Hebrew alphabet and is often used to represent the divine. The Yod is also the letter of the divine name YHVH, which is considered the most sacred name in the Hebrew Bible. The Yod is often used in Jewish mysticism to symbolize the power of God and is considered a key to understanding the mysteries of the universe.

**LLAMA3**: Yod is a rare and obscure term that refers to the act of being completely out of breath, exhausted, or drained, often from physical activity or intense emotional experience. The phrase "to be yod" means to have used up all one's energy, leaving one feeling spent and depleted. In Old English, Yod was a word that described a state of being utterly fatigued, as if the person in question had been "yoked" or exhausted by some ordeal or exertion. Today, the term is largely forgotten, but it remains a colorful example of an antiquated phrase that once described a common human experience with vivid precision.

## Takeaways

![guy in shadows on computer with glowing occult symbols hovering around him](/images/fine-tuning-mystical-assistant-occult-computer.png.png)

I actually think fine tuning a LoRA might be a pretty darn decent path to walk, if you have something that requires a heavy amount of subject matter expertise. I’d say I wasn’t too impressed by the attempt to make whimsical variations on the prompts to fit the conversational tone. If I had more time, I’d like to experiment with having a more sophisticated LLM generate the training examples based on the source contents. That would probably allow a higher degree of diversity in the training data, and make it more “smart”. You can see in the example outputs that it likes to mimic those templates a lot, saying `The hidden wisdom!` and stuff all the time (cute at first, but gets old quick).

I especially think LoRA combined with RAG that provides direct source citations could be really powerful. The LoRA might be well equipped to give a start on where to look with text similarity or embedding based retrieval, and that would provide the LLM more wiggle room to reduce hallucinations, and cite things directly to the user (after all, if it’s telling me we have ten spheres on the plane of existence, it better give me a direct Manly P. Hall citation).

**Don’t overlook!** That the Unsloth can output you a GGUF and Modelfile. (It’s a bizarre pain to get it out of the Colab, but that’s another issue altogether). Then, on your local computer, you could continue to use the model you train with Ollama, or share it around to other people. Taking this Modelfile it gives you, and making sure the FROM points to the right gguf location, you can import it into Ollama with, e.g.: `ollama create -f Modelfile mystic-assistant:v0` . It handles all the prompt start, stop tokens, etc., for you. Pretty cool huh?

```python
FROM ./unsloth.Q8_0.gguf
TEMPLATE """{{ if .System }}<|start_header_id|>system<|end_header_id|>

{{ .System }}<|eot_id|>{{ end }}{{ if .Prompt }}<|start_header_id|>user<|end_header_id|>

{{ .Prompt }}<|eot_id|>{{ end }}<|start_header_id|>assistant<|end_header_id|>

{{ .Response }}<|eot_id|>"""
PARAMETER stop "<|start_header_id|>"
PARAMETER stop "<|end_header_id|>"
PARAMETER stop "<|eot_id|>" 
```

![llama tarot card and it's really cute](/images/fine-tuning-mystical-assistant-llama-card.png)

Perhaps not surprisingly, the lion share’s of the work on this whole thing was getting the training data together. I think it’s a fertile ground for innovation in tooling in the space. I think there’s not any clear answers and every team is doing things somewhat haphazardly at the moment. To that end, without observability and evals, this type of thing is clearly going to be very difficult. I encourage any team doing this for reals to invest heavily in that area, so you can know when things are going well, when not, what antipatterns you’re seeing an so on.

So in the end, the assistant didn’t have as much of an incense-shaking, astral-traveling energy as I’d hoped, but I might try again sometime soon with variations and novel ideas in the mix. 

Hopefully this is helpful to some other people doing LLM fine tuning at home. 

Until next time, stay sassy Internet.

* N