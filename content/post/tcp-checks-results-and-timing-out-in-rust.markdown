---
title: TCP Checks, Results, and Timing Out in Rust
layout: post
date: 2021-07-19T00:06:32.229Z
categories:
  - programming
  - rust
  - concurrency
  - iqfeed
---

For the [Ogmi project](https://twitter.com/ogmiapp), one area I've been working on is ingesting and processing historical financial data from [DTN IQFeed](https://www.iqfeed.net/). I've been using this as an opportunity to both learn Rust, and take advantage of its fast performance, as the code I was previously relying on in Python is often extremely slow, in some cases to the point of being practically unusable.

I'm bundling most of the production bits in Docker containers, of course, and leaning on [Hashicorp Nomad](https://www.nomadproject.io/) for orchestration, as I found Kubernetes a bit too heavyweight at the moment. I know all too well the care and feeding that goes into a proper Kubernetes deployment, and even with the availability of managed services, it was just a bit too much YAML wrangling for me. I much prefer the modularity of the Hashi stack, and the look and formattable nature of HCL.

One thing that Nomad offers is health checks that will reschedule the app if they are failed, and I wanted to put together such a check in Rust for the IQFeed gateway, which sometimes will decide to stop working due to the quirkiness of the way it's deployed. Here's what I've come up with on the Rust side. I'll probably talk about Nomad config in another post sometime.

## Multi-threading in Rust for Health Checks

To my Rust CLI, I decided to add a simple `cmd check` subcommand that would try to talk to IQFeed, return 0 if everything looks healthy, and 2 otherwise. In Nomad, exit code 1 indicates a "warning" status for the health check, and any other non-zero exit value will indicate an unhealthy [alloc](https://www.nomadproject.io/docs/commands/alloc).

As per usual, there are a few states I wanted to make sure to cover. For instance, what if something is up on the IQFeed port but it's not the correct API? This actually happened on my desktop when installing some new Logitech software. What if something is up, but for one reason or another, the port just hangs and never writes back the client? A timeout would be an essential ingredient, so I had to learn how to handle timeouts in Rust.

Rust has a few constructs you can leverage when it comes to concurrency and parallelism, and one of the most natural feeling for a Go programmer such as myself is message passing. Lucky for me, for the question of timing out on some operation, [Stack Overflow](https://stackoverflow.com/questions/36181719/what-is-the-correct-way-in-rust-to-create-a-timeout-for-a-thread-or-a-function) came to the rescue and I had a good jumping off point.

For starters, we want to create a channel, which will have a `Sender<T>` and `Receiver<T>` on either side. In our case, we'll pass a `Result<Error>` around on this channel. We'll generate two threads, one for the timeout, and one for the attempted health check, and send a message to indicate whether there was a success, a failure, or a timeout.

### Message Passing

For our function, we'll return `i32` for easy passing to `std::process::exit`.

```
fn check_iqfeed_health() -> i32 {
```

Rust is picky about how memory is borrowed and shared, so when we create our sender, we have to also clone it to get a new version for the timeout thread.

```
let (sender, receiver) = mpsc::channel();
let timeout_sender = sender.clone();
```

### A thread for TCP streaming

After that, we'll spawn our first thread where the actual check happens. A closure will define what happens in that thread.

```
let _main = thread::spawn(move || {
    // ... work ... 
});
```

Inside that closure, we take care of a few business items. First, let's try to contact the listener on the IQFeed port.

```
let mut stream = match TcpStream::connect("127.0.0.1:9100") {
    Ok(s) => s,
    Err(e) => {
        sender.send(Err(e)).unwrap();
        return;
    }
};
```

Using `match`, we're returning a `TcpStream` if we successfully make the dial, and sending an error across the channel and exiting otherwise. Given that that went well, next let's make a request for historical tick data. We happen to know that this will give back an error, but it's not the kind we're concerned about -- if we get an IQFeed response at all (which will tell us there is an error, "no data" for the `NONSENSE_SYMBOL`), that's success. Otherwise, we'll send a resulting error over our friendly neighborhood channel again.

I'm just using `unwrap` on the `Result` from the `send` call because, if that doesn't work, I'm not sure what else to do but panic :)

```
match stream.write("S,SET PROTOCOL,5.1\r\nHTT,NONSENSE_SYMBOL,,,,,,1,\r\n\r\n".as_bytes()) {
    Ok(_) => {}
    Err(e) => {
        sender.send(Err(e)).unwrap();
        return;
    }
};
```

Now, let's check that we got back what we expected. With `BufReader`, we can scan over the lines returned from the stream. Things should match what we expect, and generate no errors, or else, you guessed it -- we send an error over the channel. `std::io::Error` has some useful `ErrorKind`s we can lean on, so we use that, it seems to fit well.

```
let mut lines = BufReader::new(stream).lines();

// should get back a response
// S,CURRENT PROTOCOL,5.1
match lines.next() {
    Some(line) => match line {
        Ok(line) => {
            info!("Got a response: {:?}", line);
            if line != "S,CURRENT PROTOCOL,5.1" {
                sender
                    .send(Err(std::io::Error::new(
                        ErrorKind::InvalidData,
                        "Got a different response than expected",
                    )))
                    .unwrap();
                return;
            }
        }
        Err(e) => {
            sender.send(Err(e)).unwrap();
            return;
        }
    },
    _ => {} // this is an exercise for the reader, not just because I'm lazy
}
```

Lots of flinging `Result` and `Option` around, and you can see how those start to come together in a more Lego-bricky way as programs evolve. Last but not least, if we made it this far, we're all clear, so let's send a success message to our buddy, the main thread.

```
sender.send(Ok(())).unwrap();
```

### A thread for timing out

Now, our timeout thread, will be simpler, since all it needs to do, is sleep for five seconds, and then sound the alarm if the other thread is choking for some reason.

```
let _timeout = thread::spawn(move || {
    thread::sleep(std::time::Duration::from_millis(5000));
    match timeout_sender.send(Err(std::io::Error::new(
        ErrorKind::TimedOut,
        "timeout trying to connect to IQFeed",
    ))) {
        Ok(()) => {} // this is another way of handling
        Err(_) => {} // besides using unwrap()
    }
});
```

### Returning a result

Last but not least, we go back to our friend the main thread, which is waiting to hear back, and returns 0 if everything looked good, but 2 otherwise.

```
return match receiver.recv() {
    Ok(msg) => match msg {
        Ok(_) => 0,
        Err(e) => {
            error!("{:?}", e);
            2 // nomad failed check
        }
    },
    Err(e) => {
        error!("{:?}", e);
        2
    }
};
```

This will signal to Nomad that it should go beep the boops to redo the alloc. In a time honored operations tradition, if our API gateway gives out, we turn it off, and turn it back on again.

## Result

I still need to keep banging on this in production to make sure it's viable, but I thought it was a fun little chunk of code to share.

Until next time, stay sassy Internet.

- Nathan