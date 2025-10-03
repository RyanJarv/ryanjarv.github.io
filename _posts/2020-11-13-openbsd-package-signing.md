---
layout: post
title: That time I complained about OpenBSD Package Signing and They Fixed It
---

{{ page.title }}
================

<p class="meta">13 November 2020 - Somewhere</p>

Around 2013ish (? give or take) OpenBSD (pre 5.5) evidently did not support signed packages via pkg_add, or at least not in a way that mattered. According to the documentation there was support for signatures but they where not explicitly enforced. As in you can use pkg_add to download a package, and it will verify the signature if it exists, but if it doesn't than that's cool too.

This of course defeats the purpose of signing, assuming an attacker can modify packages, you also have to assume they can simply remove the signature. This baffled me, enough so that I decided to stick with FreeBSD a while longer. I was also fairly new to the IT field and the knowledge that everything is a hack hadn't quite set in yet, even somethings in the notoriously secure OpenBSD I had heard so much about.

Anyways, I posted about this on twitter at the time, my core beliefs where shaken and I was scared.. so who knows what I said. My tweet got some attention from some OpenBSD Devs, I don't remember what I said exactly but it seemed like the tweet might have gotten to get to the right person because it wasn't too long after that the issue was resolved with the addition of signify(1).

I'll try to find that twitter post, since I'm really curious if that was what prompted this change. Maybe it'll be amongst some old backups, will see.

On second thought I suppose it's gotta be online somewhere, it is the Internet after all.

<p class="meta">pkg_add(1) history</p>



In OpenBSD 5.4 and before [pkg_add](https://man.openbsd.org/OpenBSD-5.4/pkg_add.1) you have the -D nosig option, which I believe only disables signing on a signed package and has no effect on non-signed packages.

```
nosig    do not check digital signatures. Still displays a very prominent message if a signature is found.
```

The key is the first line in this paragraph:

```
If a package is digitally signed:

pkg_add checks that its packing-list is not corrupted and matches the cryptographic signature stored within.
pkg_add verifies that the signature was emitted by a valid user certificate, signed by one of the authorities in /etc/ssl/pkgca.pem
pkg_add verifies that each file matches its sha256 checksum right after extraction, before doing anything with it.
pkg_add verifies that any dangerous mode or owner is registered in the packing-list.
In normal mode, the package names given on the command lines are names of new packages that pkg_add should install, without ever
```

And if it's not signed ¯\_(ツ)_/¯


So then in [5.5](https://man.openbsd.org/OpenBSD-5.5/pkg_add.1) we get the -D nounsigned option:

```
unsigned   allow the installation of unsigned packages without warnings/errors (necessary for ports(7), automatically set by the build infrastructure).
```

Which makes me think that this is when they decided to start deprecating this behaivor.

Then in OpenBSD 6.1 we find the following in pkg_add(1):
```
By default, pkg_add enforces signed packages, except if they come from a trusted source (TRUSTED_PKG_PATH) or if -Dunsigned is specified.
```

<p class="meta">Enough picking on OpenBSD</p>

I'll wrap this up with giving them a bit a slack, handling packaging in the BSD systems around that time typically wasn't done like we think of it in most linux systems. The recommended way to install anything I believe is to build it from source, or install it from local media. So the whole pkg_add thing for both OpenBSD and FreeBSD at the time seems more like a rough edge newbies might cut them selfs on more then anything, but that's kinda just my guess.

But really it wasn't just OpenBSD that got in the poor habit of weak or even no package validation.

If you take a look at FreeBSD's [pkg_add(1)](https://www.freebsd.org/cgi/man.cgi?query=pkg_add&apropos=0&sektion=0&manpath=FreeBSD+9.3-RELEASE&arch=default&format=html) (something I know a little more about) there's no mention of any signing there either, granted they at least had a clear warning in the man page. At the time the recommendation was mostly the same as OpenBSD, build everything through ports, which has a robust validation system and use pkg_add for local media (or something along those lines).

FreeBSD did also do a quick switch to to the much much nicer [pkg(1)](https://www.freebsd.org/cgi/man.cgi?query=pkg&apropos=0&sektion=0&manpath=FreeBSD+10.0-RELEASE&arch=default&format=html) in the next release, and validation is documented on the 10.1 release (although I believe it existed on 10.0 as well, not positive).

Oh and can't forget about Arch Linux, I never used that though so can't say too much there. Similar issue though from what I recall, just no verification on install.

Occasionally I see package validation disabled on various systems for various reasons, feel like it's more common with RHEL then Debian. But idk, that's a different thing I guess.

<p class="meta">Take aways</p>

Package validation was in a poor state for a lot of systems around 2013'ish.

Many people worked to fix this around that same time as well, likely tirelessly. Despite me dragging up the past here, I'm very appreciative of the hard work put in here. I won't say much I don't know but, I do know OpenBSD's signify(1) and FreeBSD's pkg(1) where not trivial tasks.

Maybe I should mess around with OpenBSD sometime here.. or really any of the BSD's. It's been a while.

I really wonder now if my tweet actually did have an effect on getting this resolved, or if it was just a coincidence. Would be pretty cool if it did.









