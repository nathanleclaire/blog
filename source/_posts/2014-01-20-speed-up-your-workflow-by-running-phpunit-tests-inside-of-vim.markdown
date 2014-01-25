---
layout: post
title: "Speed Up Your Workflow By Running PHPUnit Tests Inside of Vim"
date: 2014-01-20 23:30
comments: true
categories: [php,vim,bash,phpunit,unit testing,vimscript]
---

{%img images/vim-phpunit/demo.gif No more CTRL Z for me. %}

If you're a dev that cares about nice, clean, working code you should probably be writing unit tests.  I've discussed unit testing in [AngularJS]() a bit in [one of my previous posts](), but what if you are working on the server side with one of the [most wildly popular web application languages of all time]()?  That's right folks, I'm talking about [PHP]() and whether you love it or hate it if you are working with it there's a damn good chance that you are unit testing it with PHPUnit (if you're not unit testing at all, you're on the naughty list).  At the time of writing, this is what I do at my day job (my night job is as a costumed crusader fighting crime in the mean streets of [Ann Arbor, Michigan]().  For a long time my application development workflow went something like this:

1.  Be editing a PHP file and the file that tests it inside of `vim` over `ssh`
2.  Change something in the test or the class that is likely to break the test, or add new tests
3.  Pop out of `vim` using `CTRL+Z` to suspend the process, and run the test on the command line using `phpunit --colors FileTest.php`
4.  Note the results of the test.
5.  Type `fg` to get back into `vim`
6.  Change the files to correspond *OR* Wait, what was the thing that was off again?
7.  `GOTO 1`

Needless to say it's a little exhausting, especially on those days where your brain's moving slower than your fingers and you just can't seem to inject enough coffee into your system.  But if your workflow is like this, or you find yourself `ALT`-`TAB`ing between NetBeans etc. 
