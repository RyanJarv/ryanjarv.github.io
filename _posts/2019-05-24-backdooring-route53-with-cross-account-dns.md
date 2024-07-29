---
layout: post
title: Backdooring Route 53 With Cross Account DNS
---

{{ page.title }}
================

## Update

This issue is now resolved with the [announcement](https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListHostedZonesByVPC.html) of the [ListHostedZonesByVPC](https://docs.aws.amazon.com/Route53/latest/APIReference/API_ListHostedZonesByVPC.html) Route53 API action!

## Original

<p class="meta">13 May 2019 - Somewhere</p>

Back in late 2017, I was working on writing the notably missing [aws_route53_&shy;vpc_association_authorization](https://github.com/terraform-providers/terraform-provider-aws/pull/2005) provider for terraform AWS when I ran into a fairly annoying issue with the cross-account Route 53 hosted zone association process: The Route 53 API in a cross-account setup can only display hosted zone association info when calling from the hosted zone account.

This is a problem for scripting when you need to verify the state of the association without access to both accounts but the bigger and perhaps less obvious problem is it can be abused to provide persistent control over DNS from another AWS account. There isn't a whole lot to this attack, the only assumption is that the attacker, or possibly disgruntled employee, deviant third-party contractor, etc.., has at one point had access to the account. Interestingly this attack is a side effect of how the API was designed and we won't be doing much other than setting up the resources how they were designed to be used, the important part is simply that the main owner of the account isn't told, or otherwise alerted possibly through API call logging that these resources were set up.

So what does this look like?
  1. The attacker has access to the victim's account as well as their own evil account.
  2. In the evil account, a hosted zone is created for the domain www.example.com, and a CNAME pointing to www.evil-attacker.com
  2. CreateVPCAssociationAuthorization is run in the attacker's account, and Associate&shy;VPCWithHostedZone in the victim's account to finish the association between the evil hosted zone and the victim's VPC.

Now when any node using dynamic DNS in the victim's VPC makes a request for 'www.example.com' the malicious record with the CNAME www.evil-attacker.com is returned. This is of course expected since this is the normal process to share hosted zones across accounts. The problem is the owner of the main account doesn't have access to the evil account or any ability to enumerate it, preventing any way of auditing the configuration of this shared hosted zone through the API.

(Note: <s>I've recently heard this actually shows up in the web interface. I haven't verified this but if it's the case then this issue is limited to using the API. This is fairly common though as you can't expect people to manually go through dozens of accounts and verify resources manually.</s> Looking into this again I haven't been able to find where this might show up, seems for now the best option is to watch for this API call via CloudWatch.)

So how does enumeration of these resources work currently?

There is the GetHostedZone call but it requires read access to the hosted zone along with the ID of the hosted zone.

So assuming you did know the ID (which you won't) this is what you end up getting through the API.
```wrap
aws route53 get-hosted-zone --id /hostedzone/Z2A3GARM5EV7XX An error occurred (AccessDenied) when calling the GetHostedZone operation: User: arn:aws:sts::633876015373:assumed-role/OrganizationAccountAccessRole/1557793151797411000 is not authorized to access this resource
```

ListHostedZones in the target or victim account doesn't show anything, which is unfortunately misleading. In this example, I currently have a cross-account hosted zone associated with one of my VPCs redirecting traffic from www.example.com to www.evil-attacker.com.
```
aws route53 list-hosted-zones
{
    "HostedZones": []
}
```

Same with ListHostedZonesByName
```
aws route53 list-hosted-zones-by-name
{
    "HostedZones": [],
    "IsTruncated": false,
    "MaxItems": "100"
}
```

Can't run ListVPCAssociationAuthorizations of course, this is meant to be run by the hosted zone account.

```bash
aws route53 list-vpc-association-authorizations --hosted-zone-id Z2A3GARM5EV7XX
An error occurred (AccessDenied) when calling the ListVPCAssociationAuthorizations operation: User: arn:aws:sts::633876015373:assumed-role/OrganizationAccountAccessRole/1557793151797411000 is not authorized to access this resource
```

You can still attach other hosted zones just like you normally would (sorry no example for this right now).

You can dissociate *if* you somehow know the hosted zone ID. However unfortunately this can also be prevented by the attacker by leaving your VPC as the only one attached to the zone.

From the CLI help page on disassociate-vpc-from-hosted-zone:
```
DESCRIPTION
       Disassociates  a  VPC  from a Amazon Route 53 private hosted zone. Note
       the following:

       o You can't disassociate the last VPC from a private hosted zone.
```

And trying this results in the following:
```wrap
aws route53 disassociate-vpc-from-hosted-zone --vpc 'VPCRegion=us-west-1,VPCId=vpc-bde6deda' --hosted-zone-id Z2A3GARM5EV7XX An error occurred (LastVPCAssociation) when calling the DisassociateVPCFromHostedZone operation:Cannot remove last VPC association for the private zone
```

Checkmate. The attacker controls DNS without risk of being detected through the API. Furthermore, dissociation can be prevented by the attacker, requiring manual intervention from AWS support.

Note: This was reported and acknowledged by AWS security when I originally discovered the issue, I'm not currently aware of any timeline for fixing it. <s>I also want to mention again here that it seems this isn't an issue through the web console, so it is possible to manually verify your account isn't affected by this.</s> Looking into this again I haven't been able to find where this might show up. I think for now the best option is to watch for this API call via CloudWatch. There is some discussion about this on [Twitter](https://twitter.com/0xdabbad00/status/1225452593234640897?s=20) as well.

Back to the original problem, this is the core issue around implementing the route53_hosted_zone_association resource in terraform in a cross-account configuration. More specifically, we need to verify the current state of the hosted zone account while configuring the resource in the target account. This is something that doesn't map well to Terraform's state-tracking CRUD model where each resource is a connection to a single account.

