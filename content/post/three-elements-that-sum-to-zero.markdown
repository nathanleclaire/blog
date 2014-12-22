---
layout: post
title: "Three Elements That Sum To Zero"
date: "2013-10-22"
comments: true
categories: [computer science,c++,stl,math,programming]
---

There's an interview question (for developers) that recently I've been asking (if they have already proven they can [FizzBuzz](http://www.codinghorror.com/blog/2007/02/why-cant-programmers-program.html)) which goes a little something like this:

<blockquote>Given a collection of integers, return the indices of any three elements which sum to zero.  For instance, if you are given <code>{-1, 6, 8, 9, 10, -100, 78, 0, 1}</code>, you could return <code>{0, 7, 8}</code> because <code>-1 + 1 + 0 == 0</code>.  You can't use the same index twice, and if there is no match you should return <code>{-1, -1, -1}</code>.</blockquote>

I first heard this question in an interview with a San Francisco-based startup, and it has since become sort of a workhorse interview question around the office.  As it turns out, this question has the potential to [nerd snipe](http://xkcd.com/356/) developers pretty effectively.  I know, because I coded up the naive solution first before deciding that it wasn't good enough, and that I wanted to write it a faster way.  Combining this with my recent revival of interest in C++ (I learned it long ago but have been mostly working with scripting languages lately) proved to be an interesting experience.  This is the story of one man (me), and his quest to write code to efficiently solve this problem.  In my solutions I use the `std::vector` class, as I also used this as an opportunity to refresh some STL knowledge, but in the article I use the words "array" and "vector" interchangably (these solutions could also be implemented with arrays, there is nothing special about using vectors in this case).

# Solving Things Naively

The obvious way to do this is with brute force.  Starting with the zeroeth, first, and second elements of the collection, compare every possible combination of three elements to see if they sum to zero.  Sample code (`using namespace std;` is implied):

```c++
vector<int> three_indices_that_sum_to_zero_naive(vector<int> v)
{
    // O(n ** 3) time complexity in average case
    int i, j, k, n;
    n = v.size();
    for(i = 0; i < n-2; i++)
    {
        for(j = i+1; j < n-1; j++)
        {
            for(k = j+1; k < n; k++)
            {
                if ((v.at(i) + v.at(j) + v.at(k)) == 0)
                {
                    return three_vec(i, j, k);
                }
            }
        }    
    }
    return three_vec(-1, -1, -1); 
}
```

`three_vec` is a utility method that I use to return a vector of three integers:

```c++
vector<int> three_vec(int i, int j, int k)
{
    int arr[] = {i, j, k};
    vector<int> indices (arr, arr + sizeof(arr) / sizeof(arr[0]));
    return indices;
}
```

This is the obvious way to do the problem at first glance, and it has the advantage of simplicity and readability (a competent developer looking at the code should be able to figure it out fairly quickly).  However, as noted in the comments for the function defined, it runs with a time complexity of O(_n<sup>3</sup>_).  Can we do better?

# Solving Things Suavely

Of course we can, or else I wouldn't be writing this article!  Reaching into our algorithmic bag of tricks, we begin to ask ourselves: Is there anything we can do to this otherwise unordered vector of integers that would make it easier for us to get what we're after?

_"Hm,"_ you say to yourself.  _"We could trying sorting it.  This will run in O(n log n) time but it will allow us to find what we are looking for much more quickly."_   But wait- sorting the vector will change the place of the elements, and consequently their index, which is what we are after.  Therefore, we must rely on an additional (simple) data structure if we are going to take this approach: 

```c++
typedef struct index_value_pair {
    int index;
    int value;
} index_value_pair;
```

Now we can make a new array and sort that based on `index_value_pair`'s `value` element:

```c++
/* Utility Function to create an index_value_pair */
index_value_pair make_index_value_pair(int index, int value)
{
    index_value_pair ivp;
    ivp.index = index;
    ivp.value = value;
    return ivp;
}

vector<int> three_indices_that_sum_to_zero_suave(vector<int> v)
{
    int i, j, k, n, sum;
    n = v.size();
    vector<index_value_pair> value_index_vec;
    for (i = 0; i < n; i++) 
    {
        value_index_vec.push_back(make_index_value_pair(i, v.at(i)));
    }
    sort(value_index_vec.begin(), value_index_vec.end(), suave_comp);
```

Then, we can work our way forwards from the beginning of the array starting with the zeroeth and first elements (let's call them the `i`th and `j`th), and _backwards_ from the end of the array with the third (the `k`th).  `i` will go to `n-2` and start off an inner loop where `j = i + 1`.  In the inner loop, if the sum of the elements is positive, we decrement `k` because we need a smaller sum (closer to zero).  If the sum of the elements is negative, we increment `j` because we need a larger sum (also closer to zero).  If the elements sum to zero, great!  We have our match.  If `j` and `k` meet, we go on to the next loop.  This process shaves a whole multiple of `n` comparisons off our algorithm's runtime and allows us to do things in O(_n<sup>2</sup>_) time.

You can intuitively grasp why this is faster by asking yourself how many comparisons it would take to find the elements that sum to zero with this array (sorted) and this algorithm:

```
{-10, -8, -6, 0, 3, 5, 18}
```

versus this one (same elements, different order) with brute force:

```
{-6, -8, 0, 3, 10, -8, 18}
```

Therefore the whole function looks like this and runs with O(_n log n + n<sup>2</sup>_) time complexity including the sort.  O(_n <sup>2</sup>_) is asymptotically larger than O(_n log n_), so this time complexity resolves to O(_n <sup>2</sup>_) (_editor's note_: thanks to Reddit user Olathe for pointing this out).  This should outperform the O(_n<sup>3</sup>_) algorithm in most cases:

```c++
vector<int> three_indices_that_sum_to_zero_suave(vector<int> v)
{
    int i, j, k, n, sum;
    n = v.size();
    vector<index_value_pair> value_index_vec;
    for (i = 0; i < n; i++) 
    {
        value_index_vec.push_back(make_index_value_pair(i, v.at(i)));
    }
    // print_value_index_vec(value_index_vec);
    sort(value_index_vec.begin(), value_index_vec.end(), suave_comp);
    for (i = 0; i < n-2; i++)
    {
        j = i+1;
        k = n-1;
        while (k > j)
        {
            sum = sum_from_value_index_vec(value_index_vec, i, j, k);
            if (sum == 0)
            {
                return three_vec(value_index_vec.at(i).index, value_index_vec.at(j).index, value_index_vec.at(k).index);   
            }

            if (sum > 0)
            {
                k--;
            }
            else
            {
                j++;
            }

        }
    }
    return three_vec(-1, -1, -1);
}
```

Interestingly, with the first few benchmarks I ran, the naive version was outperforming the efficient version, and I couldn't quite figure out why (the first command line argument indicates how many random elements to generate in our test array- in other words, `N`).

```
$ ./indices_sum_to_zero 100000
Initializing...

Using naive...
Performance: 0 ticks
Naive : {0, 1, 77}
Using suave...
The elements: -100 0 100
Performance: 10000 ticks
Suave : {73045, 48974, 3270}
```

How could this be?  My carefully crafted algorithm was getting stomped by an algorithm I knew to be inferior.  After generating and poking around at a few callgrind files attempting to track down the issue, I suddenly realized that it was right in front of my eyes, in two constant definitions I had made and forgotten about early on:

```
static int LOWERBOUND = -100;
static int UPPERBOUND = 100;
``` 

These settings were used to specify the range of the pseudorandom integers I was using to test the algorithms with, and when they were so close together the naive algorithm was outperforming the "suave" one because the additional overhead of sorting was so costly.

What if we change the bounds to be `{-10000000, 10000000}`?

```
$ ./indices_sum_to_zero 100000
Initializing...

Using naive...
Performance: 70000 ticks
Naive : {0, 539, 31774}
Using suave...
Performance: 10000 ticks
Suave : {78891, 33850, 54525}
```

Much closer to what we expect!  For smaller values of N, and upper/lower bounds that are closer together, the naive version seems to perform better.  As the range and value of N gets larger, the "suave" algorithm begins to get more appealing.  I'd be curious to see a more rigorous numerical analysis of why this is.

Check out the [code on github](https://github.com/nathanleclaire/algorithms_and_data_structures/blob/master/indices_sum_to_zero/indices_sum_to_zero.cc) if you're so inclined.  Cheers, and I'll see you next week!

*EDIT* : Based on some feedback from Reddit I have revised a few things, notably:

- There was a bug in the implementation of `three_vec` that caused the returned value to be the same for suave and naive versions (fixed in [794993e01b1e0fa6154c722c4d74009b02cdef45](https://github.com/nathanleclaire/algorithms_and_data_structures/commit/794993e01b1e0fa6154c722c4d74009b02cdef45) )
- Constant definition is now done with `static const` instead of `#define` statements
