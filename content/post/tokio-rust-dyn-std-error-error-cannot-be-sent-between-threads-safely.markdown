---
title: Tokio/Rust dyn std::error::Error cannot be sent between threads safely
layout: post
date: 2021-11-06T21:25:29.644Z
categories:
  - programming
---
![crabs demonstrating multithreading](/images/crab_threads.png)

And for good measure, we'll also talk about error `borrowed value does not live long enough`, `argument requires that var is borrowed for 'static`, `dropped here while still borrowed`...

## Boxes, Syncs, and Sends

I just ran into an issue with rust code (tokio) where I was trying quite unsuccessfully to port some previously synchronous code to use tokio and async. My code looked like this, as I was working with a function `ticks::iqfeed_ticks` which previously was taking in some parameters and returning `Result<(), Box<dyn Error>>`:

```
let mut join_handles = vec![];
for line in lines {
    join_handles.push(tokio::spawn(async move {
        ticks::iqfeed_ticks(&line.unwrap(), &output_dir.to_owned(), no_mkt_hours)
    }));
}
let results = futures::future::join_all(join_handles).await;
```

Straightforward enough right? Quite similar to tokio examples out there, and I had figured out that `join_all` could be used to wait for all of the generated handles based on the futures added to the Tokio runtime.

Problem was I kept getting smacked in the face with this error message because the function's signature was `Result<(), Box<dyn Error>>` which felt pretty consistent with example code for Rust I'd seen on the web, sensible enough, and also worked nicely with `?`s peppered all throughout it.

```
dyn std::error::Error cannot be sent between threads safely

help: the trait std::marker::Send is not implemented for dyn std::error::Error
```

I guess I would have saved myself a lot of trouble reading more about that second line there, but I went on a wild goose chase because the first thing I tried, adding a `+ Send` to the inside of the function signature, so that it returned `Result<(), Box<dyn Error + Send>>` so that the error would have the `Send` method desired by the compiler to safely send across threads, did not work.

I realized finally that I also needed to add the `Sync` trait too. Thereby ending up with a function signature looking like:

```
pub fn iqfeed_ticks(symbol: &str, out_dir: &str, no_mkt_hours: bool) -> Result<(), Box<dyn Error + Send + Sync>> {
    // .. stuff
}
```

That made the compiler happy, sort of. It then started complaining that all the other `Box<dyn Error>` I was unwrapping and returning with `?` operator, could not be `From`ed into the newly returned `Box<dyn Error + Send + Sync>`. So, I had to go through all the calls in the chain and update those signatures as well. Then, things were really looking up as I had tackled this issue with the return type, allowing me to achieve my goal of communicating errors back to the main thread from all the downstream threads somehow.

But a few more issues were still lurking.

## Borrowing, Outliving, and Life as a Rust alloc

Like I mentioned above the newly multithreaded calls passed some parameters to the function. One value was unique to each invocation (the first, `line`), and the others were propagated through from command line flags.

```
ticks::iqfeed_ticks(&line.unwrap(), &output_dir.to_owned(), no_mkt_hours)
```

As a Golang YOLO heathen I was accustomed to not thinking too much about where I was handing off memory and its lifetime, etc. Prior to multithreading it was fine, but once I moved to async, the compiler suddenly didn't like that very much, throwing off an error about a (seemingly unrelated, but ultimately very related) variable.

![dropped here while borrowed compiler error](/images/subcmdrust.png)

Well, of course I suspect the shared value passed to every method, but it was torturous to figure out what I was doing wrong. Ultimately, it turns out that I wanted to clone or copy instead of borrowing. I had been too liberal in my application of the `&` operator when I shouldn't have been.

Specifically, the issue in my case was around the `out_dir` that the method was borrowing. While `matches` seemed tangential to `out_dir`, because `out_dir` came from a sequence like this, it was a reference, not an owned variable:

```
let subcmd_matches = matches.subcommand_matches("ticks").unwrap();

let output_dir = subcmd_matches.value_of("output_dir").unwrap();
```

`subcommand_matches` returned an `Option<&ArgMatches>`, so after unwrapping, you are left with a reference. Meanwhile when you call `value_of` to get the value of a flag, you get back an `Option<&str>`, so yet another reference after unwrapping.

Well, when it comes to sharing that across threads, it's NO GOOD as far as the Rust compiler is concerned. The compiler can't guarantee that you're going to wait for the results of the thread before exiting the scope, hence the complaining message about the borrowed value not living long enough. Sweet, it's protecting us from a bunch of bugs and footguns that are way too easy to code up in other languages.

OK, so we know it's complaining because we're reusing the same borrowed value across multiple threads, so what's the solution? **Ownership**. Instead of borrowing the value directly, we can redefine an owned version unique to each thread that will be captured when we `move` the `async` future. (I think I got all that correct, if any Rustaceans out there have some clarifying feedback, I welcome it!)

So what do we do? When we loop over, we want to get an owned version of the string with `to_owned`. Surprisingly straightforward solution, but I was really having a hard time wrapping my head around the various layers, the difference between `&str`, `str`, `String`, and so on. Now everything is happy because `line` is unique to each iteration (hence the borrow is OK), `out` is owned, and`no_mkt_hours` is `Copy`-ed because it's a `bool`, not a `&bool`.

```
for line in lines {
    let out = output_dir.to_owned();
    handles.push(tokio::spawn(async move {
        ticks::iqfeed_ticks(&line.unwrap(), &out, no_mkt_hours)
    }));
}
```

After that, waiting for all the threads is EZ PZ. Just `await` the `futures::future::join_all` call on all the returned `JoinHandle`s each `spawn` call generates.

## Wrap Up

Anyway, I hope this helps someone out there navigate the often confusing land of Rust sharing, borrowing, and traits... I am very pleased that Rust is cleaning up a whole class of possible bugs but it certainly is a lot more restrictive than other languages.

Again, I'm super green on all this -- if any Rust gurus out there have feedback, please pass it along!

Now, onward to killer performance. Until next time, stay sassy Internet.

* Nate
