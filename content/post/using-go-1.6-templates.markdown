---
layout: post
title: "Using Golang 1.6 Templates"
date: "2016-02-23"
comments: true
categories: [golang,go,template]
---

{{%img src="/images/gotemplate.png" caption="Coming soon to a workstation near you." %}}

Very recently [Golang 1.6](https://tip.golang.org/doc/go1.6) was announced.
There is a tweak to the templating engine that I'm pretty happy about and I
think you should be too.  Here's why.

## whitespace

Our old friend whitespace rears its ugly head when we go to work with Golang
templates.  "Back in the day" when I was developing an application for the web
we would use the [Smarty](http://www.smarty.net/crash_course) templating Engine
to spit out HTML.  It was glorious -- because of the way that browser rendering
works, you didn't need to concern yourself with extraneous whitespace, and so
you could layout your rendering of back-end data with quite a bit of flourish,
like this:

```
<table>
{foreach $names as $name}
{strip}
   <tr bgcolor="{cycle values="#eeeeee,#dddddd"}">
      <td>{$name}</td>
   </tr>
{/strip}
{/foreach}
</table>
```

Unfortunately, lots of other environments _do_ care about whitespace, including
your friendly neighborhood shell.  Therefore, it's useful to have more fine
grained control over how whitespace is rendered in templates.

## example

Let's say we wanted to render a command to start the Docker daemon with certain
parameters using Go templating, our first attempt might look something like
this:

```
package main

import (
	"log"
	"os"

	"text/template"
)

type EngineOptions struct {
	StorageDriver        string
	ClusterStore, Labels []string
}

func main() {
	engineOpts := &EngineOptions{
		StorageDriver: "overlay",
		ClusterStore: []string{
			"zk://10.0.0.2:2181",
			"eth0:2376",
		},
		Labels: []string{
			"storage=ssd",
			"distro=debian",
			"region=us-west-1",
			"instance-type=m1.medium",
		},
	}

	// Bad code: Doesn't give us what we actually want.
	tmpl, err := template.New("test").Parse(`docker daemon \
--debug \
{{ range .ClusterStore }}
--cluster-store {{.}} \
{{ end }}
{{ range .Labels }}
--label {{.}} \
{{ end }}
--storage-driver {{.StorageDriver}}
`)
	if err != nil {
		log.Fatal(err)
	}

	if err = tmpl.Execute(os.Stdout, engineOpts); err != nil {
		log.Fatal(err)
	}
}
```

But unfortunately, running this code will give us a lot of extra whitespace,
that a shell actually _would_ be sensitive to:

<pre>
$ go run /tmp/template.go
docker daemon \
--debug \
--label instance-type=m1.medium \

--cluster-store zk://10.0.0.2:2181 \

--cluster-store eth0:2376 \


--label storage=ssd \

--label distro=debian \

--label region=us-west-1 \
--storage-driver overlay
</pre>

Prior to Go 1.6, one would have to re-write the template to actually carefully
manage the whitespace, but in 1.6:

> it is now possible to trim spaces around template actions, which can make
> template definitions more readable. A minus sign at the beginning of an
> action says to trim space before the action, and a minus sign at the end of
> an action says to trim space after the action.

So, we could re-write our above template like so:

```
	tmpl, err := template.New("test").Parse(`docker daemon \
--debug \
{{- range .ClusterStore }}
--cluster-store {{.}} \
{{- end }}
{{- range .Labels }}
--label {{.}} \
{{- end }}
--storage-driver {{.StorageDriver}}
`)
```

(from [https://tip.golang.org/doc/go1.6](https://tip.golang.org/doc/go1.6))

This gives us a rendering which is much more airtight:

<pre>
$ go run /tmp/template.go
docker daemon \
--debug \
--cluster-store zk://10.0.0.2:2181 \
--cluster-store eth0:2376 \
--label storage=ssd \
--label distro=debian \
--label region=us-west-1 \
--label instance-type=m1.medium \
--storage-driver overlay
</pre>

## fin

Go 1.6 authors == <3

Until next time, stay sassy Internet.

- Nate
