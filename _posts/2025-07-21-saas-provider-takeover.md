---
layout: post
title: AWS CDK and SaaS Provider Takeover
---

{{ page.title }}
================

<p class="meta">27st August 2025 - NW</p>

Imagine you manage a SaaS platform that accesses customer AWS accounts using `sts:AssumeRole`. While this is a common pattern, it has many sharp edges. You've done your research, so you're well aware of the confused deputy problem—where a program is tricked into misusing its authority—and you diligently use the `sts:ExternalId` condition to prevent it.

You're in the process of modernizing your infrastructure, migrating from a legacy IaC solution to the AWS Cloud Development Kit (CDK) with a new CI/CD pipeline.

Notice anything wrong here? It doesn't seem like much, but I've already described nearly all the requirements needed for an attacker to exploit the critical unauthenticated vulnerability I'll be covering in this blog post. This vulnerability affects the highly privileged SaaS platform AWS account, the same account that is used to access all customer AWS accounts in this example.

## The Problem

AWS CDK requires you to bootstrap each environment that you will be deploying infrastructure to. You can either let this step run automatically in the first CI/CD run or run it manually with cdk bootstrap:

<img src="/images/cdk-bootstrap.png" style="width: 90%;">

You can see above that this deployed a CloudFormation template, which ended up creating a set of four IAM roles with permissions varying from ReadOnly to Administrative access via CloudFormation.

<img src="/images/cdk-roles.png" style="width: 60%;">

And if you look at the trust policies for these four roles you'll notice that each one is configured to trust the current account's root principal:

<img src="/images/cdk-role-trust-policy.png" style="width: 70%;">

For most accounts, this is a reasonable default, since typically only trusted users will have the required `sts:AssumeRole` permission in their identity policy.

However, as a SaaS provider that is using `sts:AssumeRole` to access customers' accounts, the threat model gets flipped upside down because we have an IAM role with full `sts:AssumeRole` access that we allow unauthenticated users partial control over. How this works for most SaaS providers is that during onboarding, the user can provide arbitrary role ARNs that the SaaS application attempts to assume. If the AWS API call is successful, as far as the application is concerned, the user owns the target AWS account. Authentication is effectively controlled by the target role, and whether the session's external ID, which is not user-controllable, matches the external ID in the trust policy.

So, reviewing the current state of the account:

* Our partially untrusted application role has full `sts:AssumeRole` permissions in the identity policy.
* The CDK roles, created during the bootstrap process, trust the current account's root principal, allowing access from any principal with appropriate `sts:AssumeRole` permissions (i.e., our untrusted role).
* These CDK roles do not implement `sts:ExternalID` protections since they aren't useful for the intended use case of these IAM Roles.

This means the attacker can onboard the SaaS provider's own AWS account using a trial SaaS account created by the attacker simply by specifying any of the CDK role's ARNs during the SaaS onboarding process. Once onboarded this way by the attacker, the SaaS application has its own AWS account associated with the attacker's SaaS trial account. The attacker now has full access to the SaaS provider's AWS account, limited by the capabilities of the SaaS platform and the permissions configured on these CDK roles.

### Is AWS CDK a Requirement Here?

No, I used AWS CDK as an example because it was the most common IAM Role type I found in my testing that led to the SaaS platform being vulnerable to this attack. More specifically, this attack is possible when any IAM role in the SaaS provider's AWS account is configured to trust the root principal of the same account, and does not explicitly implement `sts:ExternalID` protections.

This is a very common configuration; you'll likely see it when you need to create an IAM Role for more than one person. It is also created when you use any of the following tools:

* [AWS CDK](https://github.com/aws/aws-cdk)
* [AWS Landing Zone Accelerator](https://github.com/awslabs/landing-zone-accelerator-on-aws)
  * I believe this deploys CDK to all accounts in an org.
* [Copilot CLI](https://github.com/aws/copilot-cli)
* [Amplify V1](https://github.com/aws-amplify/amplify-cli)
* [Amplify V2](https://github.com/aws-amplify/amplify-backend)

The full list of tools is fairly long, and to make it worse, they do not include any warning that this kind of role is being created. If anyone has ever run CDK bootstrap in the SaaS provider account, then this attack is possible.

## The Attack Chain: From Onboarding to Takeover

The attack unfolds in four simple steps, requiring no prior authentication to the SaaS provider's AWS account.

**Step 1: Discovery**

The attack begins with finding a vulnerable IAM Role ARN within the SaaS provider's AWS account. Attackers don't need credentials for this; the SaaS provider's AWS Account ID is often provided in the account onboarding documentation, after which, you can use [awseye.com](https://awseye.com) or [unauthenticated role scanning](https://blog.ryanjarv.sh/2025/01/07/unauthenticated-role-scanning.html) to discover potential IAM Role ARNs that can be targeted.

The CDK bootstrap Roles are prime targets due to the widespread use of AWS CDK and because they follow a predictable naming pattern (e.g., `cdk-hnb659fds-lookup-role-{account-id}-{region}`), however, there is a number of tools that create similar predictable role names. The key is to find roles that are typically deployed with the trust policies set to trust the current account's root principal, which is what allows this attack to work.

**Step 2: Onboarding**

The attacker signs up for a standard free-tier account on the target SaaS platform.

**Step 3: Exploitation**

During the "connect your AWS account" flow, the SaaS platform asks for the ARN of a role in the customer's account. Instead of providing a role from their own account, the attacker inputs the ARN of the CDK lookup-role they discovered in the SaaS provider's own account. Any other role found in Step 1 can also be tested here.

**Step 4: Access**

The platform's internal proxy role successfully assumes the provided CDK role. The SaaS platform now treats its own AWS account as if it were a customer, exposing its infrastructure data to the attacker through the platform's dashboard.

**Root Cause Analysis**

This vulnerability isn't caused by a single misconfiguration, but by the dangerous interaction of two otherwise valid IAM policies. It's a classic case of a "context collapse," where a component designed for one purpose is used in a way its creators never intended.

**The CDK Bootstrap Role**

This role is created by cdk bootstrap with a trust policy that allows any principal within the same account to assume it. This is a common and secure configuration for its intended purpose—enabling CI/CD and other internal administrative tasks. Since this role is meant for internal use, its trust policy does not include an `sts:ExternalId` condition. It doesn't need one.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::SAAS_ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**The SaaS Proxy Role**

This is the role the SaaS platform uses to access all its customers' accounts. Its identity policy typically grants a broad `sts:AssumeRole` permission on Resource: "*". It relies on the customer to correctly configure their role's trust policy (with the SaaS account as Principal and a unique External ID) to be secure.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "*"
    }
  ]
}
```

**The Flaw: Context Collapse**

The vulnerability is not that `sts:ExternalId` is bypassed, but that it was never expected to be there. The attack works because the SaaS platform's proxy role—designed for external, cross-account access—is tricked into assuming an internal, administrative role. Because the CDK role's trust policy allows any same-account principal to assume it without an ExternalId, the `sts:AssumeRole` call succeeds, giving the attacker indirect access to the SaaS provider's account.


## Mitigation Strategies for SaaS Providers

Fortunately, fixing this vulnerability is straightforward. Here are the options, from most to least effective.

**Primary Fix: The Explicit Deny Policy (Recommended)**

The most effective solution is to add a Deny statement to the SaaS proxy role's identity policy. This explicitly forbids it from assuming roles within its own AWS account, preventing this and similar vulnerabilities entirely. The aws:ResourceAccount and aws:PrincipalAccount condition keys are AWS global conditions that compare the account ID of the resource being accessed with the account ID of the principal making the request, ensuring the policy only applies when the role is trying to assume another role in the same account.

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyIntraAccountRoleAssumption",
            "Effect": "Deny",
            "Action": "sts:AssumeRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceAccount": "${aws:PrincipalAccount}"
                }
            }
        }
    ]
}
```

This is also the same fix for the attack I covered previously in [Implicit SAR – Attacking the Confused Deputy](https://blog.ryanjarv.sh/sar/sar-6-confused-deputy.html) a while ago. I'd recommend also taking a look at that if you haven't already, as it can still affect SaaS providers that haven't taken any action.

**Secondary Mitigation: External ID Enforcement**

After publishing this, [Aidan Steele](https://x.com/__steele) reminded me that another mitigation applies here: if you ensure all customer roles have a `sts:External` condition present, then attempting to register the CDK bootstrap role won't work as it does not enforce any specific `sts:ExternalId`.

The process for enforcing customer use of the `sts:ExternalId` conditional is the following:

1. Try to assume the role without providing an external ID. This should fail.
    * If step #1 doesn't get an AccessDenied, alert the user and refuse to complete the onboarding.
2. Try to assume the role with the correct external ID. This should pass.
    * If step #2 fails, alert the user and provide additional information on how to proceed with onboarding.

If this process is followed, an attacker attempting to onboard the CDK bootstrap roles should never make it to step 2, resulting in the attack failing.

**Alternative: Bootstrap Null Condition**

This alternative was suggested by AWS, and is the mitigation that is present in the AWS CDK CLI 2.1026.0 ([PR](https://github.com/aws/aws-cdk-cli/pull/811/files)). It's not clear to me if this mitigation is applied automatically or not, so for the moment I'd recommend checking this manually.

By adding a Null condition with `sts:ExternalId` set to `true` to all the bootstrap roles that trust the root principal (there should be four), inbound assume role requests that have an external ID present will be denied access.

```json
{
	"Version": "2008-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::123456789012:root"
			},
			"Action": "sts:AssumeRole",
			"Condition": {
				"Null": {
					"sts:ExternalId": "true"
				}
			}
		},
		{
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::123456789012:root"
			},
			"Action": "sts:TagSession"
		}
	]
}
```

However, if you allow users full control over the ExternalID you may not want to avoid relying on this prevention. If you do, and cannot fix it right now, I'd recommend verifying this mitigation works as expected and that an attacker cannot coerce the backend into not sending a `sts:externalId` value (note that sending an empty string isn't enough due to server-side parameter validation). This is a separate topic, but I'd highly recommend avoiding giving anyone full control of the ExternalID in any situation; your customers can't protect themselves if you do.

## Guidance for AWS CDK Users

Even if you don't run a SaaS platform, you should be deliberate about the roles cdk bootstrap creates. You can lock down the bootstrap roles from the start by using the --trust flag to specify which principals are allowed to assume them.

> cdk bootstrap --trust <specific_role_arn_or_account_id>

## Have You Found This Vulnerability in The Wild?

Yes, I've found and reported this specific vulnerability to several SaaS platforms.

## A Note for Security Researchers: How to Test Responsibly

If you are a bug bounty hunter or security researcher testing for this vulnerability, you must confirm its existence without accessing any data from the target account. The goal is to prove that the role is assumable, then stop and report immediately.

A key part of this is establishing a baseline for what "success" and "failure" look like in the target SaaS application's UI.

* **Establish a "Success" Baseline:** 
    * To see what a successful connection looks like without using a real, sensitive role, you can use a harmless test role. I built a simple tool for this exact purpose: [Assume Role ID](https://github.com/RyanJarv/assume-role-id/tree/main). It provides a publicly assumable role that you can use to see the application's behavior upon a successful `sts:AssumeRole` call.

* **Establish a "Failure" Baseline:** 
    * Next, find out what an unsuccessful connection looks like. Simply attempt to connect the SaaS platform to a non-existent role ARN, such as arn:aws:iam::123456789012:role/ThisRoleDoesNotExist.

* **Test the Target Role:** 
    * Now that you have both baselines, you can test the suspected vulnerable role.

If the application's response matches your failure baseline, the account is likely not vulnerable to that specific role.

If the application's response matches your success baseline, you have likely confirmed the vulnerability.

At this point, you must stop. Do not proceed to view or interact with any data. Take a screenshot, document your findings, and report them immediately. The source code for the Assume Role ID tool is [available on GitHub](https://github.com/RyanJarv/assume-role-id/tree/main).

## Conclusion: A Lesson in Defense-in-Depth

This vulnerability serves as a powerful reminder that security configurations that are perfectly safe in one context can become critical risks in another. A standard CDK bootstrap role, harmless on its own, became the key to a potential account takeover when placed in the environment of a multi-tenant SaaS platform.

The core lesson is that SaaS providers must be vigilant not only about securing customer access but also about protecting their own infrastructure from being accessed through their own platform. The principle of least privilege applies everywhere.


## AWS's Response and Last Words

I sent this blog post over to AWS Security before publishing it, and they responded with the following:

```aws
"AWS can confirm that AWS Cloud Development Kit (AWS CDK) bootstrap roles are functioning as designed for their intended use case of internal account operations. The issue described in this blog is not an issue with CDK itself, but with SaaS applications that are configured with overly broad cross-account role assumption policies. Applications that perform cross-tenant authentication must configure their IAM policies to prevent unintended roles, such as those in the same account, from being accidentally assumed.

To better accommodate this use case, in AWS CDK CLI 2.1026.0 the default bootstrap template has been updated with a stricter assume role policy to prevent calls that are intended to access Roles in other accounts, as indicated by the ExternalId parameter, from assuming Roles in the same account. This update prevents this issue with no additional design work required by SaaS vendors."
```

I also want to add that I agree with their stance here. This post was written considering how this situation can come as a surprise from the user's perspective. However, security is often surprising, so this change is a step in the right direction. It seems they got the update out pretty quickly, too. I was surprised to see this policy already in my account. I just bootstrapped yesterday.

Lastly, I want to thank @z0dd from the critical-thinking discord channel for taking the time to review this post.
