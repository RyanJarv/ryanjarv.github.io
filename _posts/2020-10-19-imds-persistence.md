---
layout: post
title: AWS IMDS Persistence/Priv Escalation
---

{{ page.title }}
================

<p class="meta">19 October 2020 - Somewhere</p>
A little known feature of EC2 is it's possible to override the IMDS endpoint used by instances in EC2 by specifically using a 32 bit netmask on the 169.254.169.254 route.

Additionally the magical IP of 169.254.169.254 has some interesting properties:

* Security group rules are ignored for 169.254.169.254
  * https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Security.html (search: `don't filter traffic`)
* Traffic mirroring does not capture traffic for 169.254.169.254
  * https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ug.pdf (search: `not logged:`) 

If you think of AWS as very large, always on computer you can kinda throw together something along the line's of cloud based malware. Below is a link to a diagram of what this may look like.

[IMDS Persistence/Priv Escalation Diagram](https://app.lucidchart.com/lucidchart/4c4c146d-e9c5-4bae-9553-9c65b37aad7a/view?page=0_0#?folder_id=home&browser=icon)

The PoC I put together for this ended up being seamless in my limited testing, added about a minute to the boot time to root it, and then executed the normal user-data as expected on re-init. Since the modified route table applies to all instances in a given subnet this may be more noisy in practice though.

Think the take away here is to restrict access to routing table related API's and to monitor or possibly alert on any changes.
