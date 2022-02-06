---
title: I hate your code challenge
date: 2019-06-18
image: images/bepo.jpg
description: 'Steer clear from employers who use a soulless cookie cutter process that makes people feel like a commodity'
tags: ['career', 'hiring', 'computer-science']
---

I recently applied for an engineering management position at a maturing startup. The initial interview was great. We went an hour over the allotted time, and it felt like a friendly and meaningful conversation. In the end, the interviewer asked me if I would rather manage an existing team or kick-start a new one. I went for the second option and was looking forward to the next step in the process.

Which arrived in the form of a development test on HackerRank. Having played around with Codewars before, I signed up for an account and went on to practice their tests a bit. Unlike Codewars, HackerRank is a little more formal and geared towards people with a computer science background (or that's what it felt like). Most algorithmic challenges and interview preparation tests come with additional runtime complexity tests. Simply writing bubble sort to order an array is not going to fly.

All in all, an interesting experience and a nice way to pass a bit of free time. So after spending roughly five hours on interview preparation challenges, I decided to go for the real test (with a good night's sleep in between).

And oh my, was I in for a treat. I had exactly two hours to solve four challenges:

1. Calculating distances in two dimensional arrays¹ ([my solution](https://gist.github.com/tsak/42b26d15a81a4f9984c0973c4498d1dd))
2. [For each element in 1st array count elements less than or equal to it in 2nd array](https://www.geeksforgeeks.org/element-1st-array-count-elements-less-equal-2nd-array/) ([my solution](https://gist.github.com/tsak/452ab2efffbd3b035a8439b6197ca80f))
3. [Number of unique pairs in an array](https://www.geeksforgeeks.org/number-of-unique-pairs-in-an-array/) ([my solution](https://gist.github.com/tsak/7d6780c7ef7e3e257e0099dac8dad35a))
4. [Minimum unique array sum](https://stackoverflow.com/questions/38384537/minimum-unique-array-sum) ([my solution](https://gist.github.com/tsak/6a48fdc07783384204d9165755a112ef))

¹ This came in the form of a visual keypad, where one had to calculate the time it would take to enter security codes, depending on how far a finger had to move between keys

I planned to solve each task in roughly 30 minutes, which was an insane time limit, given the complexity of each.

In the end, I managed to solve all challenges but had to live with failed tests that targeted runtime complexity (those time out for large inputs) in two of the challenges.

In hindsight, I would have probably wanted (and needed) at least two hours **per** challenge.

And it got me thinking: Why on earth would anybody subject anyone to such a test? What does this tell me about the candidate? How are those tests in any way relevant to the real code that one would write if they would ever pass those tests? Unless you are Donald Knuth or work on planet-scale Google problems.

Last year, I had the pleasure of hiring developers for two teams. Both teams ended up being around five people strong. I would suspect only one of the ten people I helped hiring would have passed the above test in the given time. Even though each one of them is perfectly capable of writing code that makes it into production, review other people's contributions, mentor more junior developers, solve complex challenges in a team, find bugs in systems that combine any number of stacks, write meaningful commit messages and so on.

The hiring process was the same for all developers. After an initial interview, I would ask for any code they wanted to share. Something they were proud of or had worked on for a long time. I also subjected people to a development test, either done at home or at the office, but on a much simpler scale. Think frequency of characters in an array (something on the lines of [this](https://www.geeksforgeeks.org/print-characters-frequencies-order-occurrence/)). Though instead of running predefined tests, we would code review the candidate's submission and judge it based on the code quality, elegance, tests, and overall impression of the submitted solution. Quite a few that did not formally pass the test were hired anyway, simply because it was apparent that they had the right approach or misunderstood the task but showed excellent skills regardless.

And regardless of the test, nothing compares to having somebody become part of your team and work with you for a while to find out how they are. Not everybody interviews well, not everybody performs well in an arbitrary time limit, and people sometimes have bad days.

As [one Hacker News commenter](https://news.ycombinator.com/item?id=12667325) put it:

> Representative take-home work samples and conversational problem solving are in.
> My advice would be to steer clear from employers who use a soulless cookie cutter process that makes people feel like a commodity.

I could not agree more.