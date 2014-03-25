---
layout: post
title: "Fixing Cygwin's SSL issues with git clone / c_rehash bug"
date: 2014-3-24 19:44
comments: true
categories: [unix,cygwin,windows,git,dear god why]
---

# Cygwin's git clone drama

{%img /images/cygwin-ssl/cygwin.jpg %}

## Oh, you.

When I am working on Windows for the various reasons which compel one to work on Windows I often use [Cygwin](http://www.cygwin.com) to provide UNIX-like functionality on the command line (cmd.exe leaves a lot to be desired).  Since a vital part of my workflow on any OS is [git](http://git-scm.com) I happily installed git using the Install.exe workflow that Cygwin provides.

To my surprise (and, I'm not going to deny it, slight nerd-rage) when I attempted to `git clone` a repository from Github I was greeted by an error message like this one:

```
$ git clone https://github.com/foo/bar
error: SSL certificate problem, verify that the CA cert is OK. Details:
error:14090086:SSL routines:SSL3_GET_SERVER_CERTIFICATE:certificate verify failed
```

OK, so I have an SSL issue.  Running through the Setup.exe with Cygwin again and installing `ca-certificates` and `openssl` didn't fix it, and eventually I came across [this Stack Overflow post](http://stackoverflow.com/questions/3777075/ssl-certificate-rejected-trying-to-access-github-over-https-behind-firewall) which described my exact issue.

# On the hunt for solutions

## One proposed solution

```
$ git config --global http.sslVerify false
```

SERIOUSLY!?!?

No way I'm going to turn off SSL just to try and workaround this issue.  I don't like getting MITMed.

## A much better proposed solution

Also from Stack Overflow:

```
$ cd /usr/ssl/certs
$  curl http://curl.haxx.se/ca/cacert.pem | awk 'split_after==1{n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1} {print > "cert" n ".pem"}'
$ c_rehash
```

OK, this is headed in the right direction, I can tell.  I had to manually create the `/usr/ssl/certs` directory (probably because I hadn't installed OpenSSL yet when I tried this), but even after getting OpenSSL `c_rehash` was giving me an error:

```
$ c_rehash
c_rehash: rehashing skipped ('openssl' program not available)
```

Pretty odd, since just typing `openssl` on the CLI clearly indicated that it was present.

## Debuggin' some Perl code

Nothing too fruitful was turning up on Google for this (the [original program source](http://koti.kapsi.fi/ptk/postfix/c_rehash.txt) was, though :P) so I dug into the program source (Perl) and found this bit at the top:

```
my $openssl;

my $dir = "/usr/lib/ssl";

if(defined $ENV{OPENSSL}) {
	$openssl = $ENV{OPENSSL};
} else {
	$openssl = "openssl";
	$ENV{OPENSSL} = $openssl;
}

$ENV{PATH} .= ":$dir/bin";

if(! -x $openssl) {
	my $found = 0;
	foreach (split /:/, $ENV{PATH}) {
		if(-x "$_/$openssl") {
			$found = 1;
			last;
		}	
	}
	if($found == 0) {
		print STDERR "c_rehash: rehashing skipped ('openssl' program not available)\n";
		exit 0;
	}
}
```

Sprinkling some liberal debugging statements into that yielded me the information that `c_rehash` was finding the relevant directories (and consequently the `openssl` binary) but the file wasn't showing up as executable.  Some Googling turned up stuff like [this](http://cygwin.com/ml/cygwin/2007-05/msg00681.html), which made me wonder...

## If *this* solution would work

```
$ which openssl
/cygdrive/c/Program Files (x86)/Git/bin/openssl
$ chmod +x /cygdrive/c/Program\ Files\ \(x86\)/Git/bin/openssl
```

It did!  You have to run Cygwin as administrator to have the proper permissions though to change those file permissions though.

`c_rehash` then went through without a hitch, Which finally allowed `git clone` to work.

# Conclusion

Whew!  That was exhausting.  Time to do some programming to unwind :)

Until next time, stay sassy Internet.

- Nathan
