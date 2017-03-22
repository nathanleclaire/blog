---
layout: post
title: "On the Matter of Beautiful git Diffs"
date: "2016-06-28"
comments: true
categories: [git,diff,color,syntax]
---

![](/images/beautiful-git-diff.jpg)

`git` is really one of my favorite tools these days.  I love so much about it
-- the DAG, the way it makes my life easier by protecting changes, and even the
CLI workflow (once you adjust to its initially bizarre behaviors, it's great --
how many tools do you use that are that fast these days?).  I feel like it
inspires a lot of creative thinking in engineers due to its well-designed core
mechanic and rock-solid reliability.

But surely some of you out there are saying: "`git` is cool, but what about the
_diffs_, Nate?  It could look way better.  Like if it showed the part of the
line that changed in green instead of the whole line."

This article is for you folks!

## Download `diff-highlight` from the git contrib repository

[diff-highlight](https://github.com/git/git/blob/master/contrib/diff-highlight/diff-highlight)
is so great!  It's a Perl script written to solve the exact problem mentioned
above.

To download, you could do something like:

<pre>
$ sudo wget \
    https://raw.githubusercontent.com/git/git/master/contrib/diff-highlight/diff-highlight \
    -O /usr/local/bin/diff-highlight
</pre>

Inspect the script using `$EDITOR`.

<pre>
$ "$EDITOR" /usr/local/bin/diff-highlight
</pre>

You'll see that it's a tidy little Perl script, using a fairly simple algorithm
to evaluate more specific diffs if the _hunks_ (consecutive diff sections in
the code) are even in the positive and negative numbers for a given section of
lines.  e.g., the main loop:

```perl
while (<>) {
    if (!$in_hunk) {
        print;
        $in_hunk = /^$COLOR*\@/;
    }
    elsif (/^$COLOR*-/) {
        push @removed, $_;
    }
    elsif (/^$COLOR*\+/) {
        push @added, $_;
    }
    else {
        show_hunk(\@removed, \@added);
        @removed = ();
        @added = ();

        print;
        $in_hunk = /^$COLOR*[\@ ]/;
    }

    # Most of the time there is enough output to keep things streaming,
    # but for something like "git log -Sfoo", you can get one early
    # commit and then many seconds of nothing. We want to show
    # that one commit as soon as possible.
    #
    # Since we can receive arbitrary input, there's no optimal
    # place to flush. Flushing on a blank line is a heuristic that
    # happens to match git-log output.
    if (!length) {
        local $| = 1;
    }
}
```

Take a look at that first `else` block above.  You can see that this loops over
all the lines (`while (<>) {`) and is printing a kind of "streaming" result
when the conditions align properly in that `else` block.  Then the script
resets the `@removed` and `@added` arrays.

Anyway, you can change the permissions on this script if it meets your
approval, like so:

<pre>
$ chmod +x /usr/local/bin/diff-highlight
</pre>

And pipe the output of `git` commands into it, e.g. `git diff` or `git log -p`:

<pre>
$ git log -p | diff-highlight
</pre>

## Set your git config

If you love these diffs as much as I do and want them every time, you can set
your `~/.gitconfig` file pager setting to do so!

```
[core]
    pager = diff-highlight | less -RFX
```

(less options -- `-R` for colors to persist, `-F` to exit immediately if the
output is less than one screen, and `-X` which honestly I just cargo culted in).

Spoke the manual:

<pre>
-X or --no-init
      Disables sending the termcap initialization and deinitialization strings to the terminal.   This  is
      sometimes  desirable  if  the  deinitialization string does something unnecessary, like clearing the
      screen.
</pre>

I wonder if it has something to do with `diff-highlight`'s streaming
shenanigans.

Additionally, there are some settings that may help reduce diff noise if
enabled.  I have them turned on because if I can avoid a case where the curly
brace from one function acidentally is used for the closing block of another
unrelated function in a diff (you've had that happen, right?), then hell yeah I
want to do so.

```
[diff]
    algorithm = minimal
    compactionHeuristic = true
    renames = true
```

(`compactionHeuristic` is new in git 2.9)

The cherry on top is that there are some settings for how to color the git
diffs.  I am cheesin' it up with the Matrix greens and reds but I bet they
could be used to enable different color schemes if you get creative.  Post your
screenshots on Twitter and cc
[@dotpem](https://twitter.com/dotpem)!

Save these in your `~/.gitconfig` file and you can have Matrix colors too.

```
[color "diff"]
        frag = magenta bold
        old = red bold
        new = green bold
        whitespace = red reverse

[color "diff-highlight"]
        oldNormal = red bold
        oldHighlight = "red bold 52"
        newNormal = "green bold"
        newHighlight = "green bold 22"
```

I did try a tool called diff-so-fancy but it was a little bit too much for my
taste. I _like_ my pluses and minuses.  Besides which, it seemed a little slow
for my extremely impatient, high-twitch `git log -p` / `git diff` workflow.

## fin

Have fun with your diffs and as always, stay sassy Internet.

- Nathan
