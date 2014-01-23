---
layout: post
title: "How I Automated \"Finding Almost Anyone's Email Address\""
date: 2013-11-23 17:22
comments: true
categories: [growth hacking,rapportive,python,cURL,API,sales,marketing]
---

{% img /images/autorap/demo-fast.gif A demo, complete with colors. %}

*EDIT:  The original article author, Rob Ousbey, has popped up on various social media sites to remind everyone to use this tool/knowledge responsibly.  I agree.  Please be responsible.*

Not too long ago I came across an article on [Hacker News](https://news.ycombinator.com) called "[The cold emails that got me meetings at Twitter, LinkedIn and GitHub](http://www.startupmoon.com/how-i-got-meetings-at-twitter-linkedin-and-github-using-cold-emails/)".  It's by a woman named Iris Shoor who is a co-founder of a startup called [Takipi](http://www.takipi.com/).  In the article she describes how she used a certain technique originally presented [here](http://www.distilled.net/blog/miscellaneous/find-almost-anybodys-email-address/) to obtain access to the emails of decision makers at tech companies and cold email them to glean meetings which resulted in sales of her product.  Both of the articles are engaging reads and I highly recommend them, especially if you are interested in "growth hacking", or "sales and marketing" if you insist on using boring non-buzzwords.

# How Does It Work?

In the original "How To Find Almost Anyone's Email Address" article, Rob Ousbey presents a Google Doc spreadsheet that will generate a large number of possible emails for someone based on their name and the domain name of the company they work for.  [Go ahead, try it out](http://bit.ly/name2email).  Many peoples' emails are something along the lines of *[firstname].[lastname]@[company].com*, so there's a high likelihood that their email will be in the list of generated possibilities.  

Then, users are encouraged to exhaustively test each possibility in their Gmail account using the [Rapportive](https://rapportive.com/) Chrome extension until they come across a 'hit' (although a little bit of creative Googling will sometimes yield the desired result for you in less time).

When trying this out for the first time on a recruiter I was interested in contacting, I found myself clicking the generated permutations in succession with a looming disbelief that this trick would actually work.  Then, suddenly, Rapportive lit up with their portrait and social media info and I felt a funny buzzing sensation in my head as the possibilities swirled around in it.  

{% img /images/autorap/larry.png I feel funny about this. %}

However, doing it this way was exhausting and tedious, as it required a lot of focus and time.  My programmer instincts revved up and I became convinced that I could automate the process.

# Automating It

I won't be publishing my full source code because this has so much potential for abuse, but I will talk a little bit here about how I accomplished automating this.  I chose to reach for my old friend Python to write the script to automate this process.  I wanted to get things done quickly and easily and Python proved to be a great boon here, even providing the excellent `argparse` module to make the script much more usable from the command line.

{% img /images/autorap/copy-as-curl.jpeg Useful Developer Tools are useful. %}

First, I got an example cURL request using Chrome's handy developer tools.

Then, I called the "secret" Rapportive API using `pycurl`.  There's a few fields that can be used to identify whether a response has come back for the suggested user, and we use that to determine whether the user, and consequently their email address, has been found.  We also check it against the returned full name to ensure that we haven't gotten back a false positive (for example, Rapportive may return something for "larry@google.com", but it may not be the Larry we are looking for).  Outputting all of the emails we try to the terminal, we color the bunk addresses red, the "false positive" emails yellow, and the successful return results green.  Like good Internet citizens, we wait for a specified interval in between calls to the Rapportive server (2 seconds in the demo at the top of this page).  Upon finding the email for the person we're looking for, the program exits.

The Rapportive API is surprisingly flexible on what you send it as far as HTTP headers goes, seeming to rely mostly on the `X-Session-Token` header for user authentication.  


The main loop in Python looks like this:

```python
if __name__ == '__main__':
	args = argument_handler.handle_args()	
	rap_client = RapportiveClient(args.name, verbose=args.verbose)
	permutator = Permutator(args.name, args.domain)	
	permutations = permutator.get_permutations()

	for permutation in permutations:
		output = permutation 
		rap_client.perform(permutation)
		if args.should_color:
			output = colorer.color(permutation, rap_client)
		if not args.quiet: 
			print output 
			if rap_client.was_user_found() and rap_client.name_match():
				sys.exit(0)
		else:
			if rap_client.was_user_found():
				print output
				sys.exit(0)	
		time.sleep(args.wait_interval)
``` 

# Conclusion

Rapportive is a subsidiary of LinkedIn and LinkedIn has been catching a lot of heat lately for everything from their [iOS MITM hack](http://engineering.linkedin.com/mobile/linkedin-intro-doing-impossible-ios) to their [notorious password breach](http://blog.linkedin.com/2012/06/06/linkedin-member-passwords-compromised/).  They're a popular company to love to hate.  However, I think their tools have as much potential for cool stuff as they do for abuse.  Honestly, I'm surprised that the trick described in this article is not more well-known.  I haven't cold emailed anyone whose address I have obtained this way, but if I needed to do so I'd be very pleased to have this tool at my disposal.

Cheers and I'll see you next week.

Nathan
