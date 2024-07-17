---
layout: category
title: Implicit SAR -- Attacking the Confused Deputy
category: sar
permalink: /:categories/:title:output_ext
post_number: 6
---

{{ page.title }}
================

<p class="meta">31 Mar 2024</p>

## Introduction

In this post, I'll show how Implicit SAR could have turned a few missing security best practices into a critical non-authenticated vulnerability chain resulting in the compromise of all customers of a SaaS Provider.


## Example Environment

Let's assume the cloud monitoring service `DetectIT` needs access to a customer's AWS account to collect metrics, a simple diagram of the infrastructure may look like this.

```
  | SaaS Provider           |
  |-------------------------|
  | DetectIT Application    |
  |    \                   _|____ Customer 1
  |     \                 / |   
  |    DetectIT          /  | 
  |   Proxy Role -------+---+---- Customer 2
  |                      \  | 
  |                       \_|____ Customer 3
  |_________________________|
```

During signup, the customer is asked to configure an IAM Role in their own account with a role trust and `sts:ExternalID` condition which allows the `DetectIT` backend application to access the role.

The customer then provides the SaaS provider with the role ARN of this newly configured role. At this point, the SaaS application attempts to Assume the customer's role and if it is successful, it is associated with the customer's account.

Despite the fact an attacker can provide an arbitrary Role ARN, this signup process is not susceptible to the [Confused Deputy problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html). This is because, in our case, customers are enforcing `sts:ExternalID` on target roles, and the SaaS provider is not reusing `sts:ExternalID`s between customers.

Because the SaaS provider must potentially access any arbitrary role, the role is granted full `sts:AssumeRole` permissions in the identity policy. 

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AssumeRole",
      "Effect": "Allow",
      "Action": ["sts:AssumeRole"],
      "Resource": "*"
    }
  ]
}
```

Additionally, because the SaaS application is running on EC2 the trust policy of the source role is the following:

```json
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

## Implicit SAR Confused Deputy

To exploit this configuration an attacker sign's up for a new account with DetectIT using an AWS account controlled by the attacker. Once setup is completed the attacker will find a `sts:AssumeRole` log in their own account containing info about the source of the AssumeRole event.

```
  "userIdentity": {
    "type": "AWSAccount",
    "principalId": "AROAXXXXXXXXXXXXXXXXX:proxy-role",
    "accountId": "111111111111"
  },
```

The `principalId` field above consists of the roleId and name of the DetectIT proxy role separated by a colon. The attacker then takes the roleId (`AROAXXXXXXXXXXXXXXXXX`) and runs a reverse lookup on it to [derive the full Principal ARN](https://hackingthe.cloud/aws/enumeration/enumerate_principal_arn_from_unique_id/).

As long as the application does not enforce specific naming conventions for customer’s roles, and the assuming principal is actually a Role, rather than an IAM User, the attacker can now reconfigure their DetectIT account to use this newly obtained ARN.

*If the DetectIT proxy role is affected by Implicit SAR, the proxy role will successfully authenticate itself completing the registration of the DetectIT account owned by the attacker to DetectIT's own AWS account.*

## Getting Real Access

Currently, the attacker has access to the SaaS provider role restricted by the actions available through the SaaS application.

What this means, at the moment, for our specific example environment is effectively nothing. To understand the impact of this attack we need to understand what the attacker would need to do next to turn this into a useful exploit.

For the sake of understanding impact let's say our example above was not for DetectIT the monitoring application, it was for AccessIT an SSO provider. This is a service that simply returns temporary credentials to customers from the result of `sts:AssumeRole`.

By using the functionality of the `AccessIT` service the attacker now has the raw credentials of the `AccessIT` proxy role.

In contrast, the `MonitorIT` attacker can only access the `MonitorIT` proxy role through the `MonitorIT` web application. However, if a feature exists that allows customers to take arbitrary actions against their own account. For example, the `MonitorIT` application allows for configuring hook's running custom code in the context of the customer's own AWS account. Then we may be in a similar place as the `AccessIT` attacker above depending on the functionality and implementation of the `MonitorIT` feature.

We should also consider that, regardless of whether arbitrary control over the proxy role can be obtained, the attacker is in a unique position that was not previously considered possible by the SaaS Provider; it is difficult to predict what may go wrong, or which assumptions will break in this scenario.

### Over-provisioned Source Role

If MonitorIT or AccessIT proxy roles were not designed to function independently from the application role, they will likely have additional application permissions that the attacker can abuse. This is the case in our example above as the proxy role is using an Instance Profile attached to an EC2 instance rather than a separate role which is accessed by the backend at runtime.

API calls of the `MonitorIT` application that overlap with these additional permissions on the proxy role may start populating the attacker's `MonitorIT` account with data automatically. The credentials returned from the `AccessIT` application however will allow the attacker to abuse all excess permissions on the proxy role without restrictions.

The worst case scenario is if the proxy role allows read-only access to CloudTrail, which will contain customer ARNs and associated ExternalIDs for outbound `sts:AssumeRole` calls. In the case of `AccessIT` the attacker will now have all the information required to gain access to the AWS Accounts of every `AccessIT` customer. The last step is to simply call AssumeRole from the proxy role with each ARN and ExternalID combination found in the CloudTrail logs.

**With just the `cloudtrail:LookupEvents` permission AWS accounts of all AccessIT customers are fully compromised.**

Doing the same in our `MonitorIT` example may be a bit more difficult, we can coerce `MonitorIT` to attempt to assume client roles but since we can't control the `sts:ExternalID` value provided by the application the API call will probably fail. So in this case the attacker needs to find a feature similar to what we described previously.

### Other Implicit SAR Attacks

Let's say the role is properly locked down, it is as minimal as our example above and no other resources in the account have overly permissive resource policies. With arbitrary control over the proxy role, we can maintain access using the role juggling technique described in the [Bypassing Session Expirations](sar-4-eluding-session-expirations-and-revocations.html) post even after our initial attack vector is fixed.

## Prevention

Only a very tiny percent of roles were on the implicit allowlist at the time of AWS's announcement of the trust behavior change in September 2022, and since then, that amount has since decreased further.

However, I recommend explicitly ensuring any proxy roles are not using the previous IAM Trust policy behavior. When and why this can happen is covered by [AWS's original announcement](https://aws.amazon.com/blogs/security/announcing-an-update-to-iam-role-trust-policy-behavior/).

You can do this by searching CloudTrail AssumeRole events for the `explicitTrustGrant` attribute to find cases where the old role trust behavior is used. This CloudTrail attribute was covered in the "[When AWS invariants aren't [invariant]](https://awsteele.com/blog/2024/02/20/when-aws-invariants-are-not.html)" blog post by Aidian Steele and recently added to [AWS's IAM documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/cloudtrail-integration.html#cloudtrail-integration_role-trust-behavior). 

Ensuring the proxy role is not using the old behavior will prevent the attack described above, however, due to the nature of this role it's also a very good idea to make sure the privileges associated with it are as minimal as possible. For example, the proxy role should only be allowed `sts:AssumeRole` access *outside* the current organization (or account/org path). Below is an example of what this policy might look like.


```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow full assume role access",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "*"
    },
    {
      "Sid": "Deny all access to any resources in the current organization",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceOrgID": "${aws:PrincipalOrgID}"
        }
      }
    },
    {
      "Sid": "Deny all actions other than sts:AssumeRole",
      "Effect": "Deny",
      "NotAction": "sts:AssumeRole",
      "Resource": "*"
    }
  ]
}
```

## Summary

The attack covered in this post shows how Implicit SAR could have turned a few missing security best practices into a critical non-authenticated vulnerability chain resulting in the compromise of all customers of a SaaS Provider.

Very few roles are currently allow listed into the previous Implicit SAR behavior currently, however, it is still important to manually verify any SaaS proxy roles are not relying on this old behavior by checking for `explicitTrustGrant` in CloudTrail logs.

While the impact of this depends heavily on how the platform works, before the Implicit SAR change, this attack would have affected SaaS platforms that use cross-account `sts:AssumeRole` based access and do not explicitly prevent access to their own cross-account proxy role. This applies regardless if the proxy role is an AWS service role or not, for example, if it is used in a Lambda Function or as an EC2 Instance Profile.

In most cases, this vulnerability would need to be combined as a part of a longer exploit chain to be useful. However, in the worst-case scenario, this attack may directly result in the ability of the attacker to access the accounts of all clients of the SaaS provider.
