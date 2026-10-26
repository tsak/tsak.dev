
---
title: A poor man's Time Machine backup
date: 2026-10-07
image: images/time-machine.png
caption: Ever seen a rad handbag with an old timey clock built-in?
description: How to bring the original Time Machine experience to Linux
tags: ['time machine', 'linux', 'backup']
---

Back in the day<sup>1</sup> when I was still using a Mac, I always enjoyed the simplicity of 
[Time Machine](https://en.wikipedia.org/wiki/Time_Machine_(macOS)) backups that Apple introduced
almost 20 years ago. Simply plug in your dedicated drive, let Time Machine do its thing and
hey presto, snapshots of your precious data. My wife's MacBook Pro from 2013 is still backing
up to a [Drobo](https://en.wikipedia.org/wiki/Drobo) 5N of a similar vintage over SMB to this day.

I tend to synchronise my important folders such as documents, photos and videos via
[Syncthing](https://syncthing.net/) and that works without issue. However, I also have a large
`~/Development` folder that I don't synchronise. To a degree this is due to the fact that I push
most source code I care about to [GitHub](https://github.com/tsak) or [Codeberg](https://codeberg.org/tsak).
I also had bad experiences with Dropbox in the past where its synchronisation mechanism would
get confused with operations in the `.git` folder across multiple hosts. And because of that
experience, I never used to back up my `Development` folder, which was a shame, really.

So the other day, while I was looking at a disused 256 GB drive lying around on my desk, a
thought popped up in my head. What if I asked Clyde<sup>2</sup> to whip up something real
quick in that regard, with the following constraints<sup>3</sup>:

- It should run when I plug in an external drive
- It should run as a non-privileged process
- It should eject the drive when it is done
- It should have an easy to understand config file
- It should use `rsync`
- It should use hard links like the original Time Machine

Lo and behold, a little prompting later, I got my first version. It worked flawlessly on the
first try and backed up my 87 GB worth of stuff in under 10 minutes. At first, the process
was silent, so I didn't know what was going on, but I then remembered that my flavour of
Linux comes with `notify-send` which made it simple to add toast notifications to my desktop,
telling me what was going on.

The beauty of the solution is that you can simply browse the snapshots on disk as a file
tree. No special format, no index database. Just files! Thanks to hard links, each snapshot
looks like a full backup, but only files that changed since the last one take up extra space.

### How it works

- `systemd` tracks every block device as a device unit
- when a drive is plugged in, `udev` creates `/dev/disk/by-uuid/<UUID>` which `systemd` turns into a `<device>` unit
- the install script adds a `~/.config/systemd/user/<device>.wants/rsync-snapshot.service` symlink that triggers the service when the drive is plugged in
- the backup script handles the mounting and unmounting of the drive

Here's a little demo of it working:

<video controls preload="metadata" playsinline width="100%">
  <source src="/videos/time-machine-demo.mp4" type="video/mp4">
</video>

Check out its code: [codeberg.org/tsak/rsync-snapshot](https://codeberg.org/tsak/rsync-snapshot)

It comes with an extensive [README](https://codeberg.org/tsak/rsync-snapshot/src/branch/main/README.md).

Or you can just follow the install instructions (after you've cloned its repository):

1. Install:

   ```sh
   ./install.sh
   ```

   On the first run this creates `~/.config/rsync-snapshot/config` with an
   empty `UUID` and stops before setting up the plug-in trigger, listing the
   attached drives so you can pick yours (same as `lsblk -f`).

2. Edit `~/.config/rsync-snapshot/config`: set `UUID` and list the folders to
   back up in `SOURCES`:

   ```sh
   UUID="2155b0cb-13a2-452b-a336-f3a309f79b63"
   SOURCES=(
       ~/Documents
       ~/Pictures
       ~/Development
   )
   EXCLUDES=(
       .cache/
       node_modules/
   )
   ```

3. Run `./install.sh` again. With `UUID` set it enables the trigger. Do the
   same whenever you change `UUID` later, so the trigger follows the new drive.

### Footnotes

<sup>1</sup> I started using Linux full-time in 2018. These days I use ~~just a bunch of scripts on top of Arch~~ Omarchy btw

<sup>2</sup> Naming it Claude instead was a missed opportunity on Anthropic's part in my opinion

<sup>3</sup> The real discussion went a little differently. I asked Clyde about how to get a similar
experience to Time Machine on Linux and it suggested `restic` or `borg` - the complexities of each
were not what I was longing for in my fond memories of Time Machine
