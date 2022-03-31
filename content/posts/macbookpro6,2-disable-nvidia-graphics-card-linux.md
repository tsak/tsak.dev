---
title: Disable the discrete graphics card on an old Macbook Pro (Mid-2010) in Linux
date: 2022-03-31
image: images/macbookpro6,2.png
description: 'How to disable a faulty NVidia graphics card inside an old Macbook Pro and give it a new lease of life'
tags: ['linux', 'macbookpro62', 'manjaro']
---

One member of the ever-growing stack of old laptops is my wife's old [Macbook Pro (Mid 2010)](https://support.apple.com/kb/SP582). Years ago I installed the maximum allowable RAM of 8 GB as well as a 250 GB SSD instead of the HDD it originally came with. It has the [well-known issue](https://discussions.apple.com/thread/250264639) of crashing whenever the discrete NVidia graphics are being used.

A long time ago I started running Linux on it, as it feels much faster than the latest version of MacOS that would run on it, and there's an easy fix to disable discrete graphics and use the Intel chipset's graphics card instead **IF** your flavour of Linux uses the [grub](https://www.gnu.org/software/grub/) bootloader.

So a couple of days ago I installed [Manjaro (Gnome)](https://manjaro.org/downloads/official/gnome/) on it and had to remember how to disable the discrete graphics adapter yet again.

**1. Edit /etc/grub.d/00_header as root**

```bash
sudo vi /etc/grub.d/00_header
```

**2. Find the line containing the following**

```
  set gfxmode=${GRUB_GFXMODE}
```

*Line 196 in my case*

**3. Insert the following lines**

These have to be inserted **after** `set gfxmode=${GRUB_GFXMODE}`

```
  outb 0x728 1 # Switch select
  outb 0x710 2 # Switch display
  outb 0x740 2 # Switch DDC
  outb 0x750 0 # Power down discrete graphics
```

*Comments for what the individual calls to `outb` do are taken from [here](https://help.ubuntu.com/community/MacBookPro8-2/Raring).*

**4. Reboot**

```bash
sudo poweroff --reboot
```

![About dialog in Gnome on Manjaro](/images/about_macbookpro6,2.png)

*Side note:* Before applying the above fix, Gnome would think there were two internal screens, which you can work around by going into the display settings and enabling mirror mode.

I think this also disables the use of external displays, but I have never tested that assumption, as I would use the Macbook Pro as a web browsing device.