---
layout: post
title: Thoughts on Terraform and Design
---

{{ page.title }}
================

<p class="meta">15 November 2020 - Somewhere</p>
I started writing this when updating my Resume but figured it made more sense as a blog post since it's fairly opinionated.

I don’t want to impose my views here on other people but I think it’s worth going over just to get an idea of where I’m coming from in this area. You could probably also read between the lines here as a reason why I prefer to work in development going forward.

My feelings on terraform though in general are a bit mixed, it is great at managing infrastructure but that’s about where it ends and starts getting more complicated. The dev story, in my experience, ends up going a bit sour when it comes to fitting in with the larger development workflow, deployments and CI/CD are also difficult to get right and even then bare bones in terms of features and flexibility.

Not to say these aren’t achievable, but it either involves extremely knowledgeable and forward looking employees in the first place as well as getting them to agree on and enforce a standard style. The alternative is of course to borrow someone elses code (for example [CloudPosse’s](https://github.com/cloudposse) who has a whole range of amazing modules) that is already fully documented, tested and integrated with various CI/CD pipelines. The big problem with the second approach though is it means full buy in in on a very opinionated style, something that many smart people tend to shy away from naturally (sometimes with good reason, sometimes not).

If you ended attempting to carve your own path here and writing your own modules it's often very difficult for new users to write terraform code in a maintainable way as part of a larger project. I've personally made this mistake, greatly underestimating how much work goes into keeping things consistent on a team of more then one. Documentation and consistency is extremely important, and unfortunately often neglected.

Ultimately unless it is all carefully managed, terraform can, in a complex infrastructure end up widening the gap between Development and and Operations unnecessarily, which is exactly what these tools where built to avoid.

Once you've started going down the second path there's no solution to this that's both easy and effective. That said, personally, I’ve been investigating alternative ways of managing infrastructure that I feel, at least works much better with relatively common patterns.

[SAM](https://aws.amazon.com/serverless/sam/) for serverless is a good example, as well as [copilot](https://aws.amazon.com/containers/copilot/) for more typical containerized scheduled jobs, standalone APIs or two tier web apps. [CodeStar](https://aws.amazon.com/codestar/) in my limited experience, is amazing as well. It is effectively just SAM with CI/CD, deployment, monitoring, and a few other niceties handled for you out of the box. The key with it seems to be is to remember it is all entirely decomposable, if it turns out to be the wrong choice you simply remove the parts you don't like, replacing them with something else as necessary.

There's of course other good third party solutions as well, but I'll hold off on listing those since I tend to focus on AWS tools. I'll have to write up another post on the reasoning for this another time.

If nothing else I hope my experiences here encourage people to investigate the stupid (simple) path a little more before assuming their infrastructure is too complex to fit any commonly used pattern. Sometimes making higher level changes in thinking and design, examining how two architectures are similar rather then listing off how they are different can be the only thing needed.
