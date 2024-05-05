---
title: Goodbye, GoDaddy
date: 2024-05-05
image: images/goodbye-godaddy.png
caption: Domains with daddy issues, anyone?
description: The straw that broke the camel's back
tags: ['godaddy', 'api', 'enshittification']
---

For the past 15 years, I have been a customer of GoDaddy. The reason _why_ very much eludes me at this point, but I would
be hard-pressed to find anything positive to say about the _dirty old man of domain registrars_, thanks to
[their sexist advertising](https://www.youtube.com/watch?v=dTvYVxO_9N8), their god-awful user experience, their endless
attempts at cross-selling when all you wanted to do was to buy a domain, constantly trying to trick you into multi-year
renewal intervals and all the other controversies which even have their
[own Wikipedia page](https://en.wikipedia.org/wiki/List_of_controversies_involving_GoDaddy).

Guess I just never really had the energy to fully move off of them, and so I kept paying them their inflated domain
registration and renewal fees (I spent almost $2,000 in total over the years) and using their API to keep my domains
pointing at my home IP address. A few years back I discovered [Porkbun](https://porkbun.com/) and started using
them for newly registered domains, and really loved their user experience and no-nonsense approach. In the end, all
I need is a domain registrar that provides DNS services and allows me to
[update my DNS records via an API](https://github.com/qdm12/ddns-updater), should my residential IP address change.

A couple of months ago I transferred most of my secondary domains to Porkbun, a process that was fairly simple and
painless, even though GoDaddy tried its best to make navigating and confirming an ongoing domain transfer as complicated
as possible. Only my main domain remained on GoDaddy, partly due to containing lots of DNS entries for email delivery
and the plethora of `TXT` entries for DKIM, SPF, etc. which I had shied away from moving due to the risk of missing
something in the process. Also, the domain wasn't up for renewal until mid-May.

Yesterday I noticed that one of my subdomains wouldn't work anymore. First I started scrutinising my `nginx`
configuration, scouring log files for any signs of misconfiguration and was dumbfounded when I couldn't spot anything.
Until I checked the logs of the running `ddns-updater` Docker container, noticing authorization errors for the
GoDaddy API.

My first instinct was to create a new API token, assuming the old one simply expired. As this didn't make a difference,
I started searching around for other causes, until I came across
[the real reason](https://www.reddit.com/r/godaddy/comments/1chs1j8/godaddy_access_denied_via_apicall/) my DNS updates
via their API had suddenly stopped working:

> We wanted to inform you that we have recently updated our Domain API requirements. As part of this update, customers
are now required to have 20 or more domains in their account to utilize the API. However, we want to assure you that
you still have access to the OTE API without any blocks.

For a company that somehow prizes itself for its customer support, this was a new low. I had received no warning and
having used their API since 2020, it would have been nice to get at least a heads-up that a requirement such as this
was being introduced. However, I was happy that they had given me the final push to motivate myself to move my last
remaining domain over to Porkbun.

In the end, it took me about ten minutes to release the transfer lock and get a transfer code on GoDaddy's side,
request the transfer on Porkbun, replicate my DNS entries and acknowledge the transfer to finally end up with
nothing left in the GoDaddy account.

Only one thing remaining: Closing the account for good. And of course, even this is infuriatingly hard to find, either
by neglect or malice, I don't know. You need to go to [Account settings](https://sso.godaddy.com/profile/edit) and then
find the drop-down under the **Account Settings** header to find [Contact Preferences](https://sso.godaddy.com/preferences)
that has at the last entry (under the **Privacy** heading):

> **Account**  
> At your request, we will permanently close your account

They didn't have to ask twice. Goodbye, GoDaddy!

![Closing a GoDaddy account](/images/closing-a-godaddy-account.png)