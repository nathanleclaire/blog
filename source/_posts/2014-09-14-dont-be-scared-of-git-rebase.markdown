---
layout: post
title: "Don't Be Scared of git rebase"
date: 2014-09-14 14:38:31 +0000
comments: true
categories: [source,version,control]
---

{%img /images/rebase/golden_retriever.jpeg  %}

Developers like to pretend that we're analytical and make decisions based purely on logic but the truth is that, like most people, we're creatures of emotion and habit first and foremost. We get superstitious sometimes, and in the face of the brain-crushing complexity of modern computing, who wouldn't?  One fear I've noticed is of `git` (in general) and in particular of `git rebase`.  Indeed, previously I worked on a team where the mere mention of a rebase to the wrong team member could evoke howls of anxiety and protest.  Feel free to share your own rebase experiences in the comments.

Rebasing, like most of `git`, should be learned and applied to be useful - not feared or misunderstood - so if you've been bitten by rebase in the past, or are simply curious about how it can be used, hopefully I can persuade you here of its utility.

# What is it?

`git rebase` in its simplest form is a command which will merge another branch into the branch where you are currently working, and move all of the local commits that are ahead of the rebased branch to the top of the history on that branch.

From the main page: "git rebase: Forward-port local commits to the updated upstream head".

If you're still confused, let's look at an example.

Say I have been doing work on a feature branch and I want to merge in the changes my teammates have made on the `master` branch.  I've made 2 commits locally that aren't shared on the `origin` remote, and while I've been working on my feature branch my co-workers have made 20 commits on `origin/master` that I don't have on my branch (but I would like to).

My log looks something like this on the local branch.  My two recent (unshared) commits are at the top of the history, and the rest is the history of `master` when I originally checked out this branch.

<pre>
f48d47c Add Controller changes
fd4e046 Add DB migration
907e384 Most recent commit on master when I originally checked out feature branch
71fd630 ...
...
</pre>

So how should I approach getting the changes my co-workers have made on `master`?  I could `git fetch origin` and `git merge origin/master`, but that would cause two undesirable side effects:

1. It forces the creation of a merge commit.  This is useful information if there was a conflict, but otherwise it's just noise which pollutes the history.  Not good if you update your branch frequently (which you probably should).
2. It buries my commits under an avalanche of commits from other places, when really they should be at the top of the log due to the fact that they're "more recent to try and move upstream".  That is, it makes more sense for my buddy who is also working on this feature branch to see my commits first when he pulls in changes than it does for him to see the `master` changes.  The things that I've been working on in this branch are probably more relevant to him.

So what to do?  Well, as you may have predicted, `git rebase` comes to our rescue here.

`git rebase origin/master` will merge in the requested branch (`origin/master` in this case) and apply the commits that you have made locally to the top of the history without creating a merge commit (assuming there were no conflicts).  Now our history is nice and clean, and we have avoided the two issues listed above.

{%img /images/rebase/obama.jpeg %}

So why are people afraid?

# The fear

I am speculating based on anecdata here, but I suspect the general anxiety around rebasing stems from two primary places:

1. Due to the mechanics of `git rebase`, merge conflicts are more frequent and seemingly harder to deal with
2. Previous experiences with loss of work due to a botched interactive rebase and/or force push (more on this is a second).

The merge conflicts one makes sense, since few things enrage programmers quite like a well-timed merge conflict, but you shouldn't let that keep you from rebasing.  Two reasons for this are:

1. If you frequently commit your ongoing work (which you should) and rebase, the probability of having unmanageable merge conflicts goes way down.
2. If you run into conflicts while rebasing, fix them, and `git rebase --continue`, the rebase will continue to go off without a hitch (there will be a merge commit, but once again it will contain useful information about where the conflict was and how it was resolved).
3. If the conflicts are too bad and you need to bail out and attempt a normal fast-forward merge, you can easily do so with `git rebase --abort` (leaving you where you were before attempting the rebase).

So, always try rebase first, and your git history will thank you (and take note, there is `git pull --rebase` as well- I won't go into the whole fetch/merge vs. pull flamewar here).

# Not to mention that interactive rebase is _fantastically_ useful.

Another reason that the rebase fear is unwarranted is that `git rebase` has an interactive mode which is absurdly powerful and useful.  Let's take a look at some examples where this might come in handy:

- Quickly removing a commit which snuck into a different branch
- Squashing several commits into one
- Rapidly changing the message on a series of commits

## Quickly removing a commit which snuck into a different branch

If you've ever been working rapidly and concurrently on a few different branches, you may well be familiar with this problem.  It looks like this:

1. I commit some stuff on one branch, the correct place for it, then have to move over to another branch to do some different work there.  You quickly commit some changes e.g. a panic-mode bug fix.
2. Oh, crap.  I forgot to switch to `master` or the appropriate parent branch before checking out the new branch for the hotfix, and now I have the commits from the branch I was working on before, when really I wanted a "clean slate" from `master`.  
3. These other commits don't belong on this branch.  What to do?

Now, obviously it'd be easiest to just not make mistakes in the first place, but I'm willing to bet that this sort of thing happens to people more likely than most of us would like to admit.  So, we need a way to quickly deal with situations like this when they happen.

What to do?  You can't just `git reset --hard` without losing your desired commit, and the `git reset --soft` song and dance is annoying.  Fortunately, you can just do something like `git rebase -i HEAD~2` to quickly drop the commits from your new branch.  Just delete the lines for the commit(s) in the interactive rebase prompt.

{%img /images/rebase/rebaserm.gif %}

Obviously care should be taken that you don't remove anything that's not on other branches (thereby destroying work), but this is a nice swift way to correct the classic "these-commits-shouldn't-be-on-this-branch" mistake.

## Squashing several commits into one

Sometimes, in order to save your progress as you go, you may find yourself committing disparate pieces which may be better served or represented as only one commit.  For instance, your team might have a policy that all commits to a class must also have accompanying changes to unit tests in the same commit, but you like to check in your work as you go.

`git rebase -i` makes combining these several commits into one a piece of cake.  Just run `git rebase -i HEAD~n`, where `n` is the number of commits you need access to, and change "pick" on those commits' lines to "squash".  Commits with "squash" on consecutive lines will be combined into one!

{%img /images/rebase/rebasesquash.gif %}

Once again, rebasing helps us keep our history tight and readable.

### Rapidly changing the message on a series of commits

Some open source projects, such as [docker](https://github.com/docker/docker), require contributors to sign their work using `git commit -s` (or a custom message) as proof of ownership.  Changes won't be merged upstream unless they are signed off correctly in this manner.

So if you submit a pull request with four or five commits without know to do this, are you hosed?  Will you have to do the `git reset --soft` song and dance and try again on a new branch?

Hell no!  You can use `git rebase -i` to rapidly sign all of your commits the correct way.  Just change `pick` to `edit` for the commits in question, and do a `git commit --amend -s` (no need to change the original message!) and `git rebase --continue` for each commit.  If I recall correctly, you can also do `reword` if you set up signing the commits automatically as a hook in your repo (this has the additional bonus of keeping you from forgetting in the future too).

Now you can force push (`git push -f`) to the branch on the remote you're making the PR from and the commits will be signed correctly.

If you're sitting there cringing because you feel force pushing is dirty, I agree.  It _is_ dirty.  That's why it's so awesome.

A word on that, actually...

# A word on re-writing history

Re-writing history with `git rebase`, as you have seen, is fun _and_ useful, but once history hits remotes that other people are using it should be considered canon and it should almost never be changed.  So, if you rebase, make sure not to muck with _other people's_ history and commits on accident.  Likewise, if you force push, NEVER EVER force push to a remote where other people are working unless: 

- You are 100% sure you know what you are doing.
- You get explicit consent to do so from everyone working on that remote.

Being loose and careless about this will get you a _very_ bad reputation, and if you do it the consequences could range from getting kicked off the team to getting fired to getting hellbanned from touching a computer for the rest of your life.

# But don't fear the rebase

As long as you're cautious, `git rebase` will be a blast.  Learn it, love it, and grow old with it (until something better comes along!).  As you've seen, uses for rebase run the gamut from "keep the history clean" to "holy crap that solves problems in a different way than I would have thought of before".

For reference or more reading, check out this section of the Git book: [http://git-scm.com/book/ch3-6.html](http://git-scm.com/book/ch3-6.html)

Until next time, stay sassy Internet.
