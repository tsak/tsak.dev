---
title: How to make Cloudflare Origin certificates work
date: 2024-09-25
image: images/padlock.png
caption: Are you even allowed to talk about SSL without using an image of a padlock?
description: "By installing Cloudflare's Origin Root CA certificate on the origin server"
tags: ['cloudflare', 'tunnel', 'ssl', 'certificate', 'linux']
---

Using a Cloudflare Tunnel and connecting to a local service serving via self-signed certificates forced me to enable
**No TLS verify** in that tunnel's **TLS** settings. _Not ideal!_ Thankfully Cloudflare thought about that and allows
you to [create an origin certificate](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca#deploy-an-origin-ca-certificate). 

For this to work properly, I had to install **Cloudflare's Origin Root CA certificate** on my server running Ubuntu 22.04.5 LTS.

First I [downloaded one of the two origin root CA certificates](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/#cloudflare-origin-ca-root-certificate). I grabbed the
[RSA PEM](https://developers.cloudflare.com/ssl/static/origin_ca_rsa_root.pem).

Then I copied it into `/etc/ssl/certs` and named it `Cloudflare_Origin_CA_RSA_Root.pem`. To refresh the system
certificate store, I ran the following:

```bash
sudo update-ca-certificates --verbose --fresh
```

Somewhere in the output there was this line:

```
link Cloudflare_Origin_CA_RSA_Root.pem -> d947dbd7.0
```

Checking via `curl` (my tunneled origin running on `localhost:8084`):

```bash
$ curl -vs https://localhost:8084
*   Trying 127.0.0.1:8084...
* Connected to localhost (127.0.0.1) port 8084 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* TLSv1.0 (OUT), TLS header, Certificate Status (22):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS header, Certificate Status (22):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS header, Finished (20):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.2 (OUT), TLS header, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use http/1.1
* Server certificate:
*  subject: O=CloudFlare, Inc.; OU=CloudFlare Origin CA; CN=CloudFlare Origin Certificate
*  start date: Sep 24 20:47:00 2024 GMT
*  expire date: Sep 21 20:47:00 2039 GMT
*  subjectAltName does not match localhost
* SSL: no alternative certificate subject name matches target host name 'localhost'
* Closing connection 0
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.3 (OUT), TLS alert, close notify (256):
```

After this part worked, I restarted `cloudflared` on the server:

```bash
sudo systemctl restart cloudflared
```

In the public hostname settings for this endpoint, I could now disable **No TLS verify**. One caveat was that I had
to send the correct **Origin Server Name** or the live logs for the tunnel would show an error about `localhost` not
being recognised by the origin certificate.