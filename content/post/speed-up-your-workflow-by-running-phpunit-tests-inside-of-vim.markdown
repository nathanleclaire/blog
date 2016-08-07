---
layout: post
title: "Speed Up Your Workflow By Running PHPUnit Tests Inside of Vim"
date: "2014-01-20"
comments: true
categories: [php,vim,bash,phpunit,unit testing,vimscript]
---

{{%img src="/images/vim-phpunit/phpunitdemo.gif" caption="No more CTRL Z for me. " %}}

If you're a dev that cares about nice, clean, working code you should probably be writing unit tests.  I've discussed unit testing in [AngularJS](http://angularjs.org) a bit in [one of my previous posts](https://nathanleclaire.com/blog/2013/12/13/how-to-unit-test-controllers-in-angularjs-without-setting-your-hair-on-fire/), but what if you are working on the server side with one of the [most wildly popular web application languages of all time](http://langpop.com/)?  That's right folks, I'm talking about [PHP](http://php.net/) and whether you love it or hate it if you are working with it there's a damn good chance that you are unit testing it with the venerable [PHPUnit](http://phpunit.de/) (if you're not unit testing at all, you're on the naughty list).  At the time of writing, this is what I do at my day job (my night job is as a costumed crusader fighting crime in the mean streets of [Ann Arbor, Michigan](http://www.a2gov.org/Pages/default.aspx).  For a long time the unit testing part of my development workflow in PHP went something like this:

1.  Be editing a PHP file and the file that tests it inside of `vim` over `ssh`
2.  Change something in the test or the class that is likely to break the test, or add new tests
3.  Pop out of `vim` using `CTRL+Z` to suspend the process, and run the test on the command line using `phpunit --colors FileTest.php`
4.  Note the results of the test.
5.  Type `fg` to get back into `vim`
6.  Change the files to correspond *OR* Wait, what was the thing that was off again?
7.  `GOTO 1`

Needless to say it's a little exhausting, especially on those days where your brain's moving slower than your fingers and you just can't seem to inject enough coffee into your system.  But if your workflow is like this, you might be excited to find out that there is a better way.

# Let's Write Some VimScript

> And when you gaze long into an abyss the abyss also gazes into you. 
>
> - [Friedrich Nietzsche](http://en.wikiquote.org/wiki/Friedrich_Nietzsche)

If you're a `vim` poweruser, or even just a regular user, your first impulse towards solving this problem might be to execute commands using `:!phpunit @%`.  In case you're not familiar with this syntax, you just learned that you can preface commands with `!` (bang) to run them in the shell and that `@%` refers to the file opened in the current buffer.  This could work pretty well (and does) in a lot of cases, however it has a few disadvantages:  

- You have to type out the whole sequence every time, which is really annoying even if you are a fast typer and it adds a second or two onto your "writecode-runtest-repeat" cycle each time that really begins to add up quickly
- You can't see the results inside a `vim` buffer and manipulate them side-by-side with the test and code under test.  You could theoretically use `screen` for this, but I've always run into issues getting `screen` to work perfectly with my `vim` setup
- In my use case (not sure if this is universal), PHPUnit is finnicky about *where* you run the tests from, and for a variety of reasons I don't like to `:cd` away from the home directory of the project I'm working on very often (not to mention that's an extra step in the cycle).  `:set autochdir` would fix this, but for large projects I'm not often a fan of `autochdir`.

You could also try to look for a plugin, but who wants yet *another* `vim` plugin / coloring theme / whatever to juggle?

So what's a unit testing junkie to do?  We have to dig into VimScript to automate this.  Hoo boy.  But have no fear, thanks to [Steve Losh](http://stevelosh.com/)'s [Learn VimScript the Hard Way](http://learnvimscriptthehardway.stevelosh.com/) I've figured out a great solution for you.

Put this code inside of your `.vimrc` file:

```
function! RunPHPUnitTest()
    cd %:p:h
    let result = system("phpunit " . bufname("%"))
    split __PHPUnit_Result__
    normal! ggdG
    setlocal buftype=nofile
    call append(0, split(result, '\v\n'))
    cd -
endfunction

nnoremap <leader>u :call RunPHPUnitTest()<cr>
```

This will remap the keyboard shortcut `<leader>u` (run in normal mode) to run `phpunit` on the file you're currently editing (hopefully a test, or else there will be no result) in the directory where it is based, and spit out the results into a new window.  In case you're unfamiliar, the `<leader>` key in `vim` is `'\'` by default, but frequently it gets remapped to other keys (mine is mapped to `','`). 

I really like this shortcut since it allows me to look at the test results side by side with the files I'm working on.  This code generates a new test result window each time you run it, so you have to `:q` out of old ones manually.  This has never bothered me *too* much, but if you know of a way to change it so that it kills old windows automatically I'd love to hear from you.

If you have a file with a lot of test methods in it, `vim` will be somewhat awkardly locked up for a minute waiting for the results, which it will spit out all at once when it is finished instead of in real-time like when you run `phpunit` on the command line, but at this time `vim` does not support streaming input buffers as far as I am aware.  So it's something that has to be lived with if you want to use the functionality this way.  If you know of a workaround for this, you should [let me know](mailto:nathanleclaire@gmail.com).  Or, you can use the next tip to execute just a few tests at a time.

# But Can We Do Better?

Sure, we can always do better.  I really like using phpunit with the `--filter` option, since it allows you to focus on only running the tests you are interested in, instead of the whole kit and kaboodle.  This speeds things up really significantly.  How can we include this in our little VimScript function?

We'll pass a parameter to our `RunPHPUnitTest()` function to indicate whether we want to do a `--filter` run or not, and if so we will yank the current word to use as the argument for the `--filter` parameter.  So, in our use case, if our vim cursor is hovering over the name of the function we want to run in the test file (as in `function testWhatever()`), and we press `<leader>f`, it will run PHPUnit just for that test.  Revised, the code in our `.vimrc` file looks like this:

```
function! RunPHPUnitTest(filter)
    cd %:p:h
    if a:filter
        normal! T yw
        let result = system("phpunit --filter " . @" . " " . bufname("%"))
    else
        let result = system("phpunit " . bufname("%"))
    endif
    split __PHPUnit_Result__
    normal! ggdG
    setlocal buftype=nofile
    call append(0, split(result, '\v\n'))
    cd -
endfunction

nnoremap <leader>u :call RunPHPUnitTest(0)<cr>
nnoremap <leader>f :call RunPHPUnitTest(1)<cr>
```

In action:

{{%img src="/images/vim-phpunit/phpunitdemofilter.gif" caption="So much faster, especially in big files. " %}}

# Conclusion

I'd rather script my editor in Python.  JUST KIDDING.  Kind of.

Until next week, stay sassy Internet.  And keep that code coverage strong.

Cheers,

- Nathan
