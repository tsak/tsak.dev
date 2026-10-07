---
title: A poor man's Time Machine backup
date: 2026-10-07
image: images/time-machine.png
caption: Ever seen a rad handbag with an old timey clock built-in?
description: How to bring the original Time Machine experience to Linux
tags: ['time machine', 'linux', 'backup', 'rsync', 'systemd']
---

I synchronise almost everything I care about with [Syncthing](https://syncthing.net/), except my
`~/Development` folder. That's 87 GB that had never been backed up anywhere. Now it gets a
Time Machine-style snapshot every time I plug in an old 256 GB drive, using `rsync`, hard links
and a systemd device trigger, all without root.

Back in the day<sup>1</sup> when I was still using a Mac, I always enjoyed the simplicity of
[Time Machine](https://en.wikipedia.org/wiki/Time_Machine_(macOS)), which Apple introduced
almost 20 years ago. Plug in your dedicated drive, let Time Machine do its thing and hey presto,
snapshots of your precious data. My wife's MacBook Pro from 2013 is still backing up to a
[Drobo](https://en.wikipedia.org/wiki/Drobo) 5N of a similar vintage over SMB to this day.

### Why my Development folder never got backed up

Part of the reason is that I push most source code I care about to [GitHub](https://github.com/tsak)
or [Codeberg](https://codeberg.org/tsak). But plenty of things never get pushed: experiments,
local branches, `.env` files, half-finished ideas.

The other part is Dropbox. I had bad experiences in the past where its synchronisation would get
confused by operations inside `.git` folders across multiple hosts. After that I simply stopped
syncing `Development` anywhere, which was a shame, really.

So the other day, while I was looking at a disused 256 GB drive lying around on my desk, a
thought popped up in my head. What if I asked Clyde<sup>2</sup> to whip up something real
quick, with the following constraints:

- It should run when I plug in an external drive
- It should run as a non-privileged process
- It should unmount the drive when it is done
- It should have an easy to understand config file
- It should use `rsync`
- It should use hard links like the original Time Machine

A little prompting later, I had my first version. It worked on the first try and backed up my
87 GB worth of stuff in under 10 minutes. Subsequent runs take about 14 seconds, because only
changed files get copied.

At first the process was silent, so I had no idea what was going on. Then I remembered that my
flavour of Linux comes with `notify-send`, which made it simple to add desktop notifications for
start, finish and failure.

### Hard links: why every snapshot looks full but isn't

Each snapshot is a plain directory named after its timestamp, with a `latest` symlink pointing
at the newest one:

```
/run/media/tsak/fw12backup/snapshots/f12/
├── 2026-10-07-210342/
├── 2026-10-07-210754/
├── 2026-10-07-215658/
└── latest -> 2026-10-07-215658
```

The trick is `rsync --link-dest=latest/`. For every file that hasn't changed since the last
snapshot, rsync creates a hard link to the existing copy instead of copying it again. Every
snapshot directory looks like a complete backup, but unchanged files only exist once on disk.

<!-- TODO: add du numbers, e.g. `du -sh 2026-10-07-215658` vs `du -sh .` across all snapshots -->

The snapshots are plain directories on disk. There's no repository format or index to get wrong,
so you can browse them in a file manager and restore with `cp`. Because the script uses
`rsync --relative`, full paths are kept inside each snapshot:

```sh
cp -a /run/media/$USER/fw12backup/snapshots/$(uname -n)/2026-10-07-215658/home/tsak/Development/foo ~/Development/
```

### How plugging in a drive starts a user-level systemd service

This is the part I didn't know about before. systemd tracks block devices as device units, and
the drive trigger is a plain `.wants` symlink:

```
plug in drive
  → udev creates /dev/disk/by-uuid/<UUID>
  → systemd --user sees dev-disk-by\x2duuid-<UUID>.device
  → .wants/ symlink starts rsync-snapshot.service
  → script waits for udiskie to mount (or mounts via udisksctl)
  → rsync --link-dest=latest/ into in-progress/
  → rename to timestamp, re-point latest
  → prune old snapshots
  → udisksctl unmount → notify-send "Safe to unplug"
```

The unit name comes from `systemd-escape`, which is why the dash in `by-uuid` turns into `\x2d`:

```sh
$ systemd-escape --path --suffix=device /dev/disk/by-uuid/2155b0cb-13a2-452b-a336-f3a309f79b63
dev-disk-by\x2duuid-2155b0cb\x2d13a2\x2d452b\x2da336\x2df3a309f79b63.device
```

`install.sh` creates `~/.config/systemd/user/<that unit>.wants/rsync-snapshot.service` as a symlink
to the service. The service itself is a `Type=oneshot` user unit with `Nice=10` and
`IOSchedulingClass=idle`, so a backup doesn't make the desktop sluggish.

### Retention, the Time Machine way

Hard links keep snapshots cheap, but not free, so old ones get pruned after each run:

- every snapshot from the last 24 hours is kept
- after that, one per day for 30 days
- after that, one per week

Separately, if free space on the drive drops below 10%, the oldest snapshots are deleted until
there's room again (the newest is never touched). All of these thresholds are configurable.

### Edge cases the script handles

A few details in the script are there because the obvious approach doesn't work:

- **`systemctl --user add-wants` refuses while the drive is unplugged.** So `install.sh` writes the
  `.wants` symlink by hand, which means you can set things up before the drive is even attached.
- **Read-only directories can't be deleted without root.** Go's module cache, for example, is
  read-only by design, so `rm -rf` on an old snapshot fails. The script makes directories (only
  directories) writable before deleting. Changing file modes would affect every snapshot sharing
  that hard link.
- **rsync exit codes 23 and 24 aren't failures.** On a live system files vanish mid-transfer and
  the odd root-owned file in `$HOME` can't be read. Those runs still produce a snapshot, with a
  warning in the notification.
- **Interrupted runs.** Snapshots are written to `in-progress/` and only renamed once rsync
  succeeds, so `latest` never points at a half-finished copy. The next run picks up where the
  last one stopped.
- **Two runs at once.** A `flock` on the destination stops that.

### Why not restic, borg or rsnapshot

When I asked Clyde how to get a Time Machine experience on Linux, it suggested
[restic](https://restic.net/) or [borg](https://www.borgbackup.org/). Both are excellent, with
block-level deduplication and encryption. But you need the tool to restore anything, and setting
up a repository, keys and pruning policies is not what I was longing for in my fond memories of
Time Machine.

The rsync hard-link approach isn't new either. [rsnapshot](https://rsnapshot.org/) and
[Back In Time](https://github.com/bit-team/backintime) do essentially the same thing.
rsnapshot is built around running as root on a cron schedule, though, and
[Timeshift](https://github.com/linuxmint/timeshift) is aimed at system files rather than
your home folder. What I wanted was the plug-in-and-forget part, as a normal user, with
notifications.

### Limitations

- **The drive needs a Linux filesystem.** `--link-dest` needs hard links and `-AX` needs ACL and
  xattr support. Most external drives ship formatted as exFAT, which has neither. Use ext4 or btrfs.
- **No block-level deduplication.** A file that changes by one byte is stored again in full. A
  4 GB VM image that changes daily costs 4 GB per snapshot. Renamed or moved files are stored
  again too.
- **No encryption** unless the drive itself is LUKS-encrypted.
- **It's one local copy.** A drive sitting next to your laptop doesn't help if the house burns
  down. This is where restic or borg to a remote location still win.

### Try it

Here's a little demo of it working:

<video controls preload="metadata" playsinline width="100%">
  <source src="/videos/time-machine-demo.mp4" type="video/mp4">
</video>

The code is at [codeberg.org/tsak/rsync-snapshot](https://codeberg.org/tsak/rsync-snapshot), and the
[README](https://codeberg.org/tsak/rsync-snapshot/src/branch/main/README.md) goes into more detail.

1. Clone and install:

   ```sh
   git clone https://codeberg.org/tsak/rsync-snapshot.git
   cd rsync-snapshot
   ./install.sh
   ```

   On the first run this creates `~/.config/rsync-snapshot/config` with an
   empty `UUID` and stops before setting up the plug-in trigger, listing the
   attached drives so you can pick yours.

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

To run a backup without replugging, use `systemctl --user start rsync-snapshot`. Logs are in
`journalctl --user -u rsync-snapshot`.

The 256 GB drive that was collecting dust on my desk now holds a snapshot history of my
`Development` folder. If you try it and something breaks, open an issue on Codeberg.

### Footnotes

<sup>1</sup> I started using Linux full-time in 2018. These days I use ~~just a bunch of scripts on top of Arch~~ Omarchy btw

<sup>2</sup> Naming it Claude instead was a missed opportunity on Anthropic's part in my opinion
