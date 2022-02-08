---
layout: post
title: Personal Coding Projects
---

{{ page.title }}
================

<p class="meta">07 Feb 2021 - NW</p>

The project list on my resume has been getting kind of long recently and it's a bit difficult to decide
what I should keep and what should go. I also can't exactly link to the repo list in GitHub since
that contains a lot of uninteresting forks that I needed for PR's or things like that. So this post is
just a list of things that I think are interesting but may have not made it on to my resume (in no
particular order).

## GoLang

* [liquidswards](https://github.com/RyanJarv/liquidswards) -- Know, don't guess, who can access what (IAM Roles).
* [lq](https://github.com/RyanJarv/lq) -- An exactly once, in-order queue that delivers both past and future messages to all subscribers.
* [UserDataSwap](https://github.com/RyanJarv/UserDataSwap) -- Example of how an attacker might swap user data temporarily to execute arbitrary commands
* [ditto](https://github.com/RyanJarv/ditto) -- Mimic any command
* [EC2FakeImds](https://github.com/RyanJarv/EC2FakeImds) -- PoC based on https://blog.ryanjarv.sh/2020/10/19/imds-persistence.html
* [cli-hijacker](https://github.com/RyanJarv/cli-hijacker) -- Fork of aws-vault for the cli-hijacker PoC.
* [coderun](https://github.com/RyanJarv/coderun) -- Running scripts in an isolated environment should be stupid easy.
* [dockersnitch](https://github.com/RyanJarv/dockersnitch) -- Like little snitch but for docker
* [gocash](https://github.com/RyanJarv/gocash) -- Redis like cashier service in GoLang
* [RhinoSecurityLabs/amazon-ssm-agent](https://github.com/RhinoSecurityLabs/amazon-ssm-agent) -- Fork of amazon-ssm-agent that can run as any user in parallel with the official service.

## Python
* [dsnap](https://github.com/RhinoSecurityLabs/dsnap) -- Utility for downloading and mounting EBS snapshots using the EBS Direct API's
* [marionette](https://github.com/RyanJarv/marionette) -- Active/Passive UserData swap PoC
  * This is a rewrite of UserDataSwap which solves some issues that came up in practice.
* [steampipe_alchemy](https://github.com/RyanJarv/steampipe_alchemy) -- SQLAlchemy wrapper around Steampipe.
* [aws_session_recorder](https://github.com/RyanJarv/aws_session_recorder) (Python) -- AWS session that records discovered resources to a database
* [awsconfig](https://github.com/RyanJarv/awsconfig) -- AWS Config rules for non-default IMDS routes (partially obsolete)
* [nettomidi](https://github.com/RyanJarv/nettomidi) -- Net -> MIDI (Listen to your network!)
* [pingscan](https://github.com/RyanJarv/pingscan/blob/master/pingscan.py) -- Messing around with sockets
* [msh](https://github.com/RyanJarv/msh) -- Multivac Shell

## Other
* [randrust](https://github.com/RyanJarv/randrust) -- Rust HTTP server that returns random bytes encoded with base64
* [puppet-randrust](https://github.com/RyanJarv/puppet-randrust) -- Puppet module for randrust
* [minecraft_server](https://github.com/RyanJarv/minecraft_server) -- Chef repo for creating a Minecraft server in AWS
* [awesome-cloud-sec](https://github.com/RyanJarv/awesome-cloud-sec) -- Awesome list for cloud security related projects.

## Maintainer and Significant Contributor
* [Pacu](https://github.com/RhinoSecurityLabs/pacu) -- The AWS exploitation framework, designed for testing the security of Amazon Web Services environments.
* [CloudGoat](https://github.com/RhinoSecurityLabs/cloudgoat) -- CloudGoat is Rhino Security Labs' "Vulnerable by Design" AWS deployment tool
* [sous-chefs/varnish](https://github.com/sous-chefs/varnish) -- Chef Development repository for the varnish cookbook
