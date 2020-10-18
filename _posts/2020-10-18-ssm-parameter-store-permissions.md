---
layout: post
title: SSM Parameter Store Permissions
---

{{ page.title }}
================

<p class="meta">18 October 2020 - Somewhere</p>
I was looking into listing access to SSM Parameter Store secrets and noticed that it is not possible to deny list parameters based on a path due to GetParametersByPath's recursive argument.

Say you want to allow an IAM user access to all parameters except those under /restricted you might try using a policy like this.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAll",
            "Effect": "Allow",
            "Action": "ssm:*",
            "Resource": "arn:aws:ssm:*:253528964770:parameter/*"
        },
        {
            "Sid": "DenyRestricted",
            "Effect": "Deny",
            "Action": "ssm:*",
            "Resource": "arn:aws:ssm:*:253528964770:parameter/restricted"
        },
        {
            "Sid": "DenyRestrictedGlob",
            "Effect": "Deny",
            "Action": "ssm:*",
            "Resource": "arn:aws:ssm:*:253528964770:parameter/restricted/*"
        }
    ]
}
```

At first glance it might seem like this would achieve what we want here since Deny statements take priority over Allow. This however can be bypassed fairly easily by running `aws ssm get-parameters-by-path --path / --recursive`, which will return all parameters including one's under /restricted.

Unfortunately this behavior is fairly easy to miss but for what it's worth there is a note about it the [API GetParametersByPath docs](https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_GetParametersByPath.html#systemsmanager-GetParametersByPath-request-Recursive).

If you need to work around this issue I suspect handling access through KMS is the best option.
