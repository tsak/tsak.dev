---
title: My first beg bounty
date: 2023-11-13
image: images/spf.png
caption: Is the web even safe at SPF15?
description: 'When SPF does not mean sun protection factor'
tags: ['spf', 'beg', 'bounty', 'security']
---

This morning, still a bit sleepy, morning coffee in hand, I came across a Hacker News post about
[Beg Bounties](https://www.troyhunt.com/beg-bounties/). Intrigued by the title, having heard about _Bug_ Bounties
before, I learned about its next logical conclusion and the people that "randomly" discover security vulnerabilities
and then expect to be paid for their "ethical disclosure".

Putting this aside as a _Today I Learned_ kind of thing, I logged into my work email, only to be greeted by one of
such "disclosures", aimed at my employer and subsequently becoming my problem. Formatting exactly as sent, sender and
my employer's `$domain` redacted.

> **From:** `Random Security Researcher <[redacted]@gmail.com>`  
> **Date:** Mon, 13 Nov 2023 09:12:19 +0100  
> **Subject:** Vulnerability Report(Invalid SPF Record)  
> <br>
> Hey Team,<br>
> <br>
> I hope this email finds you well. I am reaching out to you as a security researcher to report a vulnerability
> related$domain to your website, .
> 
> ### Description:
> This report is about a misconfigured SPF (Sender Policy Framework) record flag, which can be used to abuse the
> organization's identity. This allows sending fake emails by a malicious actor on behalf of your organization.
> 
> ### About the Issue:
> As I have seen the SPF and TXT record for $domain:
> 
> `v=spf1 include:_spf.google.com ?all`
> 
> As you can see, the symbol at the end, which is a question mark (`?all`), is the issue. It indicates a neutral or no
> policy, which means that nothing can be said about validity. This should be replaced with a hyphen (`-all`) symbol.<br>
> <br>
> So, a valid record should look like:  
> `v=spf1 mx -all`
> 
> ### Issue:
> As you can see in the article explaining the difference between a no policy statement (`?all`) and a fail policy
> statement, you should be using fail. A no policy statement allows anyone to send spoofed emails from your domains.<br>
> <br>
> In the current SPF record, you should replace the question mark (`?`) with a hyphen (`-`) at the end before all.
> The hyphen is strict and prevents all spoofed emails except those sent by authorized sources.
> 
> ### Attack Scenario:
> An attacker will send phishing emails or any malicious mail to the victim via the email address `info@$domain`. Even if
> the victim is aware of a phishing attack, they may check the origin email, which will be `info@$domain`. This can lead
> to the victim being trapped by the attacker. This can be done using any PHP mailer tool, like the following:
> 
> ```php
> <?php
> $to = "VICTIM@example.com";
> $subject = "Password Change";
> $txt = "Change your password by visiting here - [Malicious link here]";
> $headers = "From: info@$domain";
> mail($to, $subject, $txt, $headers);
> ?>
> ```
> 
> This is a screenshot of an email that I have been able to send to my account using your domain.<br>
> <br>
> `[Gmail screenshot showing the sender as info@$domain via turbo-smtp.info]`<br>
> <br>
> You can check your SPF record [here](http://www.kitterman.com/spf/validate.html)!
> 
> ### Reference:
> - [DigitalOcean article](https://www.digitalocean.com/community/tutorials/how-to-use-an-spf-record-to-prevent-spoofing-improve-e-mail-reliability) - provides a better understanding of SPF records.
> 
> Waiting for your response and hoping for a bounty reward for responsibly disclosing this issue to your website.
> Furthermore, I may attempt to contact you again if I do not receive a response to ensure that my message has reached
> you.<br>
> <br>
> Regards,<br>
> Random Security Researcher

My colleague who had originally received the email wasn't sure if the email was classified as SPAM (his first assumption)
or if it was a genuine email, and then decided to forward it to me. I would have probably read the email a bit differently
if I hadn't read that article about beg bounties first thing in the morning. Especially grating in my opinion was the bit
at the end about _"hoping for a bounty reward"_ and the thinly veiled threat to keep contacting us if we would not respond.

Searching for that Random Security Researcher's name, netted me a deleted Google Groups discussion where he was a bit
more forthright and asking a little less subtly: _"Hoping to receive $bounty for responsible reporting of the bug."_

The annoying thing of course was that they were not wrong and our SPF record needed fixing as it was unfortunately copied
from a previous host and email setup of our main domain. We never scrutinised the record, given that we must have taken its
blueprint directly from the [documentation](https://docs.gandi.net/en/gandimail/common_operations/enable_antispoofing_tools.html)
of a large domain registrar.

So on one hand I was grateful for having been told about a potential problem with our SPF records, but on the other hand,
I was quite miffed about the pretend _responsible disclosure_ and the outstretched hand that came along with it. As Chester Wisniewski
from Sophos [put it](https://news.sophos.com/en-us/2021/02/08/have-a-domain-name-beg-bounty-hunters-may-be-on-their-way/?ref=troyhunt.com):

> If you receive one of these emails it is worth taking seriously, as you likely have a very poor security posture,
> **but you should not engage with the person soliciting your business.**

Not too long ago, I had ordered some clothes for my daughters from an online store and that small retailers' emails
always ended up in my SPAM folder with a *scary-sounding* security warning by GMail. So I ran their emails through
[mxtoolbox.com](https://mxtoolbox.com/Public/Tools/EmailHeaders.aspx)' header analyzer and forwarded an explanation
of their issue to them. They were very grateful and offered me a token of appreciation in the form of a gift for my
children which my daughters were very happy about.

I really appreciated the gesture, but in the end did not expect anything in return, as I believe that helping others
is its own reward.
