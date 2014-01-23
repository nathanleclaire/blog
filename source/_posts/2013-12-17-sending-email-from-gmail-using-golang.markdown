---
layout: post
title: "Sending Email From Gmail Using Golang"
date: 2013-12-17 23:38
comments: true
categories: [Email, Golang, SMTP]
---

As part of the soon-to-be-deployed [checkforbrokenlinks](http://github.com/nathanleclaire/checkforbrokenlinks) app, I found myself faced with the task of creating a contact form that would allow users to send me feedback on the app, so I could improve it and make it better in the future.  In order to do so I had to figure out a way to configure my server-side backend, written in Golang, to perform all of the neccessary steps in order to send me an e-mail from the front-end (written in [AngularJS](http://angularjs.org)).  Looking into it, I don't see too many e-mail sending implementations in Golang available easily online, so I'm putting the results of my research out there for all to see.

{% img /images/golang-gmail/gopher_mail.jpeg A helpful little gopher. %}

# `net/smtp`

Golang provides a `smtp` ([Simple Mail Transfer Protocol](http://golang.org/pkg/net/smtp/)) library as part of its `net` package.  `"net/smtp"` exposes some useful functionality right out of the box.  As it turns out, it's [not too hard]() to connect to [Gmail]() using `net/smtp`, which saved me some serious misgivings I was having about setting up and configuring my own mail server (I've no doubt it could be done, but I was looking for a quick and simple solution).  So I signed up for a [new Gmail account](https://accounts.google.com/SignUp?service=mail&hl=en_us&continue=http%3A%2F%2Fmail.google.com%2Fmail%2F%3Fpc%3Den-ha-na-us-bk&utm_campaign=en&utm_source=en-ha-na-us-bk&utm_medium=ha) and connected to that to send e-mails to my primary address from the Check For Broken Links app form.  As it turns out, doing so with `"net/smtp"` is fairly straightforward.  You call `smtp.PlainAuth` with the proper credentials and domain name, and it returns you back an instance of `smtp.Auth` that you can use to send e-mails.  I use a custom-defined `struct` called `EmailUser` to define the parameters for that call for clarity's sake, and so that I can keep them defined in a configuration file.

This is an example usage:

```
type EmailUser struct {
	Username    string
	Password    string
	EmailServer string
	Port        int
}

emailUser := &EmailUser{'yourGmailUsername', 'password', 'smtp.gmail.com', 587}

auth := smtp.PlainAuth("",
	emailUser.Username,
	emailUser.Password,
	emailUser.EmailServer
)
```

# Templating Mail

Odds are good that you don't want to send identical e-mails all of the time, so I'll walk you through setting up some basic templated e-mails and then show you how to send them using `net/smtp` after we've already connected to Gmail.  When you format an e-mail sent with SMTP correctly, useful information about the sender, subject, and so on will be parsed out of the e-mail's body and interpreted/displayed by the recipients e-mail client in the manner that one would expect.  You can also use more complex template structures to generate e-mails that have more user-specific data, for example if you wanted to send your customers a customized report of their server's bandwidth usage over time via e-mail, or a list of the items they purchased and their invoicing status.

I use a struct called `SmtpTemplateData` to keep track of the basic information for templating the e-mail.  In this case, we know the value of the e-mail body text ahead of time, but we could also run a template for the body template if we wanted to include business-specific logic such as mentioned above.  We import `"text/template"` and `"bytes"`, then:

```
type SmtpTemplateData struct {
	From    string
	To      string
	Subject string
	Body    string
}

const emailTemplate = `From: &#123;&#123;.From&#125;&#125;
To: &#123;&#123;.To}&#125;&#125;
Subject: &#123;&#123;.Subject&#125;&#125;

&#123;&#123;.Body&#125;&#125;

Sincerely,

&#123;&#123;.From&#125;&#125;
`
var err error
var doc bytes.Buffer

context := &SmtpTemplateData{
	"SmtpEmailSender",
	"recipient@domain.com",
	"This is the e-mail subject line!",
	"Hello, this is a test e-mail body."
}
t := template.New("emailTemplate")
t, err = t.Parse(emailTemplate)
if err != nil {
	log.Print("error trying to parse mail template")
}
err = t.Execute(&doc, context)
if err != nil {
	log.Print("error trying to execute mail template")
}
```

Then, you can send mail with `smtp.SendMail`, passing a list of recipients as well as the `bytes.Buffer` buffer for the body of the e-mail:

```
err = smtp.SendMail(emailUser.EmailServer+":"+strconv.Itoa(emailUser.Port), // in our case, "smtp.google.com:587"
	auth,
	emailUser.Username,
	[]string{"nathanleclaire@gmail.com"},
	doc.Bytes())
if err != nil {
	log.Print("ERROR: attempting to send a mail ", err)
}
```

If you want to send e-mails concurrently, or just not block in a HTTP handler, you can encapsulate the above functionality in a function and invoke it with `go sendMail(/* params ... */)`.

# Conclusion

`"net/smtp"` gets the job done, but specifically for the task of sending e-mails from Gmail it takes a little bit of setup.  I may take a whack at making a simple, clean implementation of a library for this purpose (also providing support for boiletplate templating).

Hope this article has been useful and you have a Merry Christmas.  And as always, stay sassy Internet.

- Nathan
