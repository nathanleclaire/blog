---
title: TCP Checks, Results, and Timing Out in Rust
layout: post
date: 2021-07-19T00:06:32.229Z
categories:
  - programming
---

For the [Ogmi project](https://twitter.com/ogmiapp), one area I've been working on is ingesting and processing historical financial data from [DTN IQFeed](https://www.iqfeed.net/). I've been using this as an opportunity to both learn Rust, and take advantage of its fast performance, as the code I was previously relying on in Python is often extremely slow, in some cases to the point of being practically unusable.

I'm bundling most of the production bits in Docker containers, of course, and leaning on [Hashicorp Nomad](https://www.nomadproject.io/) for orchestration, as I found Kubernetes a bit too heavyweight at the moment. I know all too well the care and feeding that goes into a proper Kubernetes deployment, and even with the availability of managed services, it was just a bit too much YAML wrangling for me. I much prefer the modularity of the Hashi stack, and the look and formattable nature of HCL.

One thing that Nomad offers is health checks that will reschedule the app if they are failed, and I wanted to put together such a check in Rust for the IQFeed gateway, which sometimes will decide to stop working due to the quirkiness of the way it's deployed. Here's what I've come up with on the Rust side. I'll probably talk about Nomad config in another post sometime.

## Timing Out

To my Rust CLI, I decided to add a simple `cmd check` subcommand that would try to talk to IQFeed, return 0 if everything looks healthy, and 2 otherwise. In Nomad, exit code 1 indicates a "warning" status for the health check, and any other non-zero exit value will indicate an unhealthy [alloc](https://www.nomadproject.io/docs/commands/alloc).

Rust has a few constructs you can leverage when it comes to concurrency and parallelism, 

Putting it all together, it looks like this:

```
fn check_iqfeed_health() -> i32 {
    let (sender, receiver) = mpsc::channel();
    let timeout_sender = sender.clone();
    let _main = thread::spawn(move || {
        let mut stream = match TcpStream::connect("127.0.0.1:9100") {
            Ok(s) => s,
            Err(e) => {
                sender.send(Err(e)).unwrap();
                return;
            }
        };
        match stream.write("S,SET PROTOCOL,5.1\r\nHTT,NONSENSE_SYMBOL,,,,,,1,\r\n\r\n".as_bytes()) {
            Ok(_) => {}
            Err(e) => {
                sender.send(Err(e)).unwrap();
                return;
            }
        };
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
            _ => {} // TODO: this probably needs handling
        }
        sender.send(Ok(())).unwrap();
    });
    let _timeout = thread::spawn(move || {
        thread::sleep(std::time::Duration::from_millis(5000));
        match timeout_sender.send(Err(std::io::Error::new(
            ErrorKind::TimedOut,
            "timeout trying to connect to IQFeed",
        ))) {
            Ok(()) => {}
            Err(_) => {}
        }
    });
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
}
```