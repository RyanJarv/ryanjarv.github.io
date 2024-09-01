---
layout: category
title: Implicit SAR -- Summary
category: sar
permalink: /:categories/:title:output_ext
post_number: 7
---

{{ page.title }}
================

<p class="meta">30 Aug 2024</p>

## Introduction

I'd like to end the Implicit SAR series with a critical assessment of what we've covered so far by answering a few withstanding questions directly. I'll keep things shorter and to the point here but if you're just jumping and feel you missed something you can find an introduction to the Implicit SAR series [here](sar-1-self-assume-role-overview.html).

I'll start this post with a quick review of the attack's we've covered so far that Implicit SAR enabled.

## Summaries

### Bypassing Session Expirations and Revocations ([link](sar-4-bypassing-session-expirations-and-revocations.html))

Nearly all high-privilege IAM roles were unexpectedly able to bypass session expirations and revocations until detection or role deletion.  

### Unexpectedly Modifying Session State ([link](sar-5-modifying-session-state.html))

IAM Role session state which was expected to be invariant in certain IAM deployments could be modified by an attacker when a role is affected by Implicit SAR. This may result in the ability to escalate privileges or misattribute logs made by the attacker to another user. 

### Attacking the Confused Deputy ([link](sar-6-confused-deputy.html))

This can be broken up into two separate attacks:

1. Implicit SAR allowed an unauthenticated attacker to gain access to the IAM Role used by a SaaS provider for accessing customer environments when this role did not explicitly deny `sts:AssumeRole` access to itself. This cross-account role could be used 
through the capabilities of the SaaS platform, restricted by the combination of permissions on the role and the resource policies in the account.

2. Depending on the features of the SaaS platform this may result in unrestricted access to customer's AWS accounts using existing IAM role trusts.

## On Undocumented Behavior in IAM

In the previous posts, I didn't touch on the fact this was an undocumented behavior, so I'd like to make sure that's clear here.

Implicit SAR was an undocumented feature of IAM in that the documentation implied it should not work, and that no tooling available at the time indicated it was a possibility:

* Access Analyzer is intended to analyze external access. 
  * Note: It does allow limited testing through new [accessanalyzer:CheckAccessNotGranted](https://aws.amazon.com/blogs/security/introducing-iam-access-analyzer-custom-policy-checks/) API call, however this API did not exist before November 2023 and more importantly simply isn't flexible enough to provide the conditions required for Implicit SAR to be possible.
* IAM policy simulator also does not support the requirements necessary to test for the Implicit SAR behavior because "[Simulation of resource-based policies isn't supported for IAM roles](https://docs.aws.amazon.com/IAM/latest/APIReference/API_SimulateCustomPolicy.html#API_SimulateCustomPolicy_RequestParameters)".
  * Despite this limitation IAM policy simlulator does let you use it in this way, however, due to the nature of IAM roles the answer can not be relied on as accurate.

Back in 2019, [Houston Hopkins](https://x.com/hhopk) also discovered Implicit SAR and identified it as a potential bypass for the data perimeter controls built to protect against attacks similar to the 2019 Capital One breach. This behavior was identified as a method to convert instance roles into regular assume role credentials, which in turn, allowed bypassing SCPs which restricted the use of EC2 Instance Profile credentials. The behavior was reported to the IAM/STS team, and he was told Implicit SAR was an "undocumented feature" that worked by design.

This surprised me when I learned this because this is an incident that made it clear the importance of this specific control, yet it wasn't until several years later when I accidentally stumbled on Implicit SAR while working on [liquidswards](http://github.com/RyanJarv/liquidswards) and intended to disclose the behavior at fwd:CloudSec 2022, that action was taken by AWS.

However, regardless of the exact reasoning behind this being addressed in 2022, what concerns me more is that it shouldn't be the responsibility of customers to rediscover undocumented behavior when that behavior is known to have unintended side effects on security. Furthermore, undocumented behavior like this in IAM, which is either known internally or where the documentation implies a deny but the result is an allow, simply should not be a problem.

I don't think this is very controversial, so I'm hoping AWS can comment on whether this will be considered a bug internally, rather than a feature, in the future.

## Was Implicit SAR a vulnerability?

Yes, or more specifically it can be considered the root cause of several different vulnerabilities.

The fact is, we ultimately rely on accurate and transparent documentation of AWS to build secure infrastructure. Because Implicit SAR was both unintuitive and undocumented, customers had no reasonable ability to protect themselves against or detect the attacks I covered previously.

## Is Self Assume Role Still Possible?

Yes. If you use the console to create a role to be assumed by an AWS account and use the default 'this account' option, then the trust policy will list the account itself, and so any principal in the account (including the role in question) that has sts:AssumeRole privileges can assume the role. This can have similar behavior in some of the scenarios previously covered, but it is fundamentally different in that Implicit SAR was both unexpected and undocumented.

## Attacking the Confused Deputy

Personally, I have some ongoing concerns about the last attack I covered which I'll cover here along with a few clarifications to my previous post.

### Were Service Providers that Implemented `sts:ExternalID` Protected from Attacking the Confused Deputy? 

No, `sts:ExternalID` has no effect in this situation for two reasons:

First, calling `sts:AssumeRole` with `sts:ExternalID` set on a role that does not require will not cause the AssumeRole attempt to fail.

But, more specifically, even in the cases where `sts:ExternalID` is required on the SaaS provider's role, for example, if they are dogfooding their own product. The `sts:ExternalID` requirement would have been ignored during the Implicit SAR evaluation.

### How likely was the Attacking the Confused Deputy scenario? 

I believe it's fairly easy for us to reason that many SaaS providers that used IAM roles were likely affected in some form, however to what degree, or whether this had a material risk on customers is difficult to answer. 

This is based on the observation that SaaS providers will need to use `"sts:AssumeRole": "*"` to avoid IAM policy size limits as well as avoid updating the IAM policy each time a new customer is onboarded. Secondly, as covered above, AWS made no indication the behavior required to exploit this existed before September 2022.

The primary blocker for this attack I believe comes down to whether the platform soft or hard fails on partial access, and whether, access in the same account or organization was denied or not. However, on the second point, how many SaaS providers take this arguably unnecessary pre-caution is uncertain. I've never come across any public documentation or blog posts encouraging SaaS providers to explicitly deny same-account access before my mention of it in [Attacking the Confused Deputy](https://blog.ryanjarv.sh/sar/sar-6-confused-deputy.html#prevention). Furthermore, many SaaS providers are still struggling with [fairly basic issues](https://blog.wut.dev/2024/08/14/vendor-cloud-security.html) that have already been well documented, which does not instill confidence this is a commonly implemented mitigation.

### How likely is the Attacking the Confused Deputy scenario now? 

Not likely. I'm not aware of this being exploited previously and new occurrences of this attack would be unlikely due to AWS's change in role behavior. However, ongoing self-assume behavior can lock roles into the previous Implicit SAR behavior which means providers may still be susceptible either through accidental role re-assumption or by having previously been targeted by this attack. 

Additionally, since the [Attacking the Confused Deputy](#attacking-the-confused-deputy) attack had the potential to target customer's accounts directly you may want to verify your SaaS providers were not affected previously. Among other persistence techniques, some SaaS providers require customer roles to be self-assumable which allows for persistence through self-role juggling as I previously covered in [Bypassing Session Expirations and Revocations](https://blog.ryanjarv.sh/sar/sar-4-bypassing-session-expirations-and-revocations.html).

So while I don't believe there's much need for most people to worry about this, I would encourage SaaS providers, as well as others concerned to thoroughly investigate the previous possibility of this attack.

### Is it possible to independently check if a given SaaS provider was affected?

I recommend checking with your SaaS providers as they would need to dig into their specific configuration and platform thoroughly to answer this question accurately. However, you may also be able to verify their answer to some degree by configuring a SaaS account with a cross-account role that has no permissions. If you can retrieve you're own session credentials through any feature of the SaaS provider, it is a good indicator that they were vulnerable to the full attack described in [Attacking the Confused Deputy](sar-6-confused-deputy.html) which results in the attacker being able to access all customer's accounts. If you can get this far, the SaaS provider needs to ensure they were explicitly denying access to their own role, or more likely, as this was undocumented, all roles in the current account using an explicit Deny condition prior to migrating to a new IAM Role not affected by Implicit SAR.

Conversely, if there is no possibility of account credentials being passed to user-controlled code, either now, or in the past, you can rule out the most direct method of accessing customer's accounts with this attack.

## Last Thoughts

I was thinking last night about what the underlying problem is that led to the [Attacking the Confused Deputy](#attacking-the-confused-deputy) scenario being possible and I think it has to do with an underlying difference, and confusion, between machine and user authentication. I'm not an expert on AuthN, but with sts:AssumeRole there is no difference between them, which may lead to defaults that may make sense for one but not the other? I'm not sure how this correlates to alternatives, but the main example I'm thinking of here is how `sts:ExternalID` doesn't cause a request to fail when it is not enforced on the target role. I suspect this would be a rather obvious design decision if it weren't for the dual-purpose nature of IAM Roles.

Anyway, while I have some ongoing concerns about the [Attacking the Confused Deputy](#attacking-the-confused-deputy) scenario, the point I want to get across here is more related to the fact that this behavior was ever undocumented. I don't know what the solution for this is, I'd like to see IAM open-sourced, but is that even possible? What about a model of how it works, something beyond written English, more like a spec? Would this include edge cases from various teams? I would imagine there is an internal process for making exceptions to the commonly documented model, or at least I hope so. Is there a place where we can find these listed? I haven't seen it if it exists, but maybe I haven't looked hard enough (i actually don't feel like looking right now... let me know if it does though).

Lastly, I appreciate that AWS ultimately decided to change the Role Trust behavior. So while I may be critical here, and have some outstanding concerns, it is worth remembering the underlying cause of these issues was fixed provided your roles have been recreated since the change, or alternatively followed the instructions described in [AWS's original announcement](https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/).
