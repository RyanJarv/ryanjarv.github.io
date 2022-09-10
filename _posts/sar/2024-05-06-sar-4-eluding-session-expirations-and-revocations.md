---
layout: category
title: Implicit SAR -- Eluding Session Expirations and Revocations
category: sar
permalink: /:categories/:title:output_ext
post_number: 4
---

{{ page.title }}
================

<p class="meta">31 Mar 2024</p>

## Introduction

Roles are preferred over IAM Users to avoid long-lived API keys. Access to a Role is granted through Role Sessions, each of which results in a set of temporary credentials that expire automatically after 1 to 12 hours. On the other hand, IAM Users use long-term credentials that are valid until rotated manually.

An important exception to this is when a misconfiguration that allows [Role Juggling](https://hackingthe.cloud/aws/post_exploitation/role-chain-juggling/) to become possible, which can allow attackers to maintain the same access past the original session expiration.

Role Juggling can extend access because [Role Chaining](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-role-chaining) results in a new set of credentials that are not associated with the previous in terms of session expiration. So, Role Juggling repeatedly extends this Role Chain to ensure the attacker's access does not expire or the session credentials are made ineffective with a time-based policy such as the one provided by [session revocation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_revoke-sessions.html) in the IAM console.

Often, we will consider Role Juggling when two or more Roles can assume each other. However, it can happen with a cyclical graph of any size, including when a single Role can assume itself. Under the old behavior, implicit SAR allowed Role Juggling to work in this way regardless of the affected Role's trust policy.

## Implicit SAR Role Juggling Example

Let's assume an attacker discovered session credentials of the following Administrative Role. Below are the policies attached to this Role.


**Identity**
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
```

**Trust Policy**
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::222222222222:user/bob"
      },
      "Action": "sts:AssumeRole",
    }
  ]
}
```

Looking at this trust policy, we might assume that access **to this Role** would have always followed the [Delegated Authority](sar-2-iam-evaluation.html#delegated-authority) IAM evaluation and this Role was not vulnerable to Role Juggling. 

However, with [implicit SAR](sar-3-iam-evaluation-self-assume-role.html#implicit-self-assume-role), the attacker could have maintained access to the Role for as long as necessary by repeatedly extending the Role Session Chain.

![SAR Role Juggling Example](/images/sar-role-juggling.png)

The image above shows a shell function that continuously assumes its own Role. After assuming the Role it exports the returned credentials to the environment, ensuring the new session gets used the next time `assume` is called.

### Other Role Types -- EC2 Example

Under the old behavior of Implicit SAR, terms we use to differentiate between Roles like an `EC2 Instance Role`, `Lambda Role`, `Federated Role`, or `MFA Role` did not matter. The result was the same. Given sufficient identity-based permissions, cases where we would expect a Role not to have been re-assumable, it would have been susceptible to single-role Role Juggling, and thus to the risk of being prolonged indefinitely by re-assumption rather than being time-limited as with normal temporary credentials.

I won't cover all Role types here, but as one more example, we can consider a Role used by an EC2 instance. The only principal that ever needs to assume an EC2 Instance Role is the EC2 service principal managed by AWS, and to allow this, EC2 Roles will have a trust policy like the following:

```
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

Like before, our example is an administrative Role with full `sts:AssumeRole` access in the identity-based policy. With credentials retrieved from the IMDS, the attacker without access to the `ec2.amazonaws.com` principal could have still refreshed the Role's credentials.

Additionally, the subsequent session credentials would have no longer been associated with the original EC2 instance and no longer would have had any EC2 context data associated with the session. For example, a Service Control Policy that [restricts our use of IMDS credentials](https://aws.amazon.com/blogs/security/how-to-use-policies-to-restrict-where-ec2-instance-credentials-can-be-used-from/) using `ec2:SourceInstanceARN` would not effectively restrict these resulting context-less session credentials, even if the instance was shutdown or the instance profile detached.

### Eluding Role Session Revocation

*Previously, sessions assuming their own role in a short loop would elude Role session revocation.*

**Note:** See the [Updated Revocation Behavior](#updated-revocation-behavior) for why this does not work anymore.

The IAM web console has a feature that revokes sessions of a given Role by applying a time-based policy using `aws:TokenIssueTime`; this policy denies all access for sessions created before the time policy is applied.

![web-revocation](/images/sar-web-revocation.png)
***Shown above is the web console revocation feature.***

Because session revocation in the web console only affects sessions created before the revocation action, it may not contain Role-Juggling attacks across multiple roles if only some of the roles are revoked. Any still-active session belonging to one of the non-revoked Roles can create a new session for the Role affected by the revocation. These newly created role sessions will have an `aws:TokenIssueTime` later than the templated `[policy creation time]` and will not be affected by the revocation action. So in a Role Juggling attack scenario, the defender would need to revoke the sessions of all the roles in use in order to stop the behavior, which might not be that easy.

Generally this attack requires multiple roles, and should not have worked in the SAR Role Juggling case. However, prior to AWS's [updated revocation behavior](#updated-revocation-behavior) change, it was also possible to perform a similar attack with a single role that could assume itself.

Due to eventual consistency in IAM, the revocation policy will take some amount of time to apply to active sessions. Despite this, the `[policy creation time]` value in the session revocation template previously resolved to the time at which the policy was applied, not when it took effect, which, in my testing is typically about six seconds later.

This delay means calling `sts:AssumeRole` within this small window in a short loop (shown below) will elude revocations assuming this further behavior is not subsequently detected. 

![sar-role-juggling](/images/sar-role-juggling.png)
***The image above shows Implicit SAR Role Juggling previously capable of eluding both session revocation and expiration.***

Alternatively, it's worth noting that the web revocation IAM event only takes two seconds to be delivered through Event Bridge and SQS. With IAM events configured to send to SQS, it was also previously possible to use the revocation event as a trigger to refresh the session instead of constantly refreshing the current session every few seconds.

While the policy template previously used by the AWS Console previously used the current time, it now uses the current time plus thirty seconds (see the [updated revocation behavior](#updated-revocation-behavior) section) which mitigates this behavior.

#### Example Demo

To get a better understanding of how eluding revocation worked previously it may help to see this happening in real time.

<video controls>
  <source src="/images/sar-role-juggling.mp4" type="video/mp4">

  Your browser does not support the video tag.
</video>

As you can see in the video, the first revocation should have applied to the sessions created at `12:15:20` UTC. However, due to eventual consistency in IAM, by the time the applied revocation policy took effect, we were already using the session created at `12:15:25` UTC, which the revocation policy does not apply to.


#### Updated Revocation Behavior

AWS recently updated revocation behavior to take into account the delay shown above. Specifically, the [documentation now mentions](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_revoke-sessions.html#revoke-session) the following:

```
After you choose Revoke active sessions, the policy denies all access to users who assumed the role in the past as well as approximately 30 seconds into the future. This future time choice takes into account the propagation delay of the policy in order to deal with a new session that was acquired or renewed before the updated policy is in effect in a given region. Any user who assumes the role more than approximately 30 seconds after you choose Revoke active sessions is not affected.
```

Along with the Role trust policy change, which prevented these attacks for many roles, this additional change, mitigates the technique described above for other roles which have been explicitly configured to allow self-role assumption. 

*Note: I say mitigate here because it is possible for policy delay to take longer than 30 seconds in rare cases. I won't cover this here, but it's good to keep in mind.*

### SAR Role Juggling with High Privileged Roles: Why did it matter?

A reasonable question is why we should care about the previous SAR Role Juggling possibility on highly privileged Roles. Aren't there other options in this situation?

Yes, there are plenty. However, finding a more straightforward and effective persistence mechanism than what SAR Role Juggling previously allowed would have been difficult. Aside from being aware of SAR itself, It required almost no additional information, did not modify the account, and blended in with legitimate use. It also had the side effect of making events across sessions challenging to track, potentially slowing down remediation after the attacker had been discovered.

As an attacker attempting to perform the previous SAR Role Juggling behavior, we needed to know our current caller ARN, which we would have used `sts:GetCallerIdentity` to obtain. This API call, by design, requires no permissions. Using other persistence methods, we often need additional enumeration to find appropriate targets first.

More importantly, though, Role Juggling is ephemeral. Understanding and tracking resources is often the first step for any security team working with AWS. However, even for organizations without a security team, a simple line in a terraform diff, a broken access key, or an EC2 instance that does not follow tagging conventions can all be enough to raise suspicions.

Furthermore, detecting Role Juggling requires understanding the state of Role Chain Sessions. Without the state of the role chain, AssumeRole is simply another commonly used API call. It is not common for a set of roles to require a bidirectional trust or to be able to assume themselves. Because of these requirements, it generally makes more sense to prevent Role Juggling rather than rely on logging and alerting. However, due to this reasoning, it may not have gotten caught when it is was previously possible.

Compared to other escalations like creating new users or backdooring role trust policies, `sts:AssumeRole` is difficult to audit and is not a great indicator of a compromise.

For these reasons, SAR Role Juggling previously had the potential to be a valuable technique for malicious users who expected their access to expire or be revoked. For example, when an Admin is expecting to be fired or when an attacker gains access to a cross-account proxy role for a SaaS service, the second which we'll explore more in [Attacking the Confused Deputy](./sar-6-confused-deputy.html).

## Summery

Role Juggling complicates the expectation that access to Roles is time-limited and can be easily revoked. Additionally, [Implicit SAR](./sar-3-iam-evaluation-self-assume-role.html#implicit-self-assume-role) meant a simplified version of Role Juggling previously applied to all administrative Roles.
