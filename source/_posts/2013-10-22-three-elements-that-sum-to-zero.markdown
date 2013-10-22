---
layout: post
title: "Three Elements That Sum To Zero"
date: 2013-10-22 00:02
comments: true
categories: [computer science,c++,stl,math,programming]
---

There's an interview question (for developers) that recently I've been asking (if they have already proven they can [FizzBuzz](http://www.codinghorror.com/blog/2007/02/why-cant-programmers-program.html)) which goes a little something like this:

<blockquote>Given an array of integers, return the indices of any three elements which sum to zero.  For instance, if you are given <code>{-1, 6, 8, 9, 10, -100, 78, 0, 1}</code>, you could return <code>{0, 7, 8}</code> because <code>-1 + 1 + 0 == 0</code>.  You can't use the same index twice, and if there is no match you should return <code>{-1, -1, -1}</code>.</blockquote>

I first heard this question in an interview with a San Francisco-based startup, and it has since become sort of a workhorse interview question around the office.  As it turns out, this question has the potential to [nerd snipe](http://xkcd.com/356/) developers pretty effectively.  I know, because I coded up the naïve solution first before deciding that it wasn't good enough, and that I wanted to write it a faster way.  Combining this with my recent revival of interest in C++ (I learned it long ago but have been mostly working with scripting languages lately) proved to be an interesting experience.  This is the story of one man (me), and his quest to write code to efficiently solve this problem.

The obvious way to do this is with brute force.  Starting with the zeroeth, first, and second elements of the array, compare every element


