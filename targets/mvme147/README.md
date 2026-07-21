# MVME147 (`mvme147`)

A 68030 VME board that mainline QEMU doesn't support.  It uses a QEMU
fork ([fifteenhex/qemu], branch `m68k-testrobot`, in `sources.repos`,
built as `output/qemu-m68k-testrobot/` and selected by `QEMU_SOURCE`)
plus a matching U-Boot fork ([fifteenhex/u-boot], branch `m68k-testrobot`,
in `u-boot.repos`).

The board has no direct kernel/loader path in QEMU, so the whole chain
boots through **147Bug's ROMboot**.  The U-Boot fork builds its SPL as a
self-contained 147Bug "BOOT" module (the ROMboot header and self-relocator
are in the SPL itself), so 147Bug finds it in ROM bank 2 and runs it.  The
SPL loads `u-boot.img` from a FAT16 partition on the SCSI disk and starts
full U-Boot, which loads `vmlinux` off the same partition and boots Linux.

Mainline Linux only partially supports the MVME147, so the kernel is built
from the [fifteenhex/linux] fork (branch `m68k-testrobot`, in `linux.repos`)
with the in-tree `mvme147_defconfig`.

`scripts/build-mvme147-boot.sh` stages the SPL as the ROM bank-2 image,
builds the ROMboot-enabled NVRAM, and builds the SCSI disk — a DOS MBR
with a bootable FAT16 partition holding `u-boot.img` and `vmlinux` (via
`mkfs.fat` + `mcopy` + `sfdisk`, so no loop device or root is needed).  We
check the kernel starts (`Linux version`):

```sh
sudo scripts/install-qemu-build-deps.sh
sudo scripts/install-uboot-deps.sh
sudo scripts/install-linux-deps.sh
sudo apt-get install -y dosfstools mtools           # disk tools for the boot image
scripts/fetch-sources.sh targets/mvme147/sources.repos  # the QEMU fork
scripts/fetch-sources.sh targets/mvme147/u-boot.repos   # the U-Boot fork
scripts/fetch-sources.sh targets/mvme147/linux.repos    # the Linux fork
scripts/build-qemu.sh qemu-m68k-testrobot               # -> output/qemu-m68k-testrobot/
scripts/build-uboot.sh u-boot-m68k-testrobot mvme147_defconfig
scripts/build-linux.sh mvme147                          # -> output/linux/mvme147/vmlinux
scripts/fetch-rom.sh mvme147                            # -> output/roms/147bug...
scripts/build-mvme147-boot.sh                           # bank-2 image + NVRAM + disk (u-boot.img + vmlinux)
scripts/boot-target.sh mvme147                          # boot the whole chain and check
```

(Commands are run from the repository root.)

[fifteenhex/qemu]: https://github.com/fifteenhex/qemu
[fifteenhex/u-boot]: https://github.com/fifteenhex/u-boot
[fifteenhex/linux]: https://github.com/fifteenhex/linux
