---
layout: post
title: Abusing the AWS SDK
---

{{ page.title }}
================

<p class="meta">17 October 2020 - Somewhere</p>
A bit ago I noticed a SYN open connection from what was most likely the AWS SDK trying to connect to the IMDS service. I must have been a bit bored at the time and decided to look into how this could be abused in various scenarios. After some messing around I came up with a fairly simple PoC that allows an attacker on the local network under specific conditions to gain plain text secrets uploaded using SSM parameter store. My take away from looking into this further is if you use multiple named profiles in your config/credentials file it's a good idea to either put dummy creds in the default profile and/or make sure AWS_EC2_METADATA_DISABLED=true is set in your shell environment. In general the issue sounds worse than it is, but given the the right conditions, enough patience by the attacker, or a bit of luck the potential for damage is there.

This issue ended up affecting me by default since I've gotten in the habit of never setting a default profile to avoid accidentally connecting to the wrong account. It seems I'm not the only person that does this either, found a few people suggesting the same thing.

Including these links just to show it's not all that uncommon to set your config up this way. If it wasn't for this IMDS gotcha this would actually a very smart thing to do.

* [multiple-aws-profiles](https://mads-hartmann.com/2017/04/27/multiple-aws-profiles.html#dont-have-a-default-profile)
* [short-how2tips-aws-using-multiple-profiles](https://knplabs.com/en/blog/short-how2tips-aws-using-multiple-profiles)
* [stackoverflow comment](https://stackoverflow.com/a/37866692)

When you perform any action the AWS SDK makes a lookup to the IMDS server if you didn't specify a profile and it can't find the credentials locally. Usually this tends to result in a long delay before the API call fails.

What is actually happening here depends on your local routing configuration for the link local address range (169.254.0.0/16). For example on my MacBook Pro running 10.15 I have the following in my route table.


```
169.254            link#6             UCS            en0      !
224.0.0/4          link#6             UmCS           en0      !
224.0.0.251        XX:XX:XX:XX:XX:XX  UHmLWI         en0       
255.255.255.255/32 link#6             UCS            en0
```

This means when I am running `aws s3 ls` with no default profile set we can see that the OS attempts to look for the IMDS server on the local network.


```
% tcpdump -i any host 169.254.169.254
tcpdump: data link type PKTAP
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on any, link-type PKTAP (Apple DLT_PKTAP), capture size 262144 bytes
23:29:36.631710 ARP, Request who-has 169.254.169.254 tell 10.0.1.105, length 28
23:29:37.635852 ARP, Request who-has 169.254.169.254 tell 10.0.1.105, length 28
```


Eventually the AWS SDK will timeout and we'll get this familiar error. 

```
Unable to locate credentials. You can configure credentials by running "aws configure".
```

For fun you can also search through GitHub Issues [relating to this error](https://github.com/search?q=%27Unable+to+locate+credentials.+You+can+configure+credentials+by+running+%22aws+configure%22.%27&type=issues).

Thinking about this from an attacker's viewpoint who already has access to the local subnet we can do a few things by simply claiming that IP as our own. The simplest being scraping the AWS SDK version of user's on the local network. Worth noting the error on the victims side remains the same as above.


```
(h@x0r) % ifconfig lo0 add 169.254.169.254
(h@x0r) % nc -lk 169.254.169.254 80

## Meanwhile we wait for someone to accidentally trigger an IMDS lookup.

PUT /latest/api/token HTTP/1.1
Host: 169.254.169.254
Accept-Encoding: identity
x-aws-ec2-metadata-token-ttl-seconds: 21600
User-Agent: aws-cli/2.0.50 Python/3.8.5 Darwin/19.6.0 source/x86_64
Content-Length: 0

GET /latest/meta-data/iam/security-credentials/ HTTP/1.1
Host: 169.254.169.254
Accept-Encoding: identity
User-Agent: aws-cli/2.0.50 Python/3.8.5 Darwin/19.6.0 source/x86_64
```

Taking this a step further we can actually serve the victim another set of credentials of our choosing which will cause the SDK to connect to an account we control. For this to be useful to us the API called by the victim must use relative naming schemes for parameters (i.e. no ARN's) as well as upload sensitive info. One that fit's this description is the SSM parameter PutParameter call.


Testing this out is fairly simple. Here we're doing the same thing as before but using aws-vault's server feature to feed back credentials to the victim. Typically aws-vault will only bind on localhost but we can force it to skip this step by adding the 169.254.169.254 IP beforehand.


```
(h@x0r) % ifconfig lo0 add 169.254.169.254
(h@x0r) % aws-vault exec -s attackers-account
```


If the victim run's STS GetCallerIdentity and happens to trigger an IMDS lookup they will be connected to the attacker's account. Uploading a secret using SSM PutParameter at this point will end up pushing it to the wrong account, allowing it to be viewed by the attacker in plaintext.

This would be a not so great situation, but to reiterate, getting to this point requires both the IMDS lookup to be triggered when it shouldn't have, as well as the victim running an API call that is susceptible to this. Unless you are able to determine through some other means what API call a client is going to make and when they will most likely notice something is not right, the tool they are using will fail or behave strangely.

Personally though I think this could use more eye's looking into how feasible this attack might be. For example it may be worth looking into what would happen if ARN's are constructed from the STS GetCallerIdentity call, something that is fairly common when running terraform. If there is any situations where an attacker might have access to the running process list or tracing privileges to the running app then this may be more effective as well.

One last thing to note is for OS's that send 169.254.169.254 to the default route the same situation comes up further upstream, allowing an attacker in a privileged position on the network to do the same thing across multiple subnets. Link local addresses in theory should be filtered, so *hopefully* outside of any network misconfigurations this wouldn't come up.

If you have any thought’s on how this might more effectively be abused I encourage you to reach out to either me (me@ryanjarv.sh) or [AWS security](https://aws.amazon.com/security/vulnerability-reporting/).

