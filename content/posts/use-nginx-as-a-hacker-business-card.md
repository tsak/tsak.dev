---
title: Use nginx as a hacker business card
date: 2022-09-13
image: images/curl-tsak.dev.png
description: Return directive for the win
tags: ['nginx', 'curl', 'business-card']
---

A [friend of mine](https://martincarlin.uk/) recently showed me his curl-able business card inspired by this 
[Cloudflare worker template](https://github.com/Gaafar/curl-worker).

I liked the idea of returning something similar when running `curl tsak.net`, but using Cloudflare
workers or any other complicated stack for that matter felt a bit like overkill to me. After all, I'm
hosting my blog at home, using nginx.

Nginx supports a [return](http://nginx.org/en/docs/http/ngx_http_rewrite_module.html#return) directive that
allows you to specify a response code and a URL or alternatively the content you would like to return.

So in [my blog's nginx config](https://gist.github.com/tsak/fb99c478ab3887768090c130cbcb5552),
I include the following config (note the `\n` to insert line-breaks):

```
if ($http_user_agent ~ "^(curl|HTTPie)") {
        return 200 "\n  ▀█▀ █▀ ▄▀█ █▄▀ ░ █▀▄ █▀▀ █░█\n  ░█░ ▄█ █▀█ █░█ ▄ █▄▀ ██▄ ▀▄▀\n\n  satan's hackathon boilerplate\n  shitpit co-lead developer\n\n  Blog: https://tsak.dev\n  Github: https://github.com/tsak\n\n";
}
```

I'm including this twice, once in the SSL-enabled server block and again in the HTTP-only server block that
by default redirects any requests to the SSL encrypted version of the site, unless you're hitting it via
curl or HTTPie.

```
$ curl tsak.net

  ▀█▀ █▀ ▄▀█ █▄▀ ░ █▀▄ █▀▀ █░█
  ░█░ ▄█ █▀█ █░█ ▄ █▄▀ ██▄ ▀▄▀

  satan's hackathon boilerplate
  shitpit co-lead developer

  Blog: https://tsak.dev
  Github: https://github.com/tsak
```

**Update:** Having since moved my blog to Cloudflare Pages, I've moved the curl-goodness to `tsak.net`.
Examples have been amended, but the screenshot and response stay the same.