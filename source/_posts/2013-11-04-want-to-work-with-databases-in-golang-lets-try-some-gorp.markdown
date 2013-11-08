---
layout: post
title: "Want to work with databases in Golang?  Let's try some gorp."
date: 2013-11-04 18:58
comments: true
categories: 
---

# Google's Go

[Go](http://golang.org/) is a new programming language released by [Google](http://www.google.com).  It has an excellent pedigree (see [Rob Pike]() and [Ken Thompson]()) and it brings a lot of interesting things to the table as a programming tool. Go has been the subject of rave reviews as well as controversy.  As Google is a web company it's no surprise that Go seems hard-wired from the start to be used in the context of the modern web and the standard libaries include everything from [HTTP servers]() to [a templating system]() to address these ends.  A lot of companies and hobbyist hackers seem to enjoy Go as a utility language that replaces components which used to be written in Python or Perl (with Go offering better performance).  


Its supporters emphasize its [performance](), nifty approach to concurrency (it's [built right in]()), and fast compile times as advantages.  Some of its detractors dislike its lack of exceptions and generics, but the purpose of this article is not to address these concerns, which have already been discussed *ad nauseum*.  Instead, this article will talk about and examine the `gorp` library.  

{% img /gorp/gorp.jpg Eh? %}

I don't mean GOOD OLD RAISINS & PEANUTS, of course- I mean [gorp](), an "ORM-ish library for Go".  What is it, and how does it work its funny magic?

# ORM-ish?

The README.md from `gorp`'s repository is just too great an introduction to not quote, check it out:

<blockquote>
I hesitate to call `gorp` an ORM. Go doesn't really have objects, at least not in the classic Smalltalk/Java sense. There goes the "O". gorp doesn't know anything about the relationships between your structs (at least not yet). So the "R" is questionable too (but I use it in the name because, well, it seemed more clever).

The "M" is alive and well. Given some Go structs and a database, gorp should remove a fair amount of boilerplate busy-work from your code.

I hope that `gorp` saves you time, minimizes the drudgery of getting data in and out of your database, and helps your code focus on algorithms, not infrastructure.
</blockquote>

When I was looking into [revel](http://www.github.com/robfig/revel) as a possibility for a Go web framework, I found myself frustrated by the lack of a database solution.  Persistence is just such a key aspect of web applications, it was hard to believe that such a large framework didn't even want to touch the problem (especially since [Play](http://www.playframework.com/documentation/1.2.1/model), a large source of inspiration for revel, provided such functionality).  Revel is awesome in a lot of other ways (like hotswapping), but for now at least it is "bring-your-own-ORM" (or other database solution).

So I set off to look into this funny `gorp` business.  As it turns out, `gorp` is pretty straightforward, and powerful.

Out of the box gorp sets the columns to have a decent bit of buffer, so it's worth noting that you can set the field length manually (though this feature doesn't seem particularly well documented):

# Read the source, Luke

Obviously gorp is really cool, and useful.  So how does it work?

I remembered the words of Jeff Atwood and 

```go
// AddTableWithName has the same behavior as AddTable, but sets
// table.TableName to name.
func (m *DbMap) AddTableWithName(i interface{}, name string) *TableMap {
        t := reflect.TypeOf(i)
        if name == "" {
                name = t.Name()
        }

        // check if we have a table for this type already
        // if so, update the name and return the existing pointer
        for i := range m.tables {
                table := m.tables[i]
                if table.gotype == t {
                        table.TableName = name
                        return table
                }
        }

        tmap := &TableMap{gotype: t, TableName: name, dbmap: m}
        tmap.columns, tmap.version = readStructColumns(t)
        m.tables = append(m.tables, tmap)

        return tmap
}
```

# The future

One thing that I have been thinking would be cool is if `gorp` could handle relational data, perhaps by using pointers to some kind of foreign key wrapper structure?


