---
layout: post
title: Backdooring Route 53 With Cross Account DNS
---

{{ page.title }}
================

<p class="meta">24 Dec 2016 - Somewhere</p>
Back in late 2017 I was working on writing the notably missing [aws_route53_vpc_association_authorization](https://github.com/terraform-providers/terraform-provider-aws/pull/2005) provider for terraform AWS when I ran into a fairly annoying issue with the cross account Route 53 hosted zone association process. The Route 53 API in a cross account setup can only display hosted zone association info when calling from the hosted zone account. This is a headache for verifying the state of the association from the reviewing account the bigger and perhaps less obvious problem is it allows an attacker to add a backdoor in DNS while they have access for use later after they are removed from the account. The persistent access is due to the lack of ability to show zone info in the vpc account, the owner is not able to view these resources to beable to remove them.

This is fairly concerning since it means unless you have audited all Route53 API calls back to account creation it is not possible to know if another account is injecting malicious DNS resolutions into your VPC (TODO: look into dns logging for detecting this).

The process for this issue is as follows:
  1. Attacker has access to the victim account as well as their own evil account.
  2. In the evil account a hosted zone is created for the domain www.example.com and a CNAME pointing to www.evil-attacker.com
  2. CreateVPCAssociationAuthorization is run in the attacker's account, and AssociateVPCWithHostedZone in the victim's account to finish the association between the evil hosted zone and the victim's VPC.

Now when any node using dynamic DNS in the victim's VPC makes a request for 'www.example.com' the malicious record with the CNAME www.evil-attacker.com is returned. This is of course expected since this is the normal process to share hosted zone's across accounts. The problem is simply the victim who doesn't have access to the evil account or even know it exists, doesn't have any way of auditing the configuration of this shared hosted zone.

 There is the GetHostedZone and GetHostedZoneByName calls but they require read access to the hosted zone, an issue for terraform since it will be connecting to the receiving account.

the state of associated hosted zones to VPC’s when connecting to the account receiving the hosted zone share.  terraform's route53_zone_association resource needs to use GetHostedZone's output of associated VPC’s to determine if the zone is still attached to our given VPC.

ListHostedZones in the victims account doesn't show anything..
```
aws> route53 list-hosted-zones
{
    "HostedZones": []
}
```

Same with ListHostedZonesByName
```
aws> route53 list-hosted-zones-by-name
{
    "HostedZones": [],
    "IsTruncated": false,
    "MaxItems": "100"
}
```

Can't use GetHostedZone since the victim wouldn't know the hosted zone id, but assuming they somehow did the victim account can't read it anyways.
```wrap
aws> route53 get-hosted-zone --id /hostedzone/Z2A3GARM5EV7XX
An error occurred (AccessDenied) when calling the GetHostedZone
operation: User: arn:aws:sts::633876015373:assumed-role/Organization
AccountAccessRole/1557793151797411000 is not authorized to access
this resource
```

You can still attach other hosted zone's just like you normally would.
Can't run ListVPCAssociationAuthorizations of course
```
aws> route53 list-vpc-association-authorizations --hosted-zone-id 
Z2A3GARM5EV7XXAn error occurred (AccessDenied) when calling the 
ListVPCAssociationAuthorizations operation: User: arn:aws:sts::
633876015373:assumed-role/OrganizationAccountAccessRole/1557793151797411000
is not authorized to access this resource
```

You can dissacociate *if* you somehow know the hosted zone id.

However unfortunately if the attacker leaves your VPC as the only one attached to the zone it will prevent you from removing it even if you had the zone id by chance.
```
aws> route53 disassociate-vpc-from-hosted-zone --vpc 'VPCRegion=us-west-1,\
VPCId=vpc-bde6deda' --hosted-zone-id Z2A3GARM5EV7XX
An error occurred (LastVPCAssociation) when calling the 
DisassociateVPCFromHostedZone operation:Cannot remove last VPC association 
for private zone
```
