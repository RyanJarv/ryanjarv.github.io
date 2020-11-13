---
layout: post
title: Why I didn't switch OpenBSD (in 2013)
---

{{ page.title }}
================

<p class="meta">13 November 2020 - Somewhere</p>
I'll admit this is a bit strange for me to bring up now, it's already been 7 years. But the thing is I need a job.. so I'm going back and digging up any scraps I can pass off as some meager claim to fame.

To be clear this issue has been fixed in OpenBSD for quite some time now, specifically with the addition of signify(1) iirc. And fair warning I never actually tested this, maybe I should go back and try this before I speak to confidentally, so worth taking all this with a grain of salt.. writing mostly from memory here. At the very least though, whether right or wrong this is why I never ended actually digging into OpenBSD too much.

Around 2013ish (? give or take) OpenBSD (pre 5.5) evidently did support sign packages via pkg_add, but they where not explicitly enforced. As in you can use pkg_add to download a package, and it will verify the signature if it exists, but if it doesn't then that's not an issue either.

This clearly defeats the purpose of signing, assuming an attacker can modify packages, you also have to assume they can simply remove the signature. This baffled me, enough so that I decided to stick with FreeBSD a while longer. I was also fairly new to the IT field and the knowledge that everything is a hack hadn't quite set in yet, even somethings in the notariously secure OpenBSD I had heard so much about.

Anyways I posted about this on twitter at the time, my core beliefs where shaken and I was scared.. so who knows what I said. My tweet got some attention from some OpenBSD devs, I don't remember much about for what it's worth it did seem like the tweet might have gotten to get to the right person since it wasn't too long after that the issue was resolved with the addition of signify(1). 

<p class="meta">pkg_add(1) history</p>

I'll try to find that twitter post, since I'm really curious if that was what prompted this change.


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

I'll wrap this up with giving them a bit a slack, handling pkg'ing in the BSD systems around that time typically wasn't done like we think of it in most linux systems. The recommended way to install anything I believe is to build it from source, or install it from local media. So the whole pkg_add thing for both OpenBSD and FreeBSD at the time seems more like a rough edge newbies might cut them selfs on more then anything, but that's kinda just my guess.


And not surprisingly if you take a look at FreeBSD's [pkg_add(1)](https://www.freebsd.org/cgi/man.cgi?query=pkg_add&apropos=0&sektion=0&manpath=FreeBSD+9.3-RELEASE&arch=default&format=html) (something I know a little more about) there's no mention of any signing there either, granted they at least had a clear warning in the man page. At the time the recommendation was mostly the same as OpenBSD, build everything through ports, which has a robust validation system and use pkg_add for local media (or something along those lines).

FreeBSD did also do a quick switch to to the much much nicer nicer [pkg(1)](https://www.freebsd.org/cgi/man.cgi?query=pkg&apropos=0&sektion=0&manpath=FreeBSD+10.0-RELEASE&arch=default&format=html) in the next release, and validation is documented on the 10.1 release (although I believe it existed on 10.0 as well, not positive).

Oh and can't forget about Arch Linux.

<p class="meta">Take aways</p>

Package validation was in a poor state for a lot of systems around 2013'ish.

Many people worked to fix this around that same time as well, likely tirelessly. Despite me dragging up the past here, I'm very appreciative of the hard work put in here. I won't say much I don't know but, I do know OpenBSD's signify(1) and FreeBSD's pkg(1) where not trivial tasks.

Maybe I should mess around with OpenBSD sometime here.. or really any of the BSD's. It's been a while.

I really wonder now if my tweet actually did have an effect on getting this resolved, or if it was just a coincidence. Would be pretty cool if it did.









