---
layout: post
title: Implicit SAR -- Overview
category: sar
permalink: /:categories/:title:output_ext
post_number: 1
---

{{ page.title }}
================

<p class="meta">31 Mar 2024</p>

## Introduction

In September of 2022, AWS [announced an update to IAM role trust policy behavior](https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/).

At the time of the post nearly all IAM roles had been updated to use the new behavior and a small percentage (approximately 0.0001%) that relied on the old behavior were allowlisted into the older behavior. Over the past year and a half the number of allowlisted roles where reduced further as they were recreated or usage was updated to avoid relying on the previous behavior.

This modification in IAM Role trust policies overlapped with my examination of sts:AssumeRole, focusing on a niche scenario within IAM evaluation known as Implicit Self-Assume Role (Implicit SAR). Throughout this period, I explored various cases where I proposed that Implicit Self-Assume Role might result in unintuitive behavior, topics I will cover later.

By sharing these blog posts I hope to dive deeper into AWS's original discussion, focusing on the potential exploitation of past behaviors of Implicit SAR.

If you would like to verify your roles are not allowlisted into the old behavior I would recommend reading through the [original blog post by AWS](https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/). It is also worth noting that AWS has also recently added the `explicitTrustGrant` to AssumeRole log events to help detect legacy trust role behavior, this is covered in AWS’s post linked above and documented [here](https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html#cloudtrail-integration_role-trust-behavior).

### Summary

The first couple of posts in the IAM Evaluation section below go over the basics of AssumeRole in the context of IAM and how Implicit SAR worked before the change. You can skip these if you want, just know these are there if they are helpful.

After that, I'll cover a few attacks that may have been possible in the past with Implicit SAR. Starting with persistence with [Bypassing Session Expirations and Revocations](sar-4-bypassing-session-expirations-and-revocations.html), then [Modifying Session State](sar-5-modifying-session-state.html) to throw off auditing or potentially escalate privileges, finally in [Attacking The Confused Deputy](sar-6-confused-deputy.html) I'll show how Implicit SAR can turn a few missing security best practices into a critical non-authenticated vulnerability chain resulting in the compromise of all customers of a SaaS Provider.

#### IAM Evaluation

  * [IAM Evaluation](sar-2-iam-evaluation.html)
  * [IAM Evaluation with Implicit Self Assume Role](sar-3-iam-evaluation-self-assume-role.html)


#### Attacks

  * [Bypassing Session Expirations and Revocations](sar-4-bypassing-session-expirations-and-revocations.html)
  * [Modifying Session State](sar-5-modifying-session-state.html)
  * [Attacking The Confused Deputy](sar-6-confused-deputy.html)

#### Summary

  * [Summary](2024-05-06-sar-7-summary.html)

#### Notes and Thanks

I started this post about a year and a half ago, but took me a long time to finish. After digging into this topic quite a bit I ended up just getting burnt out on it and set it away for a while.

I want to thank the AWS security team for reviewing this post, and separately, for the work that was put into updating the Role Trust behavior.

The mention of implicit SAR bypassing SCP enforcement of EC2 sessions in the [Session Expirations and Revocations](sar-4-bypassing-session-expirations-and-revocations.html#Other-Role-Types----EC2-Example) was originally brought up by [Houston Hopkins](https://twitter.com/hhopk).

The effect Implicit SAR had on Role Session Names, which is covered in [Modifying Session State](sar-5-modifying-session-state.html), was also mentioned in [this blog post](https://arkadiyt.com/2024/02/18/detecting-manual-aws-actions-an-update/#detecting-session-name-bypasses) by Arkadiy Tetelman.

Aidian Steele also covers the same topic, along with the `explicitTrustGrant` CloudTrail attribute, which I reference later, in [When AWS invariants aren't [invariant]](https://awsteele.com/blog/2024/02/20/when-aws-invariants-are-not.html).

Lastly, I want to thank [Houston Hopkins](https://twitter.com/hhopk) and [Nick Frichette](https://twitter.com/Frichette_n) for reveiwing and providing feedback the Implicit SAR summary post.


