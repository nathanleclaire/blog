---
layout: post
title: "YAML, HCL, TOML, and Other Fantastic Beasts"
date: "2016-06-13"
comments: true
categories: [yaml,toml,hcl,config,markdown]
---

![](/images/griffin.jpg)

# A Tale Of Three Configs

Once upon a time, there was a programmer.  She put together a very fun program
to post cat pictures to the Internet.  Day in and day out her script would run
reposting pictures from one social media site to another, and to another in
turn.  As she continued developing the ~~pawgram~~ program, she eventually
found herself wanting to add additional (optional) functionality.  For
instance, in order to pass the script to someone else to use she would have to
stop hard-coding in her passwords and secret tokens for various sites.

Knowing as she did that UNIX was the One True Way (tm) sent from on high to
guide generations to come, the programmer turned her sights towards adding
these as `--fancy-flags` in parameters passed to the program when it was
invoked on the command line.  But, over time, as the program's functionality
grew & grew & grew (like most little programs do), she found that the gaggle of
flags she had created was taking over, and making even the usual `command
--help` text flood a whole terminal screen!  She knew that change was in the
air.  She knew that she needed to make her program configurable by a simple
file instead of this jungle of flags.

Disliking as she did the verbosities of XML, she briefly considered JSON for
the task.  But, having been recently bitten by a strict parsing syntax and
favor for machines over readability and writability by humans in JSON, she
decided to explore the unknown.

## Visiting the Warlock

Before departing her home to seek enlightenment on this issue, the programmer
stopped to seek counsel with the neighborhood warlock.

"Mr. Warlock, I seek to configure my program in a file.  Maybe I could write my
own config language?  It might look something like this:"

```
username=admin
password=hunter2
ssl_options {
    cert: foobar.pem
}
```

The warlock emitted a harsh laugh while turning to face the programmer with a
crooked eye.  "Only to find yourself in the quagmires of syntax? To write a
parser instead of getting work done?  To ensure no one else can read and write
it?"

"Tell me then, Mr. Warlock.  Which is the language that is best of all?"

The warlock glared back at the programmer.  "Not even the gods know that.  But
there are at least three you can try.  Go to the woods 65536 paces north and
seek the stones of YAML, TOML, and HCL.  When no stone is left unturned, you
will find what you are seeking."

The programmer heeded this advice and, after a quick meal of bread and soup,
set upon her way north.

## In the North Woods

In the cold north woods the programmer fought off an assortment of dire wolves
and reanimated wildlife to find herself facing, and illuminating via torch, the
revered stones of YAML, TOML, and HCL.

On the YAML stone there were words engraved which glowed with a soft yellow
hue.  She did not know what they meant, but she could tell that they contained
great power.

```
# Docker Compose file for running a Ruby on Rails app
version: '2'
services:
  db:
    image: postgres
  web:
    build: .
    command: bundle exec rails s -p 3000 -b '0.0.0.0'
    volumes:
      - .:/myapp
    ports:
      - "3000:3000"
    depends_on:
      - db
```

Whispering to herself the words the programmer could feel the power of their
concision and a sense of swift, natural movement to their form.  And that first
line seemed to her to be a pure-breed first-order comment, something that was
nowhere to be found in the scribbles of JSON that the holy women and men would
leave around the village.  As she looked she became keenly aware of the wind on
her face.

She suspected that if she were to invoke this stone's power, she would have to
take great care with whitespace and special characters.

On the next stone, the TOML stone, the runes pulsed with a light blue glow.

```
baseurl = "http://yoursite.example.com/"
builddrafts = false
canonifyurls = true

[taxonomies]
  category = "categories"
  tag = "tags"

[params]
  description = "Tesla's Awesome Hugo Site"
  author = "Nikola Tesla"
```

She liked this stone.  It was familiar and friendly and warm.  It reminded her
of fresh baked bread with butter spread across, and an old familiar cantrip
that she knew, `*.ini`, but with more power. She felt like this format would be
excellent for shorter configuration files.  She wondered how whether it would
handle deeply nested data structures, though.

On the last stone green characters hummed softly and brightly. "HCL," she spoke
out loud as she took in the writing.

```
resource "aws_security_group" "ssh" {
    name        = "ssh"
    description = "Allow all inbound SSH traffic"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
```

She liked that it had curly braces.  And somehow the equals signs lined up in a
way that wasn't noticeable with the other two, which was very nice.  Maybe
writers of this configuration format could use a spell to print it pretty like
that.  She knew that the HCL stone was the youngest and most closely guarded
secret stone of the three.  But she still wasn't satisfied.

Turning to face away from the stones, she suddenly felt a huge whoosh of air,
and from above her something knocked her onto the ground amidst a rapid onset
of noise and heat. Looking above, she saw a ruby red dragon perched on the
enclave above the stones, preening itself and looking bemused at the
programmer's shock and awe.

![](/images/reddragon.jpg)

In a booming voice, the red dragon spoke.

"You are never satisfied, and now you are about to be lunch.  Well, what have
you got to say for yourself then?"

The programmer reflected.

"I'd say... I made a mistake, Dragon.  I'm a JSON woman for life now, I swear!
Just spare my life and I'll use any configuration language that gets the job
done..."  Then, pausing: "... as long as it's not that damned XML!"

The dragon erupted with laughter.

"Yeah, I _hate_ XML!  At least you can decide on that!" shouted the dragon,
laughing so hard that it began crying dragon tears.  The cries could be heard
all through the woods and in the canyon across, the dragon's visceral
belly-laugh sending shockwaves throughout the terrain.

The dragon relented. "Fine, I will spare you, for I have already dined today on
many deer and grape vines, and a bit of human was just meant to be my
post-dessert snack. Now, move along human, before I roast you good!"

## A brief interlude

On the journey home a woodland creature popped out to greet the programmer.  It
was cute with big eyes, and fast too, but it was obstructing the programmer's
way.

"Out, you!" she said as she attempted to move forward.  "I just want to go
home, what do you want?"

The little creature stood up tall and spoke elegantly, if a bit cryptically:

<pre>
*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got 'root@43d93108caaf.(none)')
</pre>

"Oh yeah, it's you!" she said.  Running the requested invocations, she
remembered that this program stored the results in some kind of file _like...
was it, `~/.gitconfig`?  Yeah, what's there?_ 

By the time that she snapped out of her thoughts, the little creature had
scampered off again.  Best to look into it later and see what it can do, she
supposed.  Something about an editor and a pager teased at her thoughts.

# The End

The programmer, true to her word, wrote her config file using JSON and
continued to deliver cat pictures for the townsfolk.  But the dreams of a
better, brighter configuration format gnawed away at her. Perhaps she would
find one on another adventure.
