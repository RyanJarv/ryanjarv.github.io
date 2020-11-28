---
layout: post
title: Backdooring User Data
---

{{ page.title }}
================

<p class="meta">27 November 2020 - Somewhere</p>

Previously I did some work around creating fake IMDS servers to serve malicious userdata, you can find more info in my [AWS IMDS Persistence/Priv Escalation](https://blog.ryanjarv.sh/2020/10/19/imds-persistence.html) post. Then just yesterday I came across this post on twitter about [compromising instances via modifying userdata](https://twitter.com/Darkarnium/status/1065600704134475776?s=20). I immediately started to wonder if I had previously come up with a very round about way to do the same thing, this was brief as I started to remember how my fake IMDS scenario works, but either way @Darkarnium's method was compelling enough as an alternative that I decided to try it out.

This approach is much simpler then the Fake IMDS server, enough so I could codify it in about a day. You can find the code on my GitHub under the [UserDataSwap](https://github.com/RyanJarv/UserDataSwap) repo. Once deployed it will automatically root every new instance created in your account (or deployed region, haven't tested how event bus work's there exactly yet). The code itself is harmless and simply run's the following command as root:

```
echo "Hello from malicious user data 4 to $(whoami)" > /msg4
```

When your new instance does come up it will have the original metadata that you deployed it with. We save it before injecting our malicious code and set it back after our code has run.

Because of some limitations around when you can modify user data we end up needing to do a few full boot cycles, once for each time we modify it. This ends up taking about 2 minutes from the RunInstance api command issued to when we can log in to our rooted instance. This also could potentially cause issues depending on the user's exact configuration on startup, since they likely won't be writing their code expecting multiple restarts after initial creation.

I've mentioned this all happens on creation, this is simply because we have an events trigger for the RunInstance API call triggering our lambda. This code could be run against any powered on machine, which may be better in some cases.

Below are the permissions needed (beyond what's normally used for lambda):

```
{
    "Statement": [
        {
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StartInstances",
                "ec2:DescribeInstanceAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:StopInstances"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Sid": "ModifyInstanceAttribute"
        }
    ]
}
```

I'll expand on this in the future but in brief the differences from this method vs the [IMDS Persistence/Priv Escalation](https://blog.ryanjarv.sh/2020/10/19/imds-persistence.html) one is:
* IMDS requires both less privileges and less obvious privileges
* IMDS takes about a minute less to login
* IMDS run's before the original metadata and doesn't require any restarts  
* UserSwap can target individual instances
  * IMDS currently needs to target the whole subnet, potentially breaking IMDS for other instances for about 30 seconds
* UserSwap is much simpler
  * Only requires a single lambda function, as opposed to IMDS's lambda function and attacker controlled EC2 node
