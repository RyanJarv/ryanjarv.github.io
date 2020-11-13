---
layout: post
title: VirtualBox NAT and your Loopback Interface
---

{{ page.title }}
================

<p class="meta">19 October 2020 - Somewhere</p>
I'm just catching up on old posts that I should have written a while ago, and of course this is no different. I actually almost forgot about this, but it is very important if you use VirtualBox for compartmentalization.

###  Overview and quick fix

To keep things brief if you using a guest VM like [Tails](https://tails.boum.org/) and VirtualBox to provide anonmity you should go to your settings and make sure you are not using the "NAT" interface type. If you never changed this manually, it is most likely set up this way.

###  The Rest

The default configuration of VirtualBox allows the guest to access the hosts loopback adapter.

So what does this mean?

Say you're running [Tails](https://tails.boum.org/) in VirtualBox on your laptop you use for day to day work.

<img src="{{site.baseurl}}/images/tails.png">

Unfortunately I left GoLand running here on my host machine which apparently likes to spit out my name it's path. So given that an attacker can hit that port, through JavaScript or RCE to the guest machine they can start probing port's that are only bound to your hosts loopback adapter.

From my understanding (which granted is fairly limited) this happens because the NAT driver in VirtualBox is emulated entirely in software. There's no difference between packets coming from the NAT software itself and any other program on your host, so all apps regardless of if they are running on your Host or in the VM have access to the hosts loopback device.

This behavior is pretty convenient from an attackers perspective since access can't easily be blocked like you would if VirtualBox was using the hosts networking stack. Here you can see I had the MacOS firewall on the strictest settings.

<img src="{{site.baseurl}}/images/macos_firewall.png">

I also run Little Snitch and that too unfortunately doesn't do us much good here. After messing with the settings here for a while I haven't had any success in blocking this connection. Another thing to note is the connection doesn't show up on the network monitor either. Seems little snitch simply doesn't work for traffic to the loopback adapter.

Blocking in /etc/pf.conf seems to work but I'm not sure if pf can block connections from a specific source app and not others.

Either way though it seems the point is simply, not to use the default NAT settings in VirtualBox if you want any compartmentalization between the guest and host.

I reached out to Oracle support about this issue but unfortunately this is working as intended according to them. On top of that from some looking around on the web it seems various people use this as a feature here and there.

One option that I didn't bring up when talking to them before is to create another non localhost IP on the loopback and bind to that instead. I'll have to think about that some more though.

Anyways, don't forget to switch the network type when setting up a new VM. Also if you found this post interesting you may want to also check out my post on malicious [vagrant boxes](https://blog.ryanjarv.sh/2019/06/08/malicious-vagrant-boxes.html)
