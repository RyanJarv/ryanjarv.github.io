---
layout: post
title: VirtualBox NAT and your Loopback Interface
---

{{ page.title }}
================

<p class="meta">19 October 2020 - Somewhere</p>
I'm just catching up on old posts that I should have written a while ago, and of course this is no different. I actually almost forgot about this, somehow, unfortunately, because it is actually pretty important if you use VirtualBox for compartmentalization.

###  Overview and quick fix

To keep things brief if you using a guest VM guest like [Tails](https://tails.boum.org/) with VirtualBox to provide anonymity you should go to your settings and make sure you are not using the "NAT" interface type. If you never changed this manually, it is most likely set up this way.

###  The Issue

The default configuration of VirtualBox allows the guest to access the hosts loopback adapter.

So what does this mean?

Say you're running [Tails](https://tails.boum.org/) in VirtualBox on your laptop you use for day to day work. An attacker somehow is able to open socket's to the 10.0.2.2 address from within the VM.

Sending packets to this magical IP from within the VM show's up on the host as packet's from localhost <-> localhost

So when we connect from within the guest VM to 10.0.2.2:6942 like so:

<img src="{{site.baseurl}}/images/tails.png">

We'll see something like this when running tcpdump on the host's loopback adapter.

```
07:34:15.998866 IP localhost.55231 > localhost.6942: Flags [F.], seq 1, ack 121, win 6377, options [nop,nop,TS val 789867426 ecr 789867426], length 0
```

In the picture above you can see I left GoLand running on my host machine which apparently likes to spit out my name in it's path. This was only the fist port I attempted, far too many app's make the assumption that localhost is safe. Getting RCE on the host from this position would likely not be too difficult.

So given that an attacker can hit that port, through JavaScript or RCE to the guest machine they can start probing port's that are only bound to your hosts loopback adapter. 

From my understanding (which granted is fairly limited) this happens because the NAT driver in VirtualBox is emulated entirely in software. There's no difference between packets coming from the NAT software itself and any other program on your host, so all apps regardless of if they are running on your Host or in the VM have access to the hosts loopback device.

This behavior is pretty convenient from an attackers perspective since access can't easily be blocked like you would if VirtualBox was using the hosts networking stack. Here you can see I had the MacOS firewall on the strictest settings.

<img src="{{site.baseurl}}/images/macos_firewall.png">

Little Snitch seems to have the same issue as far as I can tell. It simply doesn't work on traffic to and from lo0. Blocking in /etc/pf.conf seems to work but I'm not sure if pf can block connections from a specific source app and not others. Either way though it seems the point is simply, not to use the default NAT settings in VirtualBox if you want any compartmentalization between the guest and host.

I reached out to Oracle support about this issue but unfortunately this is working as intended according to them. Oracle however did update the documentation to make it clear the NAT adapter allows access to lo0 from the guest.

One option that I didn't bring up when talking to them before is to create another non localhost IP on the loopback and bind to that instead. I'll have to think about that some more though.

Anyways, don't forget to switch the network type when setting up a new VM. Also if you found this post interesting you may want to also check out my post on malicious [vagrant boxes](https://blog.ryanjarv.sh/2019/06/08/malicious-vagrant-boxes.html)
