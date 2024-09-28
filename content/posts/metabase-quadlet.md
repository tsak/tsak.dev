---
title: "Deploying Metabase as a Quadlet: A Rootless Podman Journey"
date: 2024-09-28
image: images/quadlet-podman-metabase-almalinux.png
caption: Not many images for "quadlet podman metabase almalinux" but Stable Diffusion gave it its best
description: 'How to run Metabase as a Quadlet on Almalinux 9 and other Redhat 9 derivatives'
tags: ['almalinux', 'metabase', 'podman', 'quadlet', 'redhat', 'linux']
---

Recently I have been getting into Podman as a great (rootless) Docker alternative and its neat integration into
Redhat based Linux distributions, rekindling my decade old love affair with [Red Hat Linux](https://en.wikipedia.org/wiki/Red_Hat_Linux).
Being asked to deploy [Metabase](https://www.metabase.com/) (Open-source Edition) as an internal service at my place of
work, I decided to give the somewhat new Quadlets a try in deploying the service, instead of the older, deprecated way
of asking Podman to generate `systemd` unit files.

I've been using [Alma Linux](https://almalinux.org/) 9.4, but this will work equally in Rocky Linux or Redhat Enterprise
Linux of the same version.

## Architecture

We are going to create a dedicated Metabase user on the host, running their [official Docker image](https://hub.docker.com/r/metabase/metabase)
with a Postgresql sidecar (application database) for the application and a secondary Postgresql sidecar (source
database) for the source data for generating reports. The application database will be backed up nightly, the
source database will be restored daily from a production backup.

## Requirements

We need mainly Podman, but as my base installation was relatively minimal, I installed a few extra bits as well.

```bash
sudo dnf install podman tar unzip buildah postgresql htop
```

## Metabase

First I created a dedicated user for Metabase, calling it `metabase`. This is not strictly required, but I like to
deploy larger applications in their own little enclave. Furthermore, we will enable [lingering](https://www.freedesktop.org/software/systemd/man/latest/loginctl.html#enable-linger%20USER%E2%80%A6)
for our newly created user, so that its systemd services will restart after a reboot.

After creating the user we will switch to it via `sudo -i -u metabase`

```bash
# Create metabase user
adduser metabase

# Enable linger for user (this ensures that services survive a reboot)
sudo loginctl enable-linger metabase

# Switch to the newly created user
sudo -i -u metabase
```

For some reason my Alma Linux install didn't set `XDG_RUNTIME_DIR` which is required to start `systemd` services as a
user, so I had to create a script in `.bashrc.d`:

```bash
# Enable systemd user integration environment variable
mkdir -p ~/.bashrc.d
echo "export XDG_RUNTIME_DIR=/run/user/$(id -u)" > ~/.bashrc.d/systemd
source ~/.bashrc.d/systemd
```

Now we create the local directories for the database volumes and the local `.config` directory for our Quadlet files:

```bash
# Create database volume containers
mkdir -vp ~/volumes/{metabase-db,metabase-source-db}

# Create Quadlet directory (systemd container files)
mkdir -p ~/.config/containers/systemd
```

Then we place the following four files into `~/.config/containers/systemd`.

**Please note:** Amend the value of `MB_DB_PASS` and `POSTGRES_PASSWORD` to suit your needs. You could use a
[Podman secret](https://docs.podman.io/en/v4.4/markdown/podman-secret.1.html) or just add a reasonably complicated
password in the file itself. We will interact via `podman exec` with the database, so will not require these passwords
again. `MB_DB_PASS` and the value of `POSTGRES_PASSWORD` in the `metabase-db.container` have to match. You will need
the `POSTGRES_PASSWORD` of the `metabase-source-db.container` when setting up a datasource in Metabase itself.

### metabase.network

The simplest of them all. It will create the `metabase` network that the other three containers will use.

```quadlet
# ~/.config/containers/systemd/metabase.network
[Network]
```

### metabase-app.container

```quadlet
# ~/.config/containers/systemd/metabase-app.container
[Container]
Image=docker.io/metabase/metabase:latest
AutoUpdate=registry
PublishPort=3000:3000
Network=metabase.network
Environment=MB_DB_TYPE=postgres
Environment=MB_DB_DBNAME=metabase
Environment=MB_DB_USER=metabase
Environment=MB_DB_PASS=CHANGEME
Environment=MB_DB_HOST=metabase-db
Environment=MB_DB_PORT=5432

[Unit]
Requires=metabase-db.service
After=metabase-db.service

[Service]
Restart=always

[Install]
WantedBy=default.target
```

### metabase-db.container

The main database for Metabase to store its own state. Remember to change `CHANGEME`!

```quadlet
# ~/.config/containers/systemd/metabase-db.container
[Container]
Image=docker.io/library/postgres:16
AutoUpdate=registry
PublishPort=5432:5432
Volume=%h/volumes/metabase-db:/var/lib/postgresql/data:Z
Network=metabase.network
HostName=metabase-db
Environment=POSTGRES_USER=metabase
Environment=POSTGRES_PASSWORD=CHANGEME

[Service]
Restart=always

[Install]
WantedBy=default.target
```

### metabase-source-db.container

The database we set as a datasource for Metabase. As we are running Postgres in production, we could simply replicate
the `metabase-db.container` setup. Please change `example` to something meaningful, e.g. your company name, project, etc.
Also remember to change `CHANGEME`!

```quadlet
# ~/.config/containers/systemd/metabase-source-db.container
[Container]
Image=docker.io/library/postgres:16
AutoUpdate=registry
PublishPort=5433:5432
Volume=%h/volumes/metabase-source-db:/var/lib/postgresql/data:Z
Network=metabase.network
HostName=metabase-source-db
Environment=POSTGRES_USER=example
Environment=POSTGRES_PASSWORD=CHANGEME

[Service]
Restart=always

[Install]
WantedBy=default.target
```

## Starting Metabase and its services

Now we can reload the Metabase user's `systemd` daemon and start our containers:

```bash
# Reload systemd user daemon, this links and compiles the above quadlet files
systemctl --user daemon-reload

# Start containers
systemctl --user start metabase-db.container
systemctl --user start metabase-source-db
systemctl --user start metabase-app
```

If all went well we can now continue with the Metabase application setup.

## Initial Metabase setup

Log out of your server and SSH into it again with port forwarding:

```bash
# Running htop so that the connection remains open, you can also use the `ServerAliveInterval` SSH option
ssh -L 3000:localhost:3000 user@example.com -t htop
```

Navigate to http://localhost:3000 for the Metabase admin user creation and initial setup. As much as the initial
Metabase setup isn't part of this guide, but we ended up hosting it through a Cloudflare tunnel and using Google as
our single-sign-on provider.

## Backup and restore

I'm only listing this as a help on how to use `zcat` and `podman exec` to restore a source database backup.

First grab a database backup and place it in `/home/metabase/latest.sql.gz`.

```bash
# Restore source data backup, using podman exec avoids having to remember the database password
zcat latest.sql.gz | podman exec -i systemd-metabase-source-db psql --username=example -h localhost example
```

Again, listing this as a help on how to use `podman exec` to create a backup of Metabase's database.

```bash
BACKUP_FILE="metabase_$(date +'%Y-%m-%d-%H%M%S').sql"
podman exec -it systemd-metabase-db pg_dump -U metabase -h localhost > "$BACKUP_FILE"
```

## Automatic updates of Metabase container

As we are targeting the `latest` tag for Metabase and their frequent release cycle, we can enable automatic updates
of their Docker container via Podman like so:

```bash
systemctl --user enable podman-auto-update.{service,timer}
systemctl --user start podman-auto-update.timer
```

Even if this could result in a broken install at some point, using a nightly backup, one could always roll back to a
last known good state. We have been running the above setup for a while now without a hitch but your mileage may vary.