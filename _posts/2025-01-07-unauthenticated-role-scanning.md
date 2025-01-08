---
layout: post
title: Fast Unauthenticated Role Scanning 
---

{{ page.title }}
================

<p class="meta">7 Jan 2025 - NW</p>

Just a quick blog post here, recently I've been trying to open source some of my projects. One of these was the GoLang 
tool [roles](https://github.com/RyanJarv/roles/blob/main/README.md) for unauthenticated role scanning.

The other well known tool for scanning unauthenticated principals was [quiet-riot](https://github.com/righteousgambit/quiet-riot)
which was able to achieve about over 1,200 reqs/sec using python. Despite being able to achieve this throughput, it is 
written in python, which despite it's simplicity tends to be difficult to code high performance code in. This got me
a bit curious about what the upper limit might be for a similar tool written in GoLang, which tends to be surprisingly 
easy to write fast highly-concurrent code with.

Originally, [roles](https://github.com/RyanJarv/roles/blob/main/README.md) wasn't intended to be fast, I really worked
on it because I wanted a few features like caching and variable interpolation in role names, and secondly I often find it
a bit easier to hack on a purpose made tool I built myself then use a more generic one already available that supports
features I may not need at the moment.

I started on improving the speed of enumeration by ensuring setup and enumeration where ran as separate steps. The setup
process is ran by passing `-setup` and enables all available regions and pre-creates the resources needed by each thread
later for enumeration. I added a [plugin interface](https://github.com/RyanJarv/roles/blob/aab41f059c761049a057fd04efe40da768efbae1/pkg/plugins/types.go#L10)
and [documented it](https://github.com/RyanJarv/roles/tree/main?tab=readme-ov-file#plugins) so that ChatGPT could create
new methods of enumeration in case I ended up hitting account limits on a specific API call. However, the key thing here
was running a few goroutines for each plugin, in each region.

With this I was able to hit about 2000 reqs/second per second, considering [quiet-riot](https://github.com/righteousgambit/quiet-riot) 
was getting 1200 reqs/second across twenty accounts this seemed pretty good. 

Next, I registered an org account and started adding the `-org` setup mode. This enabled AWS Organizations in the 
account, created as many sub-accounts as allowed, and ran the account level setup on each. By default, you can only
create 9 sub-accounts, so along with the root account the organization mode used 10 accounts in a similar setup as 
before, and not-surprisingly got approximately 10 times the throughput for a total of 20k reqs/second.

These tests weren't perfect, the stats code was originally broken, and out of a bit of caution I ended up disabling 
three of the five plugins and reducing the concurrency during the org testing to 1/5th the optimal account settings. 
It's actually a bit surprising it worked out to just about 10 times after adjusting for the broken stats code. In any
case, it seems scanning at 20k roles/second for short durations (up to 20 seconds) is possible.

One question I still have though is how API limiting works on these API actions, if they use a token bucket rate 
limiter these short duration tests may not mean that much since the bucket is usually refilled slowly over some duration
of time. Either way, I thought this was interesting and wanted to share the results even if it wasn't exactly a 
completely accurate benchmark.


## Roles Tool

If you want to use the tool you can find it on my GitHub [here](https://github.com/RyanJarv/roles), however it's 
currently rate-limited to a maximum of 50 requests per second, and the org mode is not supported at the moment. Using 
the APIs in this way is a bit of a corner case, and while it's important to know what's possible, it may be in your
best interest to avoid going much faster than these limits for an extended period of time.

Anyway, the tool also supports caching and account ID and region interpolation. At some point I'd like to support more
advanced wordlist options, if you're interested in working on that feel free to ping me or open a PR!



