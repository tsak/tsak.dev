---
title: "From Gaming Rig to Fanless Console: Reviving Old Hardware with Batocera Linux and NVMe workarounds"
date: 2025-01-27
image: images/refind.png
caption: Three dots or the penguin are both valid choices
description: 'How to boot an old PC from NVMe in a PCI Express slot using rEFInd'
tags: ['linux', 'pcie', 'nvme', 'refind', 'batocera']
---

More than ten years ago, I bought a [MAINGEAR Potenza](https://uk.pcmag.com/desktops/1817/maingear-potenza-super-stock)
mainly for gaming. It was a decent enough machine, but fell out of use over the years and ended up serving as a Proxmox
testbed until I decided against its power-hungry third-generation i7-3770 and continued hosting via a much more recent
Intel NUC. I still had a Streacom FC8 fanless ITX case lying around, hoping to turn the motherboard and 
processor from the Maingear into a fast console emulation station, using [Batocera Linux](https://batocera.org/).
Eventually, the day arrived when I attempted to install the mainboard into the Streacom case, only to realise that the
processor placement wasn't compatible with the heat pipes that came with my case. So an order of a 
[different heat pipe set](https://streacom.com/products/sh8-heat-pipe-set/) later and I transplanted the old 
innards into the much newer (and fanless case).

Instead of using a SATA SSD, I wanted to use a disused m.2 NVMe drive via [PCIe adapter](https://sabrent.com/products/ec-pcie).
This turned out to be relatively easy, even though booting from the NVMe drive was not possible due to the
[old motherboard's](https://www.asus.com/us/supportonly/p8h77i/helpdesk_manual/) limitation of not being able to boot from 
a drive in the PCI Express slot. So I decided to reuse the 32 GB caching SATA SSD that the Maingear Potenza originally 
came with as a boot drive. First I tried using it as a boot drive and the NVMe as a data drive, mounted during startup,
but that never felt quite right.

Then I found [this guide](https://www.hamishmb.com/booting-nvme-older-pc-refind/) of using Clover to boot from NVMe by 
installing an EFI driver. After installing Batocera onto the NVMe drive, I managed to boot from it with the annoying
limitation that Clover would see an incorrect boot entry, which it would try to boot, only to be thrown back into
Clover, resulting in an endless boot loop. Pressing F3 to show hidden entries would reveal the correct item and allow
me to boot from the NVMe drive. Searching around for a solution and finding the Clover maintainers final say on the issue 
which was ["The Clover ideology not proposed to boot from hidden entry"](https://github.com/CloverHackyColor/CloverBootloader/issues/594#issuecomment-1837246494).
Annoying, but in the end Clover was always meant for Hackintoshes and the like and not some old x86 forced into a
second life as a media player/emulation station.

Thankfully I remembered that there was another piece of software that solved the same problem, namely the
[rEFInd Boot Manager](https://www.rodsbooks.com/refind/).

## Setting up rEFInd

First I live booted into a live Ubuntu environment. There I installed rEFInd via the following command (after connecting
to the network):

```bash
sudo apt update && sudo apt install refind
```

I ignored the question to install rEFInd to any of the disks, as my goal was to install it onto the small SATA SSD
(`/dev/sda`)

Then I partitioned the SATA SSD and formatted it as FAT32, calling it `REFIND` followed by manually installing rEFInd
onto it:

```bash
sudo refind-install --usedefault /dev/sda1 --alldrivers
```

Lastly, I downloaded [NvmExpressDxe.efi](https://github.com/MatthewPierson/Hackintosh_Files/raw/refs/heads/master/Ryzen%203600%20AB350-GAMING-3%201060%203GB%20CLOVER/EFI/CLOVER/drivers/UEFI/NvmExpressDxe.efi)
and placed it in the `REFIND` partition under `EFI/BOOT/drivers_x86`.

And that was it. Rebooting the machine dropped me into the rEFInd prompt with two boot options, both of which would
reliably start Batocera and with the added benefit that the first one would start automatically after 20 seconds.

