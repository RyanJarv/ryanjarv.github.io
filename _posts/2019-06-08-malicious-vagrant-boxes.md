---
layout: post
title: Malicious vagrant boxes
---

{{ page.title }}
================

<p class="meta">8 June 2019 - Mojave Desert</p>
Hey so did you know by default vagrant run's VM's in the same security context as your host operating system! Kinda wild right? So does that mean that if you tested a strange and unknown vagrant box off https://app.vagrantup.com/boxes/search you might be pwned? Absolutely!

"WTF?"

You might be asking. WTF indeed.

The issue is pretty straight forward, for some reason vagrant mounts the code directory inside the VM as read/write. Normally the VM would be running your code so this wouldn't be much of a concern however this directory also contains the Vagrantfile configuration, which of course is just a ruby script and is executed everytime you run `vagrant` on the host.

Kinda crazy right?

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
Welcome to Ubuntu Eoan Ermine (development branch) (GNU/Linux 5.0.0-15-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sat Jun  8 08:06:42 UTC 2019

  System load:  0.0               Processes:             111
  Usage of /:   11.5% of 9.63GB   Users logged in:       1
  Memory usage: 18%               IP address for enp0s3: 10.0.2.15
  Swap usage:   0%

 * Ubuntu's Kubernetes 1.14 distributions can bypass Docker and use containerd
   directly, see https://bit.ly/ubuntu-containerd or try it now with

     snap install microk8s --classic

0 updates can be installed immediately.
0 of these updates are security updates.


Last login: Sat Jun  8 07:59:53 2019 from 10.0.2.2
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

Now I've been meaning to make a post about this for some time, when I originally noticed this it was very difficult to find *any* mention of this which is a bit unfortantate. For a while I've been using the following workaround, which I admit isn't ideal.. but still works.

```
  config.vm.synced_folder ".", "/vagrant", disable: true
  config.vm.synced_folder "vagrant", "/vagrant"
```
This will move the shared folder to a subfolder named vagrant under the main directory, which includes the Vagrantfile config.


Just now though when I was writing this I was surprised to notice this warning that pops up when you download run `vagrant up` and the box doesn't exist on your computer yet.

```
Vagrant is currently configured to create VirtualBox synced folders with
the `SharedFoldersEnableSymlinksCreate` option enabled. If the Vagrant
guest is not trusted, you may want to disable this option. For more
information on this option, please refer to the VirtualBox manual:

  https://www.virtualbox.org/manual/ch04.html#sharedfolders

This option can be disabled globally with an environment variable:

  VAGRANT_DISABLE_VBOXSYMLINKCREATE=1

or on a per folder basis within the Vagrantfile:

  config.vm.synced_folder '/host/path', '/guest/path', SharedFoldersEnableSymlinksCreate: false
```

So it seems like this has been added more recently and there may be a better option to prevent this issue. Let's try it.

```
host$ sed -i -e "/config.vm.box =/a\ 
config.vm.synced_folder '.\/', '\/vagrant', SharedFoldersEnableSymlinksCreate: false" Vagrantfile    # Add suggested line to config just after the config.vm.box line
host$ sed -i -e "/exec/d" Vagrantfile    # Delete exec('bc') line
host$ vagrant up --provision
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Checking if box 'ubuntu/eoan64' version '20190605.0.0' is up to date...
==> default: Clearing any previously set forwarded ports...
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...

** snip **
host$ vagrant ssh
Welcome to Ubuntu Eoan Ermine (development branch) (GNU/Linux 5.0.0-15-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sat Jun  8 09:00:07 UTC 2019

  System load:  0.56              Processes:             118
  Usage of /:   11.5% of 9.63GB   Users logged in:       0
  Memory usage: 16%               IP address for enp0s3: 10.0.2.15
  Swap usage:   0%

 * Ubuntu's Kubernetes 1.14 distributions can bypass Docker and use containerd
   directly, see https://bit.ly/ubuntu-containerd or try it now with

     snap install microk8s --classic

0 updates can be installed immediately.
0 of these updates are security updates.


Last login: Sat Jun  8 08:06:42 2019 from 10.0.2.2
vagrant@ubuntu-eoan:~$ ls /vagrant/
vagrant@ubuntu-eoan:~$ sudo touch /vagrant/asdf
vagrant@ubuntu-eoan:~$ ls -lah /vagrant/
total 8.0K
drwxr-xr-x  2 root root 4.0K Jun  8 09:00 .
drwxr-xr-x 20 root root 4.0K Jun  8 08:59 ..
-rw-r--r--  1 root root    0 Jun  8 09:00 asdf
vagrant@ubuntu-eoan:~$ logout
Connection to 127.0.0.1 closed.
host$ ls -lah
total 8
drwxr-xr-x   4 jarv  wheel   128B Jun  8 02:01 .
drwxrwxrwt  15 root  wheel   480B Jun  8 02:01 ..
drwxr-xr-x   4 jarv  wheel   128B Jun  8 00:33 .vagrant
-rw-r--r--   1 jarv  wheel   3.0K Jun  8 01:52 Vagrantfile
host$ 
```

So it looks like that fixes the issue, but also doesn't seem to share the code directory.. which limit's the usefullness of vagrant I would imagine. Ideally I think the share should just mount as readonly, seems like the simplest safe solution.
