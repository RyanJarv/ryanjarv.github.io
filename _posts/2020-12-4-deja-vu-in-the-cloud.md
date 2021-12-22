---
layout: post
title: Deja Vu in the Cloud
---

{{ page.title }}
================

<p class="meta">04 December 2020 - Somewhere</p>

This is just a page to keep track of slides and notes and links for my talk at converge conference.

You can find the video of it here below, but fair warning, this was my first talk so some of it is a bit difficult to listen to. If you want to get the general idea of it I also have links to slides and related repos/posts.


## Talk

[Youtube link](https://www.youtube.com/watch?v=O9qmPTtHUAg)


[HTML Slides](https://blog.ryanjarv.sh/slides/deja-vu-in-the-cloud/#0)

## Post Talk Notes and Links

Hey all, here's the PoC's/posts for what I went over in the talk in case you want to dig into any of them a bit more.
### Main topics
* cli-hijacker -- [PoC](https://github.com/RyanJarv/cli-hijacker-vagrant)
* User data swap -- [PoC](https://github.com/RyanJarv/UserDataSwap), [blog post](https://blog.ryanjarv.sh/2020/11/27/backdooring-user-data.html), and original [Twitter Post](https://twitter.com/Darkarnium/status/1065600704134475776?s=20) where I got the idea.
* EC2FakeIMDS -- [PoC](https://github.com/RyanJarv/EC2FakeImds) and [blog post](https://blog.ryanjarv.sh/2020/10/19/imds-persistence.html)

### Talking points
* Route53 Authorization -- [Post](https://blog.ryanjarv.sh/2019/05/24/backdooring-route53-with-cross-account-dns.html)
* Supressing Guard Duty notifications when disabling CloudTrail -- [Twitter Post](https://twitter.com/RhinoSecurity/status/1253397992255582208?s=20)
* SSM deny listing bypass -- [Post](https://blog.ryanjarv.sh/2020/10/18/ssm-parameter-store-permissions.html)

I tried to document the PoC repos fairly well, but some info is spread across my blog posts as well. I put these PoC's together kinda at the last second, so some may be more or less reliable than others. Let me know if you have questions about any of them or anything I went over in the talk.

I also have a config rule for detecting 169.254.169.254/32 route changes. I haven't had much time to test it thoroughly but seems to work in my testing so far.
 * [GitHub link](https://github.com/RyanJarv/awsconfig#nondefaultmetadataserver)

The missing API calls graph slide you can find here:
 * [Twitter post](https://twitter.com/Ryan_Jarv/status/1334765133411872768?s=20) (EDIT: Also now in my [uploaded slides](https://blog.ryanjarv.sh/slides/deja-vu-in-the-cloud/#5))

Found that interesting because you can kinda see that it seems AWS making a slight shift to improving existing services.

## Accreditation

* PoC concept's
  * cli-hijacker, EC2FakeIMDS, and Route53 Auth is all original research.
  * [Rhino Security](https://rhinosecuritylabs.com/) for work on suppressing GuardDuty notifications.
  * The idea for UserDataSwap PoC came from [@Darkarnium's](https://twitter.com/Darkarnium?s=20), I just added event machine and lambda for automating it on RunInstance events in the PoC

* Data/Visualizations  
  * For the [API Call block map](https://blog.ryanjarv.sh/slides/deja-vu-in-the-cloud/#3) [@0xdabbad00](https://twitter.com/0xdabbad00?s=20) was kind enough to allow me to reuse my slides.
  * The other graphs, [API Service graph](https://blog.ryanjarv.sh/slides/deja-vu-in-the-cloud/#4) and [API Call graphs](https://blog.ryanjarv.sh/slides/deja-vu-in-the-cloud/#5) I put together from scraping botocore. Links to the scripts used for that data are below.
    * [API Service Graph](https://gist.github.com/RyanJarv/addf4ee61f0d228642cad6b01049d113)
    * [API Call Graph](https://gist.github.com/RyanJarv/f7fdc434b36c3545e006fe6c1eb5c555)
 
