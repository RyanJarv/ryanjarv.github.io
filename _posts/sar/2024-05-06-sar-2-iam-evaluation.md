---
layout: category
title: Implicit SAR -- IAM Evaluation
category: sar
permalink: /:categories/:title:output_ext
post_number: 2
---

{{ page.title }}
================

<p class="meta">31 Mar 2024</p>

## Introduction

This post covers the basics of how IAM behaved in the context of `sts:AssumeRole`; specifically the difference between Identity and Trust policies in same-account and cross-account AssumeRole scenarios. Readers should have some prior working knowledge of IAM but do not need to know how it works in the case of `sts:AssumeRole`. Covering these topics should make it easier to understand later blog posts and why the (now changed) Implicit SAR was unintuitive.

## AssumeRole Evaluation Behavior

To understand implicit SAR, we need to understand that IAM evaluation is an interaction between several different policies, and how they interact changes depending on context and whether the resource in question is one of the "special" resource types which we'll discuss below.

An Identity-based Policy is attached to a principal (IAM Role or User) and specifies what API calls that principal can make. Within the same AWS account, these permissions are typically sufficient to perform a specific action. However, this general rule doesn't apply for particular security sensitive resources such as KMS keys or IAM roles, which AWS documents [here](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html#policy-eval-denyallow). For those resource types, even in the same AWS account, the identity-based policy permissions are not sufficient, the resource-based policy must grant access. For example, you may have noticed before that `sts:AssumeRole` does not always work as an administrator in the account.

![Administrator Identity Policy](/images/sar-admin-identity-policy-2.png)
*The image above shows the AdministratorAccess Identity Policy attached to a Role.*

Resource-based policies such as IAM Role Trust Policies are attached to resources rather than principals. In the case of IAM Roles, due to the exception noted above, the resource-based policy needs to grant the necessary permission in order for the API call to be successfully authorized, even in the same account.

![Root Trust Policy](/images/sar-role-trust-policy.png)
*The image above shows a Resource Trust Policy attached to a Role.*

IAM Roles are also unique in one other way - they are the only entity within AWS that is both a principal and a resource! Because of this, they can have both kinds of policies attached to them. Identity policies on Roles affect outgoing permissions, i.e., what the Role can access as a principal. In contrast, Role Trust Policies affect incoming permissions, i.e., who can access (i.e., assume) the principal. This makes understanding IAM roles a bit more confusing than most other AWS resources, which I will cover below.

### Delegated Authority

I will dig into exactly what this means, but for the moment, we can summarize delegated authority with the following statement:

*When the Role Trust Policy specifies an AWS account, the IAM role is delegating its unique requirement for identity-based access to the specified account.*

#### Delegated Authority -- Cross Account Access

To provide an example, let's assume we have an IAM Role which we'll call `deploy`. This role has the following Trust Policy:

```json5
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::1111:root"
            },
            "Action": "sts:AssumeRole",
        }
    ]
}
```

This allows `sts:AssumeRole` for the root principal of account `1111`. Meaning, the role's requirement for Identity-based access is delegated to the administrators of `1111`.

To determine who has access to this Role, we need to look at the Identity Policy for every IAM Principal (User or Role) in the `1111` account. If the Identity Policy evaluates to `Allow` for `sts:AssumeRole`, then the action is allowed; if it doesn't, it is denied.

#### Delegated Authority -- Explicit Cross-Account Trust

Say we change the Principal in the last example to explicitly reference `bob` who exists in an ***another*** account.

```json5
"Principal": {
    "AWS": "arn:aws:iam::2222:user/bob"
},
```

The same behavior described for the account itself (the root principal) will now apply to the user `bob` so long as `bob` has the identity-based generic permission to call the `sts:AssumeRole` API (and no other condition-based restrictions that would interfere). However, the user `alice` in the same account `2222` would not have permission to assume the role, since she is not included in the Role Trust Policy.

Note that while the second example -- specifying a particular principal 'bob' in the "foreign" account -- looks like a safer, more "least-privileged" way to manage cross-account permissions, there is no practical security difference between the two approaches when thinking holistically about cross-account trusts from an account level perspective.

Why? Because the root principal of the other account can grant 'bob' privileges to anyone they like! So while there's no harm in narrowing cross-account permission to a particular user or role, if you are thinking about domains of authority on an account level, it's equivalent to granting permissions to the root principal of that account, who has full control over who can access what inside that account.

### Trust Policy Sufficient Evaluation

*Like other AWS resources, Role Trust Policies are sufficient to grant access within the same account.*

This means, if we update the policy to point to `sam`, who exists in the same account as our `deploy` role, then there would be no need to grant access in `sam`'s Identity-based policy because it's already granted by the trust policy.

```json5
"Principal": {
    "AWS": "arn:aws:iam::1111:user/sam"
},
```

In this case, IAM evaluation follows the normal rules for an identity and a resource in the same account, where the resource-based permissions are sufficient to grant `arn:aws:iam::1111:user/sam` permission to assume the role, even if the `sam` User does not have any `sts:AssumeRole` identity-based permissions.

As always, any deny statements will always still override this behavior.

## Summary

Compared to other AWS resources that support resource-based policies, IAM role trust policies are unique (along with KMS keys) in that they are always required to grant access, but similar in that they are *sufficient* to grant access within the same account even in the absence of corresponding identity-based permissions.

So far, we covered the two documented types of IAM sts:AssumeRole behavior; in the next post, I'll cover a specific subset of this behavior that was changed in AWS's IAM role trust policy update and only occurred when a role attempted to assume itself.
