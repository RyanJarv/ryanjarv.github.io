---
layout: post
title: This one weird trick to bypass IP filtering
---

{{ page.title }}
================

<p class="meta">08 Feb 2020 - Somewhere</p>
Like all of my favorite exploits this one is stupid and simple. In an ideal world we wouldn't ever whitelist IP's, especially by itself for access to privileged API's, but it happens, unfortunately.

```
curl -H 'X-Forwarded-For: 127.0.0.1' example.com
```


I'm sure many people that will be reading this will understand what's going on here so I'm mostly going to talk about why I think confusion around how X-Forwarded-For works is a more common issue then you would expect. If you want to get an idea of what's going on here and how to prevent it I'll post more info at the end of this post.

The situation is we couldn't think of a better way to identify a client then the IP address. I mean it's not like localhost is routable or anything so we should be fine right? Or maybe less unreasonable, we just need to rate limit connections from badly behaved IPs. We could also need privileged access for remote hosts and simply not have enough time to implement this correctly. Gaining control of a specific IP seems like a high enough barrier for our use case, we have other things to do anyways...

Honestly some of these use cases are hard to argue against. For the average company you usually have other more worrisome things to think about anyways, and so it gets implemented this way and everyone forgets about it.

Some time later the cluster of app nodes isn't scaling as well as you hoped and you decide you need to throw a cache or CDN in front of it all. Simple, just make a free CloudFlare account, point it to your LB and reconfigure DNS. Now with out realizing it you've now allowed anyone to impersonate any IP and the original whitelisting idea that didn't seem so bad is a bid scarier.

(does cloudflare block X-Forwarded-For? I think so unless this has changed recently, need to check this.)

Ok that's fine, we got lucky and realized this is an issue. Let's just block X-Forwarded-For at the edge. That's done and everything is secure now right?

Not necessarily. If you are using [ngx_http_realip_module](https://nginx.org/en/docs/http/ngx_http_realip_module.html) and didn't set `set_real_ip_from` correctly and are not blocking origins other then your CDN then anyone can find the backend IP then X-Forwarded-For isn't being blocked.

```
curl -H 'X-Forwarded-For: 127.0.0.1' -H 'Host: example.com' <backend ip>
```

So specifically in this example case `real_ip_header` is being used along side `real_ip_recursive` set to on (won't get the right IP otherwise) and no `set_real_ip_from` and/or a simple varnish configuration is set that prepends the real IP to the list of X-Forwarded-For before forwarding the request along. If you are reading the X-Forwarded-For header directly this is almost certainly an issue as well.

To fix this you either need to explicitly block all traffic not coming from where X-Forwarded-For is filtered, or make sure to keep track of all trusted CDN/Cache IPs and set them as the last trusted hop when appending to X-Forwarded-For. Both of these, at least in the case of using CloudFlare means pulling edge IPs and dynamically updating nginx/varnish configuration, which isn't exactly ideal.

In the case code is reading X-Forwarded-For directly you want to start at the right most IP address in the list, if it falls in the range of a proxy that you control then throw it away and grab the next one until you find an un-trusted IP. The first un-trusted IP will be what you want to use as the client's real IP.

The reason I think this is a commonly overlooked issue is because support for X-Forwarded-For can be done either on the dev or ops side of things, requires a strong understanding of how the infrastructure is set up to catch, and it often isn't clear how and when the client's IP is actually being used by the app. The problem isn't talked about often and there is no warning about this in relevant documentation ([realip_module](https://nginx.org/en/docs/http/ngx_http_realip_module.html) but there's plenty of other cases as well, maybe I need to make a PR for this). Even if you do know about this issue the seemingly obvious fixes (blocking X-Forwarded-For) are only partially effective. So there's a lot of things going on here that make this easy to miss.


(this post is mostly from memory right now. will update and be adding more to this soon once I dig into it again)
