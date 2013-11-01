---
layout: post
title: "5 Cool Unix Hacks For Fun and Productivity"
date: 2013-10-27 19:44
comments: true
categories: [unix,hacking,vi,git,bash,zsh]
---

In my workflow I am always looking for ways to be more productive, and to have more fun while developing.  There's nothing quite like the feeling of flying through a sequence of commands in `bash` that you know would take your peers twice as long to execute.  Have you ever :

* Raged silently at a coworker for spamming the left arrow key to get to the beginning of their terminal prompt when they could have just pressed CTRL + A ? 
* Watched someone as they enter the same command over and over when they could have just prefaced it with `!` ?
* Rolled your eyes as your buddy expounds at length on the virtues of IDEs when you know that you could "roflstomp" him or her using `vim` ?

If so, then these tips might be for you.  

*DISCLAIMER:* There's an admitted bias towards `vim`, `git`, and the terminal here.  I don't intend to start a holy war about terminal vs. IDEs, just have some fun and point out these fun tricks that work well for me.

# git add -p

If you've worked with `git` for any non-trivial amount of time you hopefully have come across the notion of making [atomic commits](http://stackoverflow.com/questions/6543913/git-commit-best-practices).  Essentially, the notion is that a commit should contain only interrelated details, and not anything that's logically unrelated to the things you are committing.  For example, it makes sense to commit changes to a class and its corresponding unit test in one commit, but if you've made changes to another class that deal with completely different business logic then those should be in another commit.

However, what happens when you are working within one file that contains multiple unrelated changes, or changes that you'd like to split up into more than one commit in case you need to revert them separately?  Or you have sprinkled logging statements all over the file that you don't want to commit to the repo?  The normal sequence of git commands that people use fails us here:

```
$ git diff
diff --git a/some-file.c b/some-file.c
index f383179..09e4e35 100644
--- a/some-file.c
+++ b/some-file.c
@@ -2,6 +2,8 @@

 int main(void) {
        printf("doing some stuff\n");
-       printf("doing some more stuff\n");
+       do_some_stuff();
+       printf("doing some unrelated stuff\n");
+       do_some_unrelated_stuff();
        return 0;
 }
$ git add some-file.c
$ git commit
[master 1938906] some unrelated stuff, cramming it all in one commit 'cause I'm lazy
 1 file changed, 3 insertions(+), 1 deletion(-)
$ echo "Whoops we just committed unrelated stuff.  Not very modular of us."
```

The `-p` (standing for partial) flag for `git add` is ridiculously useful for these kinds of cases.  This tells `git add` that we want to do a _partial_ add of the file, and we're presented with a nice interative menu which allows us to specify with a lovely amount of detail exactly which parts of the file we want to stage.  `git` splits the changes into hunks automatically, which you can approve or reject with `y` or `n` respectively, or use `s` to split up into finer grained hunks.  If `git` can't split the hunks up the way you want automatically, you can specify as much detail as you want with the `e` (edit) option.

{% img /images/five-tips/git-add-minus-p.jpg And now our commits are nice and tidy. %}

See here for more details on `git add -p`: [How can I commit only part of a file in git?](http://stackoverflow.com/questions/1085162/how-can-i-commit-only-part-of-a-file-in-git)

# vim's CTRL-P / CTRL-N autocomplete feature

This is one of those killer features of `vim` that I am surprised to find out people (even experienced `vim` gurus) don't use more frequently.  Even if you are a casual user (hop into `vim` to edit some config files while `ssh`ed into a box) it has the potential to help you out quite a bit.  One of the reasons people claim they couldn't live without IDEs is the existence of features such as Intellisense that provide autocompletion of variable/function names.  These features are very nice since they cut down on mistakes due to misspelling properties and thereby speed up the compile/run/debug cycle a fair bit.  Many people don't seem to realize that there is an analog which comes straight out of the box in `vim`, no plugins needed. 

You can press CTRL-N to move down the list of suggested completions when typing in INSERT mode (which vim draws from the current buffers, and from the `tags` file if you have one), or CTRL-P to move back up (representing "NEXT" and "PREVIOUS" if you didn't catch the pneumonic).  If there is only one possible completion, `vim` will just go ahead and insert it.  Very handy and speedy, especially in codebases with a lot of long variable / method / constant names.

CTRL-P/CTRL-N have a lot of synergy with the next tip as well, as touched upon briefly in the above paragraph.

{% img /images/five-tips/ctrl-n-vim.jpg And you barely need to leave the home row. %}

# ctags

Everyone who uses `vim` knows that it can be a bit of a kerfluffle sometimes to open a file in a distant directory (tab completion helps ease this with `:e`, but it's still not usually instantaneous).  If you happen to be working on a team, or a very large project, the ability to do this quickly will likely be a vital part of your workflow.

{% img /images/five-tips/c-tags.jpg Jump to the definition of this class, at lightning speed.  No mouse needed. %}

# CTRL-R in bash and zsh

{% img /images/five-tips/ctrl-r.jpg What was that IP address again? %}

`history | grep $COMMAND` will treat you well too, if you just want to review all of the times you've run that command in recent times.

# vim macros

A lot of the time when you're writing code, or doing related tasks, you find yourself in need of a way to repeat the same editor commands over and over, perhaps with a slight variation.  Different editors provide slightly different ways of addressing this.  [Sublime Text](), for example, has a "killer feature" where you are able to place multiple cursors in various locations and edit away.  In `vim` (and in `emacs` too, but here we'll be covering the `vim` method) you record and playback keyboard macros to accomplish this.  It is a tool with an absurd amount of power and flexibility, and offers the chance to speed up productivity on repetitive editing tasks by an order of magnitude.



{% img /images/five-tips/vim-macros.jpg Who needs multiple cursors? %}
