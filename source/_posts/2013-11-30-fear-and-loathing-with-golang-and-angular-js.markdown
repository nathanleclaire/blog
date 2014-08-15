---
layout: post
title: "Fear and Loathing With Golang and AngularJS"
redirect_from: /blog/2013/11/30/fear-and-loathing-with-golang-and-angular-dot-js/index.html
date: 2013-11-30 14:40
comments: true
categories: [Angular,Golang,Form,Post,ParseForm,Bugs]
---

{% img /images/fearandloathing/fearandloathingwithgolangular.jpeg Complete and utter hyperbole. %}

Recently I've been building an app to check a web page for broken links using [Golang](http://golang.org) and [AngularJS](http://angularjs.org) (it's for use with this blog, actually, as well as general public consumption).  It's pretty close to being done, except for a contact form which will allow people to send an e-mail directly to me (which has involved all manner of fun with Go's [smtp](http://golang.org/pkg/net/smtp/) library and will most likely be the subject of a future blog post) to make suggestions, send comments, flame me for creating a free tool for them to use, etc.  Though I am generally a huge fan of both of these technologies, I was tearing my hair out over a particular issue which turned out to be solvable by reading the Go source code.  This coincided with the timing of my weekly blog article.  So here I am sharing my frustration and catharsis with you, dear readers.

# What's the rub?

The rub has to do with the way that Angular sends HTTP POST requests, the way that Golang handles them, and how these two interact.

In AngularJS when we want to perform business logic (for example, calling out to a server to get some data to display ) we put that logic inside of a controller.  The controller sets properties on Angular's `$scope` variable that are accessible from the front end, and vice versa, providing us with two-way data binding.  If you want to make an AJAX call, you inject Angular's `$http` service (by passing it into the function where the controller is defined) and use it.  This is a little bit of a change from what most people are used to, which is usually something like `jQuery.ajax`, but it's not too unfamiliar.  Since Angular likes you to play exclusively in Anglar-land (in controllers at least), they provide you with this service to make sure that no funny business happens to interfere with Angular's apply-digest cycle.  The syntax is fairly straightforward and looks like this:

```js
function MainCtrl($scope, $http) {
	$http.get('/login', {
		username: $scope.user,
		password: $scope.password,
	})
	.success(function(data, status, headers, config) {
		$scope.userLoggedIn = data.isLoginValid;
	})
	.error(function(err, status, headers, config) {
		console.log("Well, this is embarassing.");
	});
}
```

This works extremely well with GET requests, so one would expect it to work equally well with POST requests, right?  Maybe.  I had a use case where I was trying to submit form data through `$http.post` and things were acting extremely funny.  No matter what I tried, it seemed that I could not retrieve anything on the back end, which in this case is written in Go.  

Normally in Go you can just call `request.ParseForm()` in the function that handles HTTP requests for the URI a form gets submitted to, and then the values you are interested in are accessible through `request.FormValue("fieldName")` calls (`request.FormValue` will automatically call `request.ParseForm` for you if needed).  Normally it works smooth as silk- so you can imagine my surprise when I couldn't for the life of me pull data out of the HTTP requests I was POSTing with Angular from my makeshift form.  I even upgraded my Go installation to 1.1.2, and still got nothing.  My code was something along the lines of this:

```
func emailHandler(w http.ResponseWriter, r *http.Request) {
	var err error
	response := map[string]interface{} {
		"success": true,
	}
	err = r.ParseForm()
	if err != nil {
		log.Print("error parsing form ", err)
		response["success"] = false
	}
	name := r.FormValue("yourName")
	email := r.FormValue("yourEmail")
	feedback := r.FormValue("feedback")
	go sendMail(name, email, feedback)
	jsonResponse, err = json.Marshal(response)
	if err != nil {
		log.Print(err)
	}
	w.Write(jsonResponse)
}
```

# So what gives?

Some Googling made me painfully aware that I was not the only one with an issue like this:

- [Angular JS POST request not sending JSON data](http://stackoverflow.com/questions/17547227/angular-js-post-request-not-sending-json-data)
- [How can I make angular.js post data as form data instead of a request payload?](http://stackoverflow.com/questions/11442632/how-can-i-make-angular-js-post-data-as-form-data-instead-of-a-request-payload)
- [How to post application/x-www-form-encoded?](https://groups.google.com/forum/#!msg/angular/5nAedJ1LyO0/4Vj_72EZcDsJ)
- [Make AngularJS $http service behave like jQuery.ajax()](http://victorblog.com/2012/12/20/make-angularjs-http-service-behave-like-jquery-ajax/) (a good blog article detailing this problem)

Most StackOverflow answers suggested modifying stuff in Angular to get this to work (since there's not much you can do about stuff not showing up in `$_POST` in PHP, for example), but this left me dissatisfied.  As Ezekiel Victor points out in the aforementioned blog article:

<blockquote>
	The difference is in how jQuery and AngularJS serialize and transmit the data. Fundamentally, the problem lies with your server language of choice being unable to understand AngularJS’s transmission natively—that’s a darn shame because AngularJS is certainly not doing anything wrong. By default, jQuery transmits data using <code>Content-Type: x-www-form-urlencoded</code> and the familiar <code>foo=bar&baz=moe</code> serialization. AngularJS, however, transmits data using <code>Content-Type: application/json</code> and <code>{ "foo": "bar", "baz": "moe" }</code> JSON serialization, which unfortunately some Web server languages—notably PHP—do not unserialize natively.
</blockquote>

After poring over the documentation for Go's `http.Request` I was still stumped on how to make a basic `$http.post` call work in Go without modifying something on the client side.  `request.Body` didn't seem to have anything useful, and calls to `request.FormValue` were definitely not working.  The server, however, was definitely receiving a JSON payload, as dumping the request made clear (I've removed the `*/*` value from the `Accept` header so the request will play nice with the auto-pretty-printing of my blog):

```
POST /email HTTP/1.1
Host: localhost:8000
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/31.0.1650.57 Safari/537.36
Content-Length: 68
Accept: application/json, text/plain
Accept-Encoding: gzip,deflate,sdch
Accept-Language: en-US,en;q=0.8
Connection: keep-alive
Content-Type: application/json;charset=UTF-8
Origin: http://localhost:8000
Referer: http://localhost:8000/

{"yourName":"John","yourEmail":"John.Smith@gmail.com","feedback":"I really like your new webapp!"}
```

# Let's Go Digging In The request.go Source!

Not being able to receive the values with `request.FormValue` was one thing, but I also could not successfully deserialize the JSON payload into a Go struct- the payload was seemingly nowhere to be found in the `Request` struct provided to my handler.  I could not believe that the Go language designers, who are otherwise very meticulous and reliable, had overlooked something like `Content-Type: application/json` handling.  But checking out the source for `Request.ParseForm` and `Request.parsePostForm` led me to my "aha" moment.  The source for `Request.ParseForm` (from [golang.org](http://golang.org/src/pkg/net/http/request.go?m=text&ModPagespeed=noscript)):

```
// ParseForm parses the raw query from the URL and updates r.Form.
//
// For POST or PUT requests, it also parses the request body as a form and
// put the results into both r.PostForm and r.Form.
// POST and PUT body parameters take precedence over URL query string values
// in r.Form.
//
// If the request Body's size has not already been limited by MaxBytesReader,
// the size is capped at 10MB.
//
// ParseMultipartForm calls ParseForm automatically.
// It is idempotent.
func (r *Request) ParseForm() error {
	var err error
	if r.PostForm == nil {
		if r.Method == "POST" || r.Method == "PUT" {
			r.PostForm, err = parsePostForm(r)
		}
		if r.PostForm == nil {
			r.PostForm = make(url.Values)
		}
	}
	if r.Form == nil {
		if len(r.PostForm) > 0 {
			r.Form = make(url.Values)
			copyValues(r.Form, r.PostForm)
		}
		var newValues url.Values
		if r.URL != nil {
			var e error
			newValues, e = url.ParseQuery(r.URL.RawQuery)
			if err == nil {
				err = e
			}
		}
		if newValues == nil {
			newValues = make(url.Values)
		}
		if r.Form == nil {
			r.Form = newValues
		} else {
			copyValues(r.Form, newValues)
		}
	}
	return err
}
```

The relevant bit for us is that call to `parsePostForm` if `r.Method` is `"POST"` (since it is in our case).  The code for `parsePostForm`:

```
func parsePostForm(r *Request) (vs url.Values, err error) {
	if r.Body == nil {
		err = errors.New("missing form body")
		return
	}
	ct := r.Header.Get("Content-Type")
	ct, _, err = mime.ParseMediaType(ct)
	switch {
	case ct == "application/x-www-form-urlencoded":
		var reader io.Reader = r.Body
		maxFormSize := int64(1<<63 - 1)
		if _, ok := r.Body.(*maxBytesReader); !ok {
			maxFormSize = int64(10 << 20) // 10 MB is a lot of text.
			reader = io.LimitReader(r.Body, maxFormSize+1)
		}
		b, e := ioutil.ReadAll(reader)
		if e != nil {
			if err == nil {
				err = e
			}
			break
		}
		if int64(len(b)) > maxFormSize {
			err = errors.New("http: POST too large")
			return
		}
		vs, e = url.ParseQuery(string(b))
		if err == nil {
			err = e
		}
	case ct == "multipart/form-data":
		// handled by ParseMultipartForm (which is calling us, or should be)
		// TODO(bradfitz): there are too many possible
		// orders to call too many functions here.
		// Clean this up and write more tests.
		// request_test.go contains the start of this,
		// in TestRequestMultipartCallOrder.
	}
	return
}
```

Initially I thought that the source code for this function might need to be modified to add another case to the switch block to handle the case where the content type is `application/json`, but then I had a moment of insight.  

I shouldn't be trying to parse a form at all!  Cue facepalm, and guilt of hours spent solving this issue (at least I'll know better next time).  My request payload wasn't encoded as a form, it was encoded as JSON.  If I just took out the call to `request.ParseForm`, I probably would have usable data in `request.Body` that I could `Demarshal`.  Indeed, this proved to be the case.   

# Conclusion

It seems that the issue in this case was mostly [PEBKAC](http://en.wikipedia.org/wiki/User_error) (naturally).  I think that `ParseForm` is doing the right thing not handling requests with `Content-Type: application/json` in `ParseForm` (since they're not really form submissions), but it would be nice if there were some kind of API to handle this directly from the `Request` (though the JSON deserialization functions provided by `encoding/json` work really well), or this was better documented in some place (partially why I wanted to write this article).  I'd be curious to talk to some of the Go language maintainers about this, and may shoot an e-mail around.  

At any rate, it definitely goes to show that a knowledge of HTTP basics is helpful, as I was equating form submissions with POST requests like a newbie.  Perhaps there's been too much developing for me over this Thanksgiving weekend :)

Originally I monkey patched a fix in Angular's `$httpProvider` config to work around this issue.  However, removing the call to `ParseForm` from my server side code seems to be a much cleaner solution.  Now my Go program can accept Angular POST requests like a charm.

Thanks for reading, and I'll catch you next week.

- Nathan
