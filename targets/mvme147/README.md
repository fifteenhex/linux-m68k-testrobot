# MVME147 (`mvme147`)

A 68030 VME board that mainline QEMU doesn't support.  It uses a QEMU
fork ([fifteenhex/qemu], branch `m68k-testrobot`, in `sources.repos`,
built as `output/qemu-m68k-testrobot/` and selected by `QEMU_SOURCE`)
plus a matching U-Boot fork ([fifteenhex/u-boot], branch `m68k-testrobot`,
in `u-boot.repos`).

The board has no direct kernel/loader path in QEMU, so U-Boot is started
through **147Bug's ROMboot**.  The U-Boot fork builds its SPL as a
self-contained 147Bug "BOOT" module (the ROMboot header and self-relocator
are in the SPL itself), so 147Bug finds it in ROM bank 2, runs it, and the
SPL then tries to load full U-Boot over SCSI.  `scripts/build-mvme147-boot.sh`
just stages the SPL as the bank-2 image alongside a ROMboot-enabled NVRAM
and a blank SCSI disk.  For now we only check it gets that far
(`Trying to boot from SATA`):

```sh
sudo scripts/install-qemu-build-deps.sh
scripts/fetch-sources.sh targets/mvme147/sources.repos  # the QEMU fork
scripts/fetch-sources.sh targets/mvme147/u-boot.repos   # the U-Boot fork
scripts/build-qemu.sh qemu-m68k-testrobot               # -> output/qemu-m68k-testrobot/
scripts/build-uboot.sh u-boot-m68k-testrobot mvme147_defconfig
scripts/fetch-rom.sh mvme147                            # -> output/roms/147bug...
scripts/build-mvme147-boot.sh                           # bank-2 image + NVRAM + disk
scripts/boot-target.sh mvme147                          # ROMboot the SPL and check
```

(Commands are run from the repository root.)

[fifteenhex/qemu]: https://github.com/fifteenhex/qemu
[fifteenhex/u-boot]: https://github.com/fifteenhex/u-boot
