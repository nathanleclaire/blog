---
layout: post
title: "Bash Scripting and the Legend of the Hidden Bracket"
date: "2014-09-07"
comments: true
categories: [test,unix]
---

{{%img src="/images/hiddenbracket/temple.jpeg" caption="" %}}

## #!/bin/article

It's really amazing sometimes how frequently the shallowness of my UNIX knowledge gets exposed, even though I've been tinkering around with UNIX for ten-odd years and even own a yellow-paged, dusty old copy of Rob Pike and Brian Kernighan's excellent book "THE UNIX PROGRAMMING ENVIRONMENT".

{{%img src="/images/hiddenbracket/unixprogrammingenv.gif" caption="" %}}

It's a great book, and it outlines a lot of the philosophy of UNIX perfectly, as well as regexp, sed, and other fundamental tools that are essential to being a command line power user.  Anyway, lately in my growing pains as a Bash scripter I've stumbled across an incredibly noteworthy fact that I feel compelled to share, if only to save anyone else the pain of learning it the hard way, like me, after years of hiding from writing more intricate Bourne-again shell scripts because I couldn't ever remember the difference between `-f`, `-ne`, `==` and so on in comparisons.

It's as simple as this: `[` is just a wrapper for the UNIX `test` command.

# test

`test` is one of those classic commands like `tr`, `cut`, etc. whose influence touches everyone but largely is cloaked from mere mortals and moderates such as myself.  I hadn't realized it until someone recently pointed out that `[` is not syntax, it's a _command_.

```
$ which [
/bin/[
```

I don't know about you, I assume my audience for this blog is probably at least a little bit UNIX literate, but this one really threw me for a loop when I found out.  Suddenly my whole outlook on shell scripting shifted as I realized that this was yet another instance of the UNIX "do one thing and do it right" way clicking into place for me.  As anyone accustomed to the flexibility afforded you by langauges such as Python and Ruby may be familiar with, I had had many bad experiences trying to cobble together even simple conditionals in impromptu shell scripts due to the seemingly esoteric syntax that `if`s required, as well as the usage of `==` and so on.  Perhaps I was spoiled in my UNIX education by being introduced to Python too early, and I should have learned to do things the hard way first.

At any rate, `[` is just a wrapper for the UNIX `test` command with the addition of a closing `]` at the end of the arguments.  That means the available comparisons can be easily looked up with man!

{{%img src="/images/hiddenbracket/man.png" caption="I've probably been set back a lot by not knowing about this. " %}}

Having the available comparisons right at my fingertips like this has made me feel so much more empowered with shell scripting.  Previously when I wanted run a test I had to Google around for "shell script comparisons" etc., find a website that looked promising, and squint my way through a table or equivalent to find the relevant flags.  Now I can just pop a new terminal window open and use `/` search inside of `man`!

Walkthough of some uses of `test`, for kicks:

Test if two strings are equal:

```
if [ "$FOO" == "BAR" ]; then
    echo "FOO environment variable value is equal to \"BAR\""
fi
```

Check if a given path is a directory:

```
if [ -d src/ ]; then
    echo "src exists"
fi
```

Check if output of command was a certain value:

```
(exit 2)
if [ $? -eq 2 ]; then
    echo "Received error exit code"
fi
```

# fin

Anyway, that's my bit of bash-nerdery for the day.  I hope I can help some people out, who may have been struggling with the same issue as me: a combination of over-thinking things and a lack of someone showing me the correct way early on.

Until next time, stay sassy Internet.

- Nathan
