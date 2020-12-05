---
layout: post
title: Deja Vu in the Cloud
---

{{ page.title }}
================

<p class="meta">04 December 2020 - Somewhere</p>

This is just a page to keep track of slides and notes and links for my talk at converge conference.

You can find the video of it here below, but fair warning, this was really my first talk so some of it is a bit difficult to listen to. If you want to get the general idea of it I also have links to slides and and related repos/posts.


## Talk

[Youtube link](https://www.youtube.com/watch?v=O9qmPTtHUAg)
[HTML Slides](https://blog.ryanjarv.sh/slides/deja-vu-in-the-cloud/#0)

## Notes and links

Hey all, here's the PoC's/posts for what I went over in the talk in case you want to dig into any of them a bit more.
* cli-hijacker
    * [Poc](https://github.com/RyanJarv/cli-hijacker-vagrant)
* User data swap
    * [Poc](https://github.com/RyanJarv/UserDataSwap)
    * [Post](https://blog.ryanjarv.sh/2020/11/27/backdooring-user-data.html)
* EC2FakeIMDS
    * [PoC](https://github.com/RyanJarv/EC2FakeImds)
    * [Post](https://blog.ryanjarv.sh/2020/10/19/imds-persistence.html)
* Route53 Authorization
    * [Post](https://blog.ryanjarv.sh/2019/05/24/backdooring-route53-with-cross-account-dns.html)

I tried to document the PoC repos fairly well, but some info is spread across my blog posts as well. I put these PoC's together kinda at the last second, so some may be more or less reliable then others. Let me know if you have questions about any of them, or anything I went over in the talk.

I also have a config rule for detecting 169.254.169.254/32 route changes. I haven't had much time to test it thoroughly, but seems to work in my testing so far.
 * [GitHub link](https://github.com/RyanJarv/awsconfig#nondefaultmetadataserver)

The missing API calls graph slide you can find here:
 * [Twitter post](https://twitter.com/Ryan_Jarv/status/1334765133411872768?s=20)

Found that interesting because you can kinda see that it seems AWS making a slight shift to improving existing services.

