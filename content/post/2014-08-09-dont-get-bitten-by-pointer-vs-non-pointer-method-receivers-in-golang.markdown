---
layout: post
title: "Don't Get Bitten by Pointer vs Non-Pointer Method Receivers in Golang"
date: "2014-08-09"
comments: true
categories: [golang]
---

{{%img src="/images/gopointer/gopherswrench.jpg" caption="" %}}

# What?

People from all sorts of backgrounds are flocking to the [Go Programming Language](http://golang.org) and even for those who have written C and C++ before (myself included) it may be confusing to grok Go's approach to pointers, and how they interact with the methods you can attach to Go's structs.

In Go, you define a *method receiver* to specify which struct to attach a certain function to in order to make it invoke-able as a method.  For instance, `func (d Dog)` is part which defines the method receiver in the following program:

```go
package main

import "fmt"

type Dog struct {
}

func (d Dog) Say() {
    fmt.Println("Woof!")
}

func main() {
    d := &Dog{}
    d.Say()
}
```

## Is there confusion?

There was for me at first over something having to do with method receivers, and I just noticed that another person who I consider to be quite competent had been surprised by this as well, so I decided to write about it.

In Go, you can define methods using both *pointer* and *non-pointer* method receivers.  The former looks like `func (t *Type)` and the latter looks like `func (t Type)`.  Though [the spec](http://golang.org/ref/spec#Method_sets) has very specific details about how the various types of method calls should behave, when I first started programming in Go I felt that pointers and the things that they point to were often conflated in property accesses and method invocations using the `.` operator.  I was thrown because I am accustomed to having to use the `->` operator, a habit carried over from C, as a shorthand for "dereference this struct pointer and use the `.` operator".  For those unfamiliar, a quick picture of what that looks like:

```c
#include <stdio.h>
#include <stdlib.h>

struct Tree {
    int a;
    int b;
};

int main() {
    struct Tree tree, *pointerToTree;
    tree.a = 5;
    tree.b = 7;
    pointerToTree = malloc(sizeof(struct Tree));
    pointerToTree->a = 5;
    pointerToTree->b = 7;
    printf("tree vals: %d %d\n", tree.a, tree.b);
    printf("pointerToTree: %p %d %d\n", pointerToTree, pointerToTree->a, pointerToTree->b);
    free(pointerToTree);
    return 0;
}
``` 

In Go you have more freedom of expression, and the type system dictates that:

> A method call `x.m()` is valid if the method set of (the type of) `x` contains `m` and the argument list can be assigned to the parameter list of `m`. If `x` is addressable and `&x`'s method set contains `m`, `x.m()` is shorthand for `(&x).m()`

This leads to emergent behavior depending on how you define the method, and in particular, the method receiver.

## So what's the difference between pointer and non-pointer method receivers?

Simply stated:  you can treat the receiver as if it was an argument being passed to the method.  All the same reasons why you might want to pass by value or pass by reference apply.

Reasons why you would want to pass by reference as opposed to by value:

- You want to actually modify the receiver ("read/write" as opposed to just "read")
- The `struct` is very large and a deep copy is expensive
- Consistency: if some of the methods on the `struct` have pointer receivers, the rest should too.  This allows predictability of behavior

If you need these characteristics on your method call, use a pointer receiver.

## Show me.

Some code to demonstrate, and an [example on the Go playground](http://play.golang.org/p/O0O7Nk1SGF):

```go
package main

import "fmt"

type Mutatable struct {
    a int
    b int
}

func (m Mutatable) StayTheSame() {
    m.a = 5
    m.b = 7
}

func (m *Mutatable) Mutate() {
    m.a = 5
    m.b = 7
}

func main() {
    m := &Mutatable{0, 0}
    fmt.Println(m)
    m.StayTheSame()
    fmt.Println(m)
    m.Mutate()
    fmt.Println(m)
}
```

You'll notice that the conspicuously named `StayTheSame` and `Mutate`  methods have behavior which corresponds to precisely that:  `StayTheSame` is defined with a non-pointer receiver and doesn't change the values of the `struct` it is invoked on, and `Mutate` is defined with a pointer receiver, so it *does* change the values of the `struct` upon which it is invoked.

# Fin

In the process of writing this article I also noticed a [great explanation of this](http://golang.org/doc/faq#methods_on_values_or_pointers) in the Go FAQ.  It's definitely worth a read.  It covers many of the same points, and helped me round out my understanding of the issue.

Until next time, stay sassy Internet, and may your code forever be free of race conditions.

- Nathan