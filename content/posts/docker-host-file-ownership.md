---
title: Correct file ownership when mounting local folders in Docker on Linux
date: 2022-03-22
image: images/whale.png
description: 'How to avoid running containers as root and other Linux file ownership related issues when mounting local folders into Docker containers'
tags: ['docker', 'linux', 'permissions', 'npm', 'eacces']
---

I just joined a new company. Our local development happens by launching multiple containers via [docker compose](https://docs.docker.com/compose/cli-command/). Most of the existing developers are using Mac OS and Docker Desktop. This means mounting local folders into a container does not result in the same behaviour as doing so on Linux, which is my operating system of choice.

When onboarding, I ran into a peculiar problem where the frontend container based on [node:17.4-alpine](https://hub.docker.com/_/node) would bork with `EACCES: permission denied`.

```
npm WARN logfile Error: EACCES: permission denied, scandir '/root/.npm/_logs'
npm WARN logfile  error cleaning log files [Error: EACCES: permission denied, scandir '/root/.npm/_logs'] {
npm WARN logfile   errno: -13,
npm WARN logfile   code: 'EACCES',
npm WARN logfile   syscall: 'scandir',
npm WARN logfile   path: '/root/.npm/_logs'
```

StackOverflow [provided an answer](https://stackoverflow.com/a/70953525/7222662) as to why this is happening. It boils down to running `npm` as `root` requires the folder which you run `npm` in needs to be owned by `root` as well. This wasn't a workable solution, as I didn't want to start to run `sudo` with everything (security issues notwithstanding).

Apart from the `npm` issue preventing the container from running, having my local directory structure filled with files and folders owned by `root` was not something I was going to enjoy.

The solution was Docker build arguments, passing my local user id, group id as well as the value of Bash's built-in [`$OSTYPE`](https://tldp.org/LDP/abs/html/internalvariables.html) environment variable.

```bash
# As part of a Bash script
docker compose -f foo.yml build \
    --build-arg USER_ID="$(id -u)" \
    --build-arg GROUP_ID="$(id -g)" \
    --build-arg HOSTOSTYPE="$OSTYPE"
```

`OSTYPE` is set to `linux-gnu` in Bash on my machine (running Pop_OS! 21.10, a Ubuntu derivative).

The Dockerfile had to be amended as well, using Alpine's [shadow](https://pkgs.alpinelinux.org/package/edge/community/x86/shadow) package to provide `usermod` and `groupmod` to set the existing node user's user id and group id to that of the host user's values.

```docker
FROM node:17.4-alpine

RUN apk add shadow

# Container needs to run as non-privileged user, or on Linux permissions will result in EACCES error in npm
# See https://stackoverflow.com/questions/70952903/npm-error-eacces-permission-denied-scandir
ARG GROUP_ID
ARG USER_ID
ARG HOSTOSTYPE

# Make sure container and host UID/GID match on Linux
RUN if [[ "$HOSTOSTYPE" == "linux-gnu"* ]]; then usermod -u $USER_ID node && groupmod -g $GROUP_ID node; fi

USER node

# Everything from here is then run by the `node` user, using the host machine's user and group id on Linux

WORKDIR /foo

RUN npm install
```

The above solution helped me fix the `EACCES` issue as well as have files created with the right ownership. It did not break Mac compatibility either.