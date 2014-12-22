---
layout: post
title: "Implementing a Concurrent Floodfill with Golang"
date: "2014-04-05"
comments: true
categories: [golang,algorithms,floodfill,concurrency]
---

# The setup

Lately as part of a coding exercise I found myself implementing a [Flood Fill](http://en.wikipedia.org/wiki/Flood_fill) for "painting" an ASCII canvas.  For those of you unfamiliar with what that is, think back to MSPaint - remember that little paint bucket that would fill a region with your color of choice?  That paint bucket implements a flood fill algorithm, although I didn't know that's what it was called until I started working on implementing one myself.

{{%img src="/images/flood-fill/flood-fill-basic.gif" caption="" %}}

My original implementation was in PHP and I had to go through a few iterations before I got to an implementation I was satisfied with.  It was surprisingly tricky to get correct as my depth-first implementation kept blowing the stack through excessive use of recursion.  A naive flood fill algorithm (depth first) looks like this:

1. Store the color of the pixel where you are starting, then color it the new color.
2. For every adjacent pixel, if it is the same as the original color and you have never visited that pixel before, perform a flood fill on it.

There are a lot of issues with this algorithm.  It takes a long time and it will quickly blow the stack if the canvas size contains more than a trivial number of pixels.

So I started thinking about ways to improve it, and it occurred to me to use a *breadth*-first solution instead (this is actually the kind of solution that's visualized in the GIF above).  That way, we could store the pixels that we want to visit / fill in a queue, and visit them one at a time without blowing the stack.  It worked pretty well.

Just one problem, though:  It was written in PHP, and PHP is dog slow.  It's also painfully single-threaded to boot.

# Go!

`<s>` Since we all know that all the cool kids use [Go](http://golang.org) nowadays `</s>`, I decided to take a crack at implementing a solution for this in Go, taking advantage of Go's high performance and concurrency patterns.  Also, I just really like coding stuff in Go.

## "Canvas" abstraction

The "canvas" I modeled as an two-dimensional array of byte arrays (which are chars for our purposes).  There's another matrix that we use to keep track of which pixels we have visited before.  For convenient passing, we also have a struct `Node` that contains data about a given pixel.  We will use this later on to make our helper functions a little bit more clean looking.

```go
type Canvas struct {
    contents [][]byte
    visited  [][]bool
}

type Node struct {
    X     int
    Y     int
    Color byte
}
```

The function to initialize the "canvas" is pretty straightforward.  We also have an analagous method, `setVisitedMatrixToFalse`, that we call before performing a flood fill operation to indicate we haven't visited anywhere yet.

```
func (c *Canvas) Init(width int, height int, blankChar byte) {
    c.contents = make([][]byte, width)
    for i := 0; i < width; i++ {
        c.contents[i] = make([]byte, height)
        for j := 0; j < height; j++ {
            c.contents[i][j] = blankChar
        }
    }
}
```

Called like:

```
canvas := Canvas{}
canvas.Init(120, 120, '_')
```

We take advantage of easy casting from `[]byte` type to `string` for our function to print the contents of the canvas:

```
func (c *Canvas) Print() {
    for _, row := range c.contents {
        fmt.Println(string(row))
    }
}
```

With this code set up, we can get into the "meat" of the flood fill algorithm.

## Flood Fill

Instead of using pure recursion, we will instead have a "master" goroutine that forks off visits to other pixels/nodes in their own goroutines.  The child goroutines will report back their "findings" to the main goroutine, including what pixels to visit next if any.  Through the use of buffered and unbuffered goroutines, we will prevent too many visits from firing off at once, and the Go runtime scheduler will take care of juggling these activities which are running concurrently. 

The main goroutine looks like this:

```
func (c *Canvas) FloodFill(x int, y int, color byte) {
    // If unbuffered, this channel will block when we go to send the
    // initial nodes to visit (at most 4).  Not cool man.
    toVisit := make(chan Node, 4)
    visitDone := make(chan bool)

    originalColor := c.contents[x][y]

    c.setVisitedMatrixToFalse()

    go c.floodFill(x, y, color, originalColor, toVisit, visitDone)
    remainingVisits := 1

    for {
        select {
        case nextVisit := <-toVisit:
            if !c.visited[nextVisit.X][nextVisit.Y] {
                c.visited[nextVisit.X][nextVisit.Y] = true
                remainingVisits++
                go c.floodFill(nextVisit.X, nextVisit.Y, color, originalColor, toVisit, visitDone)
            }
        case <-visitDone:
            remainingVisits--
        default:
            if remainingVisits == 0 {
                return
            }
        }
    }
}
```

To start, we create two channels.  One is called `toVisit` and is the channel through which we send Nodes that we still want to visit (color, then check if they have neighbors we should color).  You may notice that this channel is buffered.  This is because if it is not buffered, then when we attempt to send `Node`s to visit over it, it will block and the whole program will deadlock.  Since we know that we will "queue up" at most four `Node`s into the channel (for this exercise we don't fill pixels which are diagonally adjacent), that's why we set our buffer size to that.  Theoretically however it will work with any buffer value greater than or equal to one.

The other channel is called `visitDone` and is used to indicate when a visit for a given node is finished.  We don't care which one, since we just maintain a "one true counter" in our main routine (`remainingVisits`) that tracks how many outstanding visits we have, and ensures that the function doesn't return as long as there are visits outstanding.  Before I implemented this solution I was getting all kinds of frustrating race conditions where the `default` block would sometimes get hit before any additional visits would get added, and so the program would exit prematurely.  If you have a better idea/solution to manage this, I'd love to hear!

We also keep track of the color of the original pixel, since that's a condition of coloring (the pixels should be adjacent and the same color as the original pixel).

The `floodFill` method that we spin off into auxilliary goroutines looks like this:

```
func (c *Canvas) floodFill(x int, y int, color byte, originalColor byte, toVisit chan Node, visitDone chan bool) {
    c.contents[x][y] = color
    neighbors := c.getNeighbors(x, y)
    for _, neighbor := range neighbors {
        if neighbor.Color == originalColor {
            toVisit <- neighbor
        }
    }
    visitDone <- true
}
```

I don't know that I'm crazy about having the actual pixel coloring in this method, since it involves mutable data that's shared between threads, so I might move it into the main method eventually, but for example purposes it works okay.  This method is fairly terse and simply colors the pixel, then calls this method to get the neighbors of the current pixel (ensuring that we don't run over the bounds of the slice):

```
func (c *Canvas) getNeighbors(x int, y int) []Node {
    var (
        neighbors []Node
        color     byte
    )
    if x+1 < len(c.contents) {
        color = c.contents[x+1][y]
        neighbors = append(neighbors, Node{x + 1, y, color})
    }
    if x-1 >= 0 {
        color = c.contents[x-1][y]
        neighbors = append(neighbors, Node{x - 1, y, color})
    }
    if y+1 < len(c.contents[0]) {
        color = c.contents[x][y+1]
        neighbors = append(neighbors, Node{x, y + 1, color})
    }
    if y-1 >= 0 {
        color = c.contents[x][y-1]
        neighbors = append(neighbors, Node{x, y - 1, color})
    }
    return neighbors
}
```

Then, we send the returned nodes over the `toVisit` channel if their color matches the original pixel's color, and we send `true` across `visitDone` channel to indicate we are done when that is all through (this decrements our counter in the main goroutine).

And that's all!

Check the sample output.

Before:

<pre>
____________________
________//__________
________//_______---
__\\\\\\\\\\\\\\_---
________//_______---
________//_______---
________//_______---
_________________---
_________________---
_________________---
_________________---
_________________---
_________________---
_________________---
_________________---
_________________---
_________________---
_________________---
_________________---
_________________---
</pre>

After: (filled with `'G'` char)

<pre>
GGGGGGGGGGGGGGGGGGGG
GGGGGGGG//GGGGGGGGGG
GGGGGGGG//GGGGGGG---
GG\\\\\\\\\\\\\\G---
GGGGGGGG//GGGGGGG---
GGGGGGGG//GGGGGGG---
GGGGGGGG//GGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
GGGGGGGGGGGGGGGGG---
</pre>

It runs pretty satisfyingly quickly.  Wiki mentions a few alternative approaches that might work a little better (EDIT: it says that going line-by-line instead of pixel by pixel is an order of magnitude faster), but I like this one for its simplicity.

# Conclude

The code is [up on Github](https://github.com/nathanleclaire/golangfloodfill) if you're curious.  I'd love to hear about other possible approaches, especially ones that are better at taking advtange of Go's concurrency features.  I considered using `sync.WaitGroup` but this didn't really seem like a good case to do so.

Until next time, stay sassy Internet.

- Nathan
