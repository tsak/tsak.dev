---
title: How to get into a large codebase
date: 2022-02-07
image: images/codebase.jpg
description: 'Tips and tricks on approaching a large, unknown codebase as a developer'
tags: ['codebase', 'reverse-engineering', 'chestertons-fence']
---

A while back, somebody asked on the [ExperiencedDevs subreddit](https://old.reddit.com/r/ExperiencedDevs/) about [how to work with a large codebase](https://old.reddit.com/r/ExperiencedDevs/comments/pnzxfo/how_to_work_with_a_large_codebase/). I wanted to expand on the [answer I gave there](https://old.reddit.com/r/ExperiencedDevs/comments/pnzxfo/how_to_work_with_a_large_codebase/hct2gb1/) as I think it's an interesting topic.

## Setting the stage

In one of my previous roles, I took over an almost disintegrated development department. There were only two junior developers left, the company had experienced what a [bus factor](https://en.wikipedia.org/wiki/Bus_factor) of one means and had lost their principal developer to an illness. Source code was managed (badly) via Subversion. Builds were completely manual. Development was done on environment replicas of the main application's Linux environment, think `ssh` and `vi` as the main development environment. No code reviews. Debugging was studying a ton of `print` statements. Support staff would grep for [panics](https://go.dev/blog/defer-panic-and-recover) in customer provided debug logs.

The codebase was a large application written in Go with a Vue.js frontend. Pretty much everything was solely written by the aforementioned principal developer, taking their liberties with editing external libraries as well as a good sprinkling of [Not Invented Here](https://en.wikipedia.org/wiki/Not_invented_here).

## Diving in

To gain a good understanding of the codebase, I needed a good IDE that would work for both frontend and backend code. My personal choice was Jetbrain's Go flavoured Intellij spawn [Goland](https://www.jetbrains.com/go/).

The frontend was interacting with the backend by sort of remote procedure calls (RPC). Mainly a general `/data` endpoint receiving `POST` requests in the form of JSON payloads, e.g.

```js
{
    "msg": "foobarbaz",
    "params": {
        // Union struct of all parameters of all calls
    }
}
```

A first step was refactoring the `/data` endpoint to accept `/data/foobarbaz` so that inspecting RPC calls in the browser's network tab wouldn't be an endless collection of calls to `data` but meaningful method names instead.

This allowed observing data flows from UI to the backend. The names of the RPC methods were used in the code verbatim, so grepping for `foobarbaz` would lead to the API entry point calling a function that would further call out to the business logic.

## Database

Another good entry point into the previous developer's thinking was inspecting the database schema. The application was using SQLite, so I took a copy of one of the development machine's databases and set it up in Goland's database explorer.

Thankfully the mapping between frontend, backend and database was relatively self-explanatory in my example.

This allowed a further grep through the codebase, looking for the mapping of a database table name, queries and parts of the application certain tables were used.

## Document your findings

Whenever I had learnt something, I would document my findings. Either by adding inline comments in the code, external in a project Wiki, leaving good commit messages and refactoring variable names.

## Collect infrastructure metadata

Finding and studying any kind of script files and Dockerfiles can give valuable insight into the way an application is supposed to be run. Even if a Dockerfile does not work anymore or relies upon files in a certain place, it can be a good starting place for further investigation.

If you have access to the original developer's machine, save any history you can, e.g. `~/.bash_history`.

I manage to resurrect a dead project, i.e. couldn't be built anymore, by studying bash history, inspecting the development machine's filesystem and grepping through compiled library code.

## Study commit messages

If commit messages are reasonably well written, study those. If not, it can be useful to diff between commits to at least understand how some parts of the codebase were changed.

In my example, we had at least Slack history going back years which helped correlate changes to discussions in the main engineering discussion channel.

## Debugging

Making a codebase and application debuggable is one of the most valuable ways to gain insight into the flow of data and how it's mutated during execution. Being able to set a breakpoint and then stepping through, into and out of function calls whilst watching variable values is a great way to study what a system is doing, what a mysteriously called variable `bread` means ("bytes read") and where global state is altered.

### Debug logging

Adding and or improving existing debug logging can be a valuable tool to understand how an application works.

Even though I had access to extensive debug logging, the debug log was hard to understand without knowing the code that produced a certain message. We quickly introduced structured logging, turning log statements such as:

```go
log.Debug("foo", "bar", "baz") // Prints foobarbaz
```

...into structured log statements such as:

```go
logger.WithField("bar", "baz").Debug("foo") // Prints <timestamp> "foo", {"bar": "baz"}
```

Given that the application in question had thousands of debug statements, I had to write a script that replaced all debug calls and added the surrounding function and package name for context. This made debug log output much easier to read and filter. This was also an invaluable tool for debugging customer problems.

## Test coverage

Check unit test coverage. A good rule would be to cover any new or edited code with unit tests. Unit and integration tests are a good way to ensure any major refactor will go smoothly.

If the code is inscrutable, I would opt for at least covering API calls with end to end test cases to ensure that perceived system behavior survives a refactor of underlying business logic.

## Start small

Getting into a large codebase can seem daunting. I would always opt for looking for small wins. Adding a field to an endpoint, database table and view is a great way to start to understand.

Fixing inefficient database queries, adding indices and the like can also be a great way to have a positive impact and gain understanding.

## Give yourself time

A large codebase wasn't built in a day. Take your time and be methodical. Developers love patterns, and so after a while, you will see and start to understand your predecessor's coding idiosyncrasies.

## Refactor

Also, if naming isn't great, a good way to start understanding complex pieces of code is refactoring by renaming variables once you understand what they do. Also refactoring larger functions into small parts or in-lining single call functions can do wonders to a general understanding of a codebase.

## Chesterton's fence

One of my favourite mental models for scrutinising a codebase is [Chesterton's fence](https://fs.blog/2020/03/chestertons-fence/). Before one fully understands the reason why certain things are in code, it helps to consider anything seemingly unnecessary most likely a representation of Chesterton's Fence.

Once a meaningful amount of understanding of such fences in the codebase has been gained, it's worth starting to take those down and take risks. Being too paranoid of undocumented behaviour can lead to fear of change. After all, you probably have been brought in to make changes, improve and expand the large codebase in question.