---
layout: category
title: Implicit SAR -- Modifying Session State
category: sar
permalink: /:categories/:title:output_ext
post_number: 5
---

{{ page.title }}
================

<p class="meta">31 Mar 2024</p>

## Introduction

When we think of sessions associated with a given role it's easy to assume that they are mostly equivalent, this however is not the case. 

For example, in the [last post](sar-4-eluding-session-expirations-and-revocations.html#other-role-types) we covered how Service Control Policies (SCPs) restricting the use of principals like EC2 service roles may not apply to credentials obtained by subsequent role assumptions, including those obtained by implicit SAR. This is an example of session context affecting permissions associated with a set of credentials.

As users of AWS, we can't control the session context directly, however, there is some state that we can control which is set when we first assume a role. If we can unexpectedly re-assume a role to change this session state, we may be able to break assumptions made by certain permission models.

In this post, we'll take a look at how Implicit SAR had unexpected effects on users' permissions and identity in specific environments.

## Spoofing Role Session Names

***Note:*** *The effect Implicit SAR had on Role Session Names was also mentioned in [this blog post](https://arkadiyt.com/2024/02/18/detecting-manual-aws-actions-an-update/#detecting-session-name-bypasses) by Arkadiy Tetelman. This section covers the same general issue with a few examples.*

Session role names, by default, are arbitrary values chosen by users when a role is first assumed. The [sts:RoleSessionName](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#ck_rolesessionname) IAM condition is intended to restrict the naming of individual IAM role sessions to track access in CloudTrail.

However, for Roles affected by Implicit SAR, it was not possible to reliably depend on `sts:RoleSessionName`. This is because the `sts:RoleSessionName` attribute can only be used by trust policies, which were ignored during Implicit SAR. 

In this section, we'll show how the configuration described in the [AWS blog post on sts:RoleSessionName](https://aws.amazon.com/blogs/security/easily-control-naming-individual-iam-role-sessions/), could not be used for accurately tracking identity when a role was affected by Implicit SAR.

### Example Environment

Our example environment consists of two IAM users, alice, and bob. Which will both be granted access to the `shared-admin-role`.

The role trust policy uses `sts:RoleSessionName` to restrict the value of the `--role-session-name` parameter of `aws sts assume-role` so that it always matches the original IAM username (`aws:username`).

When working as intended, the original user's name will appear in API calls made from the `shared-admin-role` IAM Role.

![sar-session-name](/images/sar-session-name.jpeg)
*The image above shows the intended environment for the [sts:RoleSessionName](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_iam-condition-keys.html#ck_rolesessionname) trust policy.*

![sar-session-name-cloudtrail](/images/sar-session-name-cloudtrail.png)
*The image above shows the `s3:ListBuckets` action called by bob from the shared-admin-role.*

### Spoofing Resource Session Name

With Implicit SAR, as the `bob` IAM User we can first assume the role as required in the role's resource trust policy.

```
aws sts assume-role --role-arn arn:aws::123456789012:role/shared-admin-role --role-session-name bob
```

Using the `bob` role session we can now re-assume the admin role to change our name to `alice`.

```
% aws sts get-caller-identity
{
    "UserId": "AROAXXXXXXXXXXXXXXXXX:0000000000000000000",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:role/admin/bob"
}
% aws sts assume-role --role-arn arn:aws::123456789012:role/shared-admin-role --role-session-name alice
% ... export returned credentials to the environment...
% aws sts get-caller-identity
{
    "UserId": "AROAXXXXXXXXXXXXXXXXX:0000000000000000000",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:role/admin/alice"
}
```

When we re-assumed the `shared-admin-role` using our admin role nothing matched in the trust policy. Because the role was affected by Implicit SAR, IAM evaluation of the trust policy defaulted to Allow even though the following condition never matched:

```
    "Condition": {
        "StringLike": {
            "sts:RoleSessionName": "${aws:username}"
        }
    }
```


Without Implicit SAR, it would not be possible for bob to act as alice. However, with it, the role session names can be changed unexpectedly.

## Session Tag Fixation

Tags applied to roles can function as a mechanism which to grant access in IAM policies. For example, let's assume the role in the last section has the `Environment` tag set to `dev`. The following identity policy would then limit `sts` and `s3` actions to resources that also have the `Environment=dev` tag.


```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": ["sts:*", "s3:*"], 
      "Condition": {
          "StringEquals": {
            "aws:ResourceTag/Environment": "${aws:PrincipalTag/Environment}"
          }
      }
    }
  ]
}
```

In the case where sts:TagSession is allowed in the identity policy in addition to sts:AssumeRole it is possible to set transitive tags that persist for the duration of the role session chain, overriding tags from other sources.

This normally isn’t an issue, but when tags are relied on in IAM policies for granting access, for example, with the Condition statement shown above, overriding them in this way can lead to more access than intended.

#### Example Environment

Let's assume we have an `sts:AssumeRole` authorization scheme that implements access based on the source and target's `Environment` tag. Principals should only be able to make `sts:AssumeRole` calls to roles where the `Environment` value matches their own. So `dev` users can all access the `dev` admin role, while only a few can access the `prod` admin role.

To implement this we add the correct Environment tag to all users and roles and attach the following Identity policy.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sts:*",
            "Resource": "*"
        }
    ]
}
```

While `sts:*` is generally considered overprivileged we are not concerned about this because we intend to restrict access via the following trust policy.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::111111111111:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Environment": "${aws:PrincipalTag/Environment}"
                }
            }
        }
    ]
}
```


### Current Behavior

First, we'll walk through how this environment works with the current role trust behavior to get an idea of how we expected IAM to behave.

Currently, our user is in the `dev` environment group, specified by the `Environment` tag on the user. We can not access the prod role because its `Environment` tag is set to `prod`.

```shell
$ assume arn:aws:iam::299680663816:role/prod prod
Session Name: prod
arn:aws:sts::299680663816:assumed-role/test/test -> Assume Role Failed (arn:aws:iam::299680663816:role/prod)
```

We can access the `dev` role, which has the `Environment=dev` tag.

```shell
$ assume arn:aws:iam::299680663816:role/dev dev 
Session Name: dev
arn:aws:sts::299680663816:assumed-role/test/test -> arn:aws:sts::299680663816:assumed-role/dev/dev
```

The `dev` role can not access the `prod` role for the same reason as before.

```shell
$ assume arn:aws:iam::299680663816:role/prod prod
Session Name: prod
arn:aws:sts::299680663816:assumed-role/dev/dev -> Assume Role Failed (arn:aws:iam::299680663816:role/prod)
```

We can't override our session tags because no role trust policy allows the `sts:TagKeys` action.

```shell
$ assume arn:aws:iam::299680663816:role/dev dev -t Environment=prod
Setting transitive tag: Environment=prod
Session Name: dev
arn:aws:sts::299680663816:assumed-role/dev/dev -> Assume Role Failed (arn:aws:iam::299680663816:role/dev)
```

While the Identity policy appears to be overprivileged here, based on our understanding roles are unique in that they require both Trust and Identity-based permissions, this setup functions as intended.

### Example With SAR

Previously, when implicit SAR behavior was allowed, it was possible to break the assumption above by calling `sts:AssumeRole` with transitive tags on our own `dev` role. This was possible only when assuming our role due to the relaxed IAM evaluation logic that occurred during implicit SAR.

The process is similar to the last example, except before accessing the prod role, we re-assume the `dev` role a second time, setting the `Environment` tag to `prod`.

```shell
% assume arn:aws:iam::336983520827:role/dev Environment=prod 
Set transitive tag: Environment=prod
Current ARN: arn:aws:sts::336983520827:assumed-role/dev/prod
```

With this new session, we can now access the prod role.

```shell
% assume arn:aws:iam::336983520827:role/prod Environment=prod 
Set transitive tag: Environment=prod
Current ARN: arn:aws:sts::336983520827:assumed-role/prod/prod
```

The `Environment` is a transitive tag and will override other tags through any additionally chained roles or actions. In this case, the transitive tag overrides the resource tag.

# Summary

This examination of AWS IAM's historical Implicit SAR behavior reveals subtle, potentially unintended effects on role permissions and identity management within AWS environments, particularly relating to session state and access control mechanisms.
