---
title: Using nginx to secure hidden content with a bit of cookie magic
date: 2024-09-28
image: images/a-single-cookie.png
caption: Fish shaped cookies, anyone?
description: 'All it takes is a secret location, a cookie and the ngx_http_geo_module to make it happen'
tags: ['linux', 'nginx', 'security-through-obscurity', 'cookies']
---

Sometimes I host things that I don't want to be readily available on the open internet (or at least not easy
to discover). It might be something that could do with an extra layer of obscurity. It might be a piece of third-party
software to which I have no good insight into its security posture.

Below is a neat trick to achieve this with a bit of [nginx](https://nginx.org/en/) configuration magic alone, by
"misusing" the `ngx_http_geo_module`. Requests other than the secret location to
[open sesame](https://en.wikipedia.org/wiki/Open_sesame) will be rejected unless either the secret cookie is
part of the request headers, or a request is coming from a trusted network.

Hitting [secret.tsak.dev](https://secret.tsak.dev/) will return a `401 Unauthorized` at first.

But going to [secret.tsak.dev/open-sesame](https://secret.tsak.dev/open-sesame) first sets a cookie with the value of
`alibaba=fortythieves`. If this cookie is found in the request to the site, its secret content is served instead.

Of course, instead of going with `alibaba=fortythieves` one should randomize both sides of the key/value pair. Also,
the URL to set the secret cookie should be randomised.

```nginx
# Set allowed to 0 unless request is coming from my home network
geo $allowed {
        default 0;
        192.168.1.0/24 1;
}

server {
        server_name secret.tsak.dev;

        # Navigating to this location will set the secret cookie
        location /open-sesame {
                add_header Set-Cookie 'alibaba=fortythieves; Path=/; HttpOnly; Secure';
                return 302 /;
        }

        # If secret cookie is set, set allowed to 1
        if ($http_cookie ~* "alibaba=fortythieves") {
                set $allowed 1;
        }

        location / {
        # If request is neither coming from trusted network or cookie is set, return 499
                # If not behind a gateway, I would return 499
                if ($allowed = 0) { return 401; }
                root /home/htdocs/secret.tsak.dev;
        }
}
```

You can make this even more fun and return a status of `499` also known as "client closed request", but my example
host runs behind a gateway that does not forward this status code and returns a `502` status instead.