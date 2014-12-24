---
layout: post
title: "Migrating to Hugo From Octopress"
date: "2014-12-22"
---

{{%img src="/images/hugo/hugo.png" %}}


Unfortunately, I haven't been writing as much as I'd like to lately.  Partially this is because I've been quite busy with Docker-related things, but it also has a lot to do with aspects of my blogging stack (and approach) that were beginning to show their weaknesses.  The way that this blog got started was as an [Octopress](https://github.com/octopress/octopress) installation on a Macbook Air.  I loved the Octopress default theme's clean design and easy defaults, and I got to hit the ground running super fast.  A mere `rsync` to deploy my changes was amazing - I knew that static site generators were for me.


# But...

Unfortunately, my "designer's curse" soon kicked in and I found myself dissatisfied.  I wanted to be unique, so I deviated from the default theme and used the crisp [Pageturner](https://github.com/elisehein/pageturner) theme from Elise Hein, but I couldn't resist hacking and hacking away at it until it conformed to my weird desires.  I hacked up the Rakefile for a variety of reasons, and soon I found myself (badly) maintaining forks of both Pageturner and Octopress.  They weren't super deviant forks, but they were forks nonetheless.  Not fun.

As if that weren't bad enough, Ruby and I _just couldn't seem to get along_.  I would frequently think I had all of my RVM / rbenv / gem install stuff sorted, only to leave the computer and come back to rake blowing up later on in the day.  I have no idea what the hell happened there, but soon I was painstakingly preserving "golden terminal windows" on my laptop that I knew would actually compile the blog the right way.  Attempting to work on my blog on a new computer was frequently an exercise in frustration due to my lack of Ruby knowledge. This pain was alleviated somewhat by ["Docker-izing"](http://nathanleclaire.com/blog/2014/08/17/automagical-deploys-from-docker-hub/) the stack but it added some additional overhead to get going and writing new posts.

Additionally, the blog took a _long_ time to compile, and that was only going to grow as I wrote more posts.  There are workarounds, but I really don't want to have to think about that sort of thing with my static site generator.  Not to mention the fact that with every change to the theme / styling I was regenerating the whole site.

# So?

All of this was a distraction from what I really wanted to do: hack and write about it.  I knew that the barrier for working on writing had to be as low as possible for me or else I'd let it drop.

Given that I'm a complete Go fanboy, I started shopping around for a static site generator written in Go.  There are a few options, but only one stands at the forefront: spf13's [Hugo](https://github.com/spf13/hugo).

A quick look around indicated that it was very fast.  Just what I wanted.  To use it you only need a single statically compiled binary which works on OSX, Linux, and Windows, so that would put an end to my endless wrangling with Ruby interpreters.  Hugo also has a built-in server which is very fast (the default Octopress preview server was fairly sluggish in my experience so I actually had been using a [Node.js module](https://www.npmjs.com/package/http-server) for the purpose :P) and a _really_ slick built-in filesystem watch / LiveReload feature.  Out of the box the `--watch` mode will regenerate the post you are working on and refresh the browser page you are viewing it in when you save.  This all happens almost instantaneously.

{{%img src="/images/hugo/livereload.gif" %}}

Needless to say, Hugo looked like a great choice.

I knew the conversion would require some work, but it ended up being a little more to take on than what I expected.  Some Googling around suggested that the majority of the work would be in moving over the templates to use Go templates instead of Liquid templates.  There ended up being a lot more to it than that for me, so I wanted to document it here to help people in the future and share my experiences.

# The migration

If you want Hugo to be a drop-in replacement for Jekyll or Octopress you're gonna have a bad time - it's a totally new system with totally new needs.  However, there are some things that you might want to consider in your move over.

## Structure

Instead of trying to convert an existing project repo to Hugo, I'd start with a totally new directory and copy over the bits you need as it comes up.  As noted in the [quickstart](http://gohugo.io/overview/quickstart), Hugo provides a command for this:

<pre>
$ hugo new site newblog
</pre>

You'll get a structure like:

<pre>
archetypes
content
layouts
static
config.toml
</pre>

- `content` is for your actual content (in my case, blog posts and a few descriptive pages such as the "About" page).
- `layouts` is for defining the structure and layout of your pages.  This is where the Go templates you will create or use will live.
- `static` is for JS, CSS, images, etc.
- `archetypes` allow you specify generic forms of content front matter (metadata) for when you run `hugo new`

I'd attempted a migration once before, so I actually had a pre-existing `config.yml` (Hugo lets you specify configuration in TOML, JSON, or YAML) that I used:

```yaml
---
baseurl: "http://nathanleclaire.com"
title: "nathan leclaire"
layoutdir: "layouts"
contentdir: "content"
publishdir: "public"
indexes:
    category: "categories"
permalinks:
    post: /blog/:year/:month/:day/:title/
metadataformat: "yaml"
---
```

Most of this is pretty standard, but note the `permalinks` key.  I wanted each post to correspond to its old permalink from the Jekyll blog, so this was critical for me (in fact I couldn't figure out how to make it work with an earlier version of Hugo, which was partially why the previous effort stalled).  Without having the same links to old articles that used to be there (and with no redirects in place), I would be penalized by Google.  So figuring out a solution to that was critical.

## Template conversion

This is definitely the scariest chunk going into things.  Mostly, however, it's just a matter of hack and slash.  You'll just have to go into your existing Jekyll theme and convert what's there to Go templates.  I used this as an opportunity to do some badly-needed refactoring.

Inside of the `layouts` directory you can define a directory named `partials` which can be used to import sub-templates into other templates.  This allowed me to convert some of the existing header, footer, etc. templates pretty directly into Go templates.  There are a few things that take some getting used to (for instance, you can use `unless` blocks in Liquid but not in Go AFAIK) but most of them are easily worked around and Hugo provides a lot of useful functions for getting started.

The general structure I used was as follows:

I have a `header.html` partial for the beginning of the HTML, which is mostly the same across the site:

```html
<!doctype html>
<!-- START OF _layouts/default.html -->
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta content="IE=edge,chrome=1" http-equiv="X-UA-Compatible" >
        <meta content="width=device-width,initial-scale=1" name="viewport">
        <meta content="{{ .Description }}" name="description">
        <meta content="{{ .Title }}" name="author">
        
        <title>
            {{ .Title }} | I care, I share, I'm Nathan LeClaire.
        </title>
        
        <link href="{{ .Site.BaseUrl }}/stylesheets/main.css" rel="stylesheet">
        <script src="//cdnjs.cloudflare.com/ajax/libs/jquery/1.11.0/jquery.js"></script>
    </head>
    <body>
```

I ended up cutting a lot of stuff out of the original Jekyll template that I don't think I'll really miss.

I also have a `footer.html` which closes up the page:

```html
<script type="text/javascript" src="{{ .Site.BaseUrl }}/js/prettify.js"></script>
<script type="text/javascript" src="{{ .Site.BaseUrl }}/js/jquery.modal.min.js"></script>
<!-- other js -->
</body>
</html>
```

Putting it all together, I can make a default template (located at `layouts/partials/chrome/article.html`) for a type of content ("post") that Hugo will understand:

```html
{{ partial "chrome/header.html" . }}

<div class="wrap">
    {{ partial "chrome/sidebar.html" . }}
    <div id="content">
        {{ partial "article.html" . }}
        {{ partial "modal.html" . }}
    </div>
</div>

{{ partial "chrome/footer.html" . }}
```

Some code worth noting from the "article.html" partial:

```html
<time>{{ .Date.Format "2 Jan 2006" }}</time>
```

This kind of date formatting seemed really weird to me at first, as I was accustomed to the `"Y-m-d H:i:s"` variety from PHP etc., but it makes sense to me now.  Essentially, you simply write the reference time (`"Mon Jan 2 15:04:05 -0700 MST 2006"`) in the format that you want (that's why it's "2 Jan 2006" in the above example - Day, Month in string form, and four-digit year) and Go will figure out how to conform the particular date instance to that format.  Note that none of the numbers 1-9 get re-used in the reference date.

See [http://golang.org/pkg/time/#Time.Format](http://golang.org/pkg/time/#Time.Format) for reference.


## Date / Permalink challenges

Speaking of dates, that's a good segue to the next challenge I tackled.  Once I had a 
seemingly viable template conversion, I tried generating HTML from the Markdown posts I have.

When I smoothed over a few initial syntax errors etc., I soon hit another roadblock.  
Hugo was generating the HTML for the articles at `/blog/2014-09-20-title/index.html` instead of properly nested in the directories as they should be to make the permalinks work correctly (there were dashes instead of slashes).

I'm not 100% positive (haven't checked the code), but I think that Jekyll infers the permalink path from the filename (all posts start with e.g. `2014-09-20-`), whereas Hugo infers it from the `date` key specified in the front matter.

Hm, my dates in the front matter were specified like:

```yaml
date: 2013-10-27 19:44
``` 

But in the Hugo documentation they look like:

```yaml
date: "2013-10-27"
```

Maybe changing that would fix it?

I tried it manually with one article and got the article at the correct path for the permalink.  So, I could go change all the dates manually, but with 45 articles, that would have been pretty miserable.

So what to do?  `sed` to the rescue.  It took a couple of tries but eventually I worked out an expression to automate the process:

<pre>
$ find -type f -exec sed -i 's/\([0-9]\+-[0-9]\+-[0-9]\+\).*$/"\1"/' {} \;
</pre>


Make sure you have everything in version control before you try making sweeping (potentially destructive) changes such as this ;) .  Also note that this is done using GNU sed and find, not BSD sed and find (which is the default that comes with OSX), so make sure you that you either use the GNU tools (available in Homebrew) or convert it to work with the BSD versions.

With that `sed`, permalinks were looking a lot better!

## Plugins, shortcodes, images

I didn't rely too heavily on Jekyll plugins, so thankfully there wasn't a huge amount of work there to do, but one that I relied on pretty ubiquitously was `{%img .. %}` to implement captioned images.

{{% img src="/images/hugo/pretty.jpg" caption="Like this one." %}}

I used this endlessly while writing in the Jekyll blog without really thinking about the fact that it was a plugin, not a standard part of Markdown.  They generally took the form:

<pre>
{%img /images/foo.jpg This is the caption %}
</pre>

So, when migrating to Hugo, I needed a solution.  Hugo provides [shortcodes](http://gohugo.io/extras/shortcodes/) as a way to address this type of situation.  They are not too bad to implement, so I created one which was very similar for images.  It lives in the file `layouts/shortcodes/img.html`:

```html
<img src="{{ .Get "src" }}">
<div class="caption">{{ .Get "caption" }}</div>
```

And it's used like this:

<pre>
&#123;&#123;%img src="/images/foo.jpg" caption="This is a foo" &#125;&#125;
</pre>

OK, great, now that I had that working, the only thing remaining was to run another sed command like in the previous section to replace the old version with the new one:

<pre>
$ find -type f -exec \
    sed -i 's/{% *img \([^ ]*\) \(.*\) %}/&#123;&#123;%img src="\1" caption="\2"&#125;&#125;/' {} \;
</pre>

Easy to read, right?


## Some finer details

Things were starting to shape up pretty nicely, but there still a few things to fix up.

For one, I think that the Jekyll backtick / codeblock plugin previously was converting tabs to spaces for me (WARNING: CONTROVERSY AHEAD).  All of my code blocks in the new site just seemed a little bit _too_ indented.  So I whipped up yet _another_ `sed` command to help, which I ran in the `content` directory:

<pre>
$ find -type f -exec sed -i $'s/\t/    /g' {} \;
</pre>

This one will replace any instance of a tab with four spaces.  After a quick `git diff` to make sure there weren't any unwanted changes, I was good to go.

Previously in a few places I had to use `{% raw %}...{% endraw %}` blocks in my Markdown files to prevent Jekyll from "misunderstanding" that I wanted to render some Angular templates literally inside of codeblocks.  Hugo has no such thing that I'm aware of (although arguably it should), but it didn't have any issues rendering the Angular templates either, so I just wanted to take the blocks out.  `sed` to the rescue again:

<pre>
$ find -type f -exec sed -i '/{% raw %}/d' {} \;
$ find -type f -exec sed -i '/{% endraw %}/d' {} \;
</pre>

Last but not least, I had no reason for my Markdown filenames to be prefixed with the date of writing any more, so I wanted to get rid of those.  This little Bash loop took care of that:

```bash
for file in $(ls); do 
    git mv ${file} ${file:11};
done
```

It will simply chop off the first ten characters of each filename (assumed to be in a git repo).

## More permalink drama

So, things were looking pretty good - but, I soon began to notice that not all permalinks (#NotAllPermalinks ?) generated by Hugo were equivalent to the ones I had generated using Octopress.  There were two main factors at play with that:

1. Periods (`.`) in article titles were replaced by the string "dot" in Octopress (`Learn Node.js` would become `learn-node-dot-js`), but not in Hugo.  Hugo used periods in the URLs directly (`Learn-Node.js`).
2. Some characters such as `&` (ampersand) were stripped out completely from the title by Hugo. This mostly works OK but Hugo would create two dashes instead of one where the character used to be and there were some cases where Jekyll replaced `&` with the _word_ `and` and so on, that Hugo would just strip out completely.  Therefore something like `Golang? Let's try some gorp` would become `golang--lets-try-some-gorp` (note the double dash) instead of `golang-lets-try-some-gorp`.

Until Hugo has some solutions for these (if it ever does), I've hardcoded the correct links in the "url" key in the front matter for articles where the permalink deviates.  It's totally possible, of course, that I'm just quite thick and haven't noticed that there is already a solution existing for such an issue.  Once again, I may well crack open the Hugo source and get my hands dirty with respect to this issue at some point, but I'm impatient and this workaround is fine for now.

## Other notes

Part of Octopress is an implicit use of [SASS](http://sass-lang.com/) for CSS pre-processing.  I like the idea of CSS preprocessors, and I'd probably use them if I were working on a very in-depth front-end project, but having to use SASS was a bit of overkill for my needs with the blog.  So I took the most recent bundle (one big glob in `/stylesheets/main.css`), unminified it, and just included that instead.  I might refactor things to use a preprocessor later if my needs later on become more complex, but I don't really mind having a big hairy ball of CSS that I occasionally slap rules onto as I need them.

I cut out some features of the blog due to laziness and/or them being hacked up abominations in the first place that I didn't want to maintain anymore.  These include the search in the sidebar (I feel it looks cleaner now) and the "Submit a Pull Request for this on Github!" link (which I intend to bring back later, but couldn't figure out an elegant solution for during the migration).  I'd love to have some kind of `{{.Node.Filename}}` variable available in the templates so that I could reference the file's source on Github.  I might crack open the Hugo source later and submit a PR for such a thing.

I'm taking down the Discourse forum and replacing it with Disqus comments.  It was a good idea, but it's the last thing keeping me from dropping my Linode (the blog has been moved completely to S3), and I haven't had the time or willpower to administrate it properly (for instance, as far as I'm aware all social logins are broken with the Discourse instance at this time).  Discourse is still rad software and I hope I get to implement it again someday.

With respect to RSS: just make sure you follow the instructions [here](http://gohugo.io/templates/rss/).  Please, _please_ let me know if the feeds are broken for anyone out there.

For the life of me, I could not figure out how to get Hugo to stop generating mixed-case URLs (I just want lowercase), so I use the `lower` directive in a few places that I was making internal blog links (e.g. the [Archives page](http://nathanleclaire.com/post)).

I really wish that Hugo vendored dependencies and built inside of a Docker container.  Without vendoring deps or at least using something like Godeps it's really hard to know what you're getting when using `go get -u ./...` and compiling from source may well blow up in your face (all it takes is one broken build in one dep...).

# What did you learn?

I have to say that the experience gave me empathy for businesses and organizations that have legacy applications which they need to keep chugging along.  It's easy for arrogant developers to say "It's a mess, they should just rewrite the damn thing" or "I could create this in a weekend in Go" but they usually aren't thinking of all the legacy requirements and things that would break and so on.

I think that the approach Steve has taken with Hugo is very interesting.  It seems that Hugo is designed with a "roll your own batteries" attitude in mind rather than the "batteries included" attitude of Octopress.  I have a feeling that a very vibrant community will continue emerging around Hugo and it will continue to get better as time goes on.

I'm very happy with the new setup and hopefully the changes to make writing easier for me will be worth it.  Until next time, stay sassy Internet.

- Nathan
