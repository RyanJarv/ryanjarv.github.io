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

At the time of the post nearly all IAM role’s had been updated to use the new behavior and a small amount percentage (approximately 0.0001%) which relied on the old behavior where allowlisted into the older behavior. Over the past year and a half the number of allowlisted roles where reduced further as they were recreated or usage was updated to avoid relying on the previous behavior.

This modification in IAM Role trust policies overlapped with my examination of sts:AssumeRole, focusing on a niche scenario within IAM evaluation known as Implicit Self-Assume Role (Implicit SAR). Throughout this period, I explored various cases where I proposed that Implicit Self-Assume Role might result in unintuitive behavior, topics I will cover later.

By sharing these blog posts I hope to dive deeper into AWS's original discussion, focusing on the potential exploitation of past behaviors of Implicit SAR.

If you would like to verify your role’s are not allowlisted into the old behavior I would recommend reading through the original blog post by AWS (https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/). It is also worth noting that AWS has also recently added the `explicitTrustGrant` to AssumeRole log events to help detect legacy trust role behavior, this is covered in AWS’s post linked above and documented [here](https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html#cloudtrail-integration_role-trust-behavior).

### Summery

The first couple of posts in the IAM Evaluation section below go over the basics of AssumeRole in the context of IAM and how Implicit SAR worked before the change. You can skip these if you want, just know these are there if they are helpful.

After that, I'll cover a few attacks that may have been possible in the past with Implicit SAR. Starting with persistence with [Eluding Session Expirations and Revocations](sar-4-eluding-session-expirations-and-revocations.html), then [Modifying Session State](sar-5-modifying-session-state.html) to throw off auditing or potentially escalate privileges, finally in [Attacking The Confused Deputy](sar-6-confused-deputy.html) I'll show how Implicit SAR can turn a few missing security best practices into a critical non-authenticated vulnerability chain resulting in the compromise of all customers of a SaaS Provider.

#### IAM Evaluation

  * [IAM Evaluation](sar-2-iam-evaluation.html)
  * [IAM Evaluation with Implicit Self Assume Role](sar-3-iam-evaluation-self-assume-role.html)


#### Attacks

  * [Eluding Session Expirations and Revocations](sar-4-eluding-session-expirations-and-revocations.html)
  * [Modifying Session State](sar-5-modifying-session-state.html)
  * [Attacking The Confused Deputy](sar-6-confused-deputy.html)
