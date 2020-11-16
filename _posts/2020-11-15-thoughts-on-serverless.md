---
layout: post
title: Thoughts on Serverless
---

{{ page.title }}
================

<p class="meta">15 November 2020 - Somewhere</p>

This is the area I'm most interested currently. I'm currently learning a lot about serverless still and this post will likely change over time.

Q: Why did the serverless movement die?  
A: It didn't. Many people where just thinking on the wrong timeline, so it made it seem like it did. We still have a long ways to go to go, in terms of UX and managing complexity but I have no doubt it's the right direction in the long run.


Q: Serverless will never handle every use case though, right?  
A: Probably, our thinking around how services are designed and used will need to shift. This is also part of the reason why it will take so long to fully realize the benefits of it.


Q: What are some good tools for working in this area?  
A: SAM and CodeStar.


Q: Those suck, why those?  
A: SAM because CloudFormation has an amazing history of staying backwards compatible. SAM is also nice because AWS has managed to keep it fairly simple while still being flexible enough. The documentation really does suck though and CloudFormation can be a real pain sometimes, better to not try and do too much with it. If your running into issues, you may want to rethink your approach or use something else, I guess staying on the well traveled path is key to not crying yourself to sleep at night. SAM can integrate with other tools like terraform fairly easily, I would move complexity there if you can't get rid of it. I'll have to write up a post on how you may want to go about doing that though. CodeStar because you get's you going in the right direction from the beginning and it's simple enough to stop using it at any point.
