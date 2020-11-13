---
layout: post
<<<<<<< HEAD
title: Cross Cloud Lambda RPC
=======
title: Inherit Cross Cloud Provider Trust
>>>>>>> 4d7ac76 (Add lambda rpc post)
---

{{ page.title }}
================

<p class="meta">2 November 2020 - Somewhere</p>

Recently I've had this idea stuck in my head revolving around something of a cross cloud platform RPC library for lambda. Now I don't really have a need for this but, none the less I can't get it out of my head so I keep coming back to it. I also keep getting stuck in the same place, so going to try to write down my thoughts here instead for now.

When most people think multi-cloud they focus on common limiting to resources, potentially building another cloud across them wth Kubernetes and most likely a service mesh. I feel like this approach, at the FaaS layer, could achieve the same goal for certain workloads in a much simpler way.

For this to make sense though I felt I needed to these goals:

* Simple
* Don't handle networking
* No infrastructure
* Secure

<div style="width: 640px; height: 480px; margin: 10px; position: relative;"><iframe allowfullscreen frameborder="0" style="width:640px; height:480px" src="https://app.lucidchart.com/documents/embeddedchart/a2c9824c-123c-4a3c-9ce8-a4f16b9de133" id="ReIK-GaHiRGH"></iframe></div>


Here we have just a library that sit's on top of the native cloud SDK's, add's a http like addressing scheme and translates those http call's to the underlying SDK's method of calling functions. It's stupid really, but it does what we want.

The obvious problem here is how do we handle authentication and authorization, basically bootstrapping these functions.

This is where I'm stuck on this right now because for whatever reason I have an aversion to SAML and OpenID.. something about repressed memories or whatever. I keep trying come up with some other clever way of getting the right token's in the right place's in a secure/simple to understand way, but so far haven't come up with anything.

Anyways thinking over this I suspect I just need to get over my fears of SAML, OpenID, etc and see if I can sort this out that way. I'll probably be setting this aside for now but if you have any thoughts on what would work here though let me know (@ryan_jarv on twitter).
