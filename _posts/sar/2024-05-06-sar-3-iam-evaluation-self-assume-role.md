---
layout: category
title: Implicit SAR -- IAM Evaluation with Implicit Self Assume Role
category: sar
permalink: /:categories/:title:output_ext
post_number: 3
---

{{ page.title }}
================

<p class="meta">31 Mar 2024</p>

## Introduction

In the [last post](sar-2-iam-evaluation.html) I covered the two documented types of IAM `sts:AssumeRole` behavior. In this post, I cover a specific subset of this behavior that was changed in AWS's [IAM role trust policy](https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/) update and only occurred when a role attempted to assume itself.

## Implicit Self-Assume Role

This blog post series will refer to this previous behavior as Implicit Self-Assume Role or SAR. Previously, roles implicitly
trusted themselves from a role trust policy perspective if they had identity-based permissions to assume themselves.

For example, if we have the following broad and powerful statement in an identity-based policy on a Role:

```json5
{
  "Effect": "Allow",
  "Resource": "*",
  "Action": "sts:AssumeRole"
}
```

Then, under the previous behavior, ***the identity policy itself was sufficient*** for the Role to assume itself; because in this specific situation, the roles implicitly trusted themselves, and so the role could assume itself regardless of regardless whether its role trust policy referenced the role or not.

This IAM Evaluation Behavior was relatively unknown because a role assuming itself is an anti-pattern that wasn't commonly implemented - according to AWS, most of the usage they observed before making this change was due to software bugs or other accidental usage.

Additionally, because of the requirement for broad identity-based permissions meant this quirk appeared innocuous at first glance.

## What Types of Roles Did Implicit SAR Apply To?

Specifically, under the previous behavior, Implicit SAR affected roles where the identity-based policy of a role allowed `sts:AssumeRole` to itself, and the trust policy did not explicitly deny the same permission.

### __Privileged Roles__

This included any role that using a policy granting `sts:AssumeRole` with a `*`. Generally, this is a very powerful action so these policies often included other privileged actions like the ability to modify IAM.

* Roles with the `PowerUserAccess`, `AdministratorAccess`, or `AdministratorAccess-Amplify` managed policies attached.
* The `OrganizationAccountAccessRole` IAM Role created by Organizations when creating a new account.
* Roles used for [break glass access](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/break-glass-access.html) with full-admin access.

### __Trust Policy-based Authorization Models__

In a Trust Policy-based authorization model `sts:AssumeRole` access is managed primarily via IAM Role Trust policies. In these cases broad identity-based `sts:AssumeRole` permissions may be assigned to simplify IAM management. As long as IAM access to the account is strictly managed, it is not necessarily insecure and allows managing access solely through the target role's trust policy.

While this is not encouraged, in some cases, it is necessary. For example, situations that do not know all cross-account target roles prior to provisioning can not restrict access in the identity policy.

* Just In Time access systems
* Cross-Account Provisioning
* SaaS Providers accessing customer's AWS accounts
* Cross Account user access based on `sts:AssumeRole`.

### __Other__

To simplify later blog posts, I will only focus on the first two types, but for the sake of completeness we can also consider a few other situations. These cases where generally not be intentional, but may have been overlooked during security reviews if a Role assuming itself was not considered a risk. 

Under the old behavior, implicit SAR may have also applied to more scoped-down policies with partial resource patterns depending on the name or tags of the Role. For example, when the `sts:AssumeRole` action allowed `arn:aws:sts::*:role/db-access-*` attached to a role named `db-access-prod`. Another example where this could have arisen would have been when `sts:AssumeRole` access was granted based on the session tags matching the resource tags.

These situations, could have come up when renaming roles, migrating between environments, or misnaming roles when deploying code that made assumptions about the underlying infrastructure.

## Summary

In this post, we covered the specifics of previous Implicit SAR behavior and the types of roles they apply to.

Next, I will dive into how we could have taken advantage of the previous behavior under certain conditions to extend the effective lifetime of a role session beyond its expected session duration.

