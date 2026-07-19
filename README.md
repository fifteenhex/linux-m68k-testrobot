# linux-m68k-testrobot

Automation for building and testing the m68k emulation work: QEMU
machine models, the u-boot ports for those boards, and Linux/m68k on
top.

This is a work in progress.

## Sources

External trees are tracked in `sources.repos`, a [vcs2l] manifest, and
checked out under `src/` by `scripts/fetch-sources.sh` (which also
prints the exact commits it resolved).

[vcs2l]: https://github.com/ros-infrastructure/vcs2l

## Buildroot

Generic, board-agnostic Buildroot builds for each m68k CPU variant,
optimised for the target CPU (gcc `-mcpu=68030` / `-mcpu=68040`):

```sh
sudo scripts/install-buildroot-deps.sh   # host packages + vcs2l
scripts/fetch-sources.sh                 # checkout upstream Buildroot
scripts/build-buildroot.sh 68030         # -> output/68030/images/
scripts/build-buildroot.sh 68040         # -> output/68040/images/
```

- `configs/buildroot/m68k_<cpu>_defconfig` — the per-CPU defconfigs.
- `.github/workflows/buildroot.yml` — builds both CPUs on `ubuntu-latest`.

## Targets

A target is one machine + how it is booted.  Each lives under
`targets/<name>/` (kernel config or boot artifacts, `target.conf`, and a
README with its build/boot recipe — linked from the table below).

| Machine | In QEMU | Boot method | Boot pipeline |
| --- | --- | --- | --- |
| [Quadra 800](targets/q800/README.md) (`q800`) | Yes | kernel-direct | [![q800](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/q800.yml/badge.svg)](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/q800.yml) |
| m68k virt (`virt`) | Yes | kernel-direct | [![virt](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/virt.yml/badge.svg)](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/virt.yml) |
| MVME147 (`mvme147`) | Yes (fork) | ROMboot → U-Boot SPL | [![mvme147](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/mvme147.yml/badge.svg)](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/mvme147.yml) |

The second target is the **m68k virt machine** (`virt`), QEMU's
pure-virtual m68k platform (goldfish TTY/RTC/PIC + virtio-mmio).  It
defaults to a 68040 CPU, so it reuses the same 68040 Buildroot rootfs;
the flow is identical (`scripts/build-linux.sh virt`,
`scripts/boot-target.sh virt`).

The third target is the **MVME147** (`mvme147`), a 68030 VME board that
mainline QEMU doesn't support.  It uses a QEMU fork ([fifteenhex/qemu],
branch `m68k-testrobot`, in `targets/mvme147/sources.repos`, built as
`output/qemu-m68k-testrobot/` and selected by `QEMU_SOURCE`) plus a
matching U-Boot fork ([fifteenhex/u-boot], branch `m68k-testrobot`, in
`targets/mvme147/u-boot.repos`).

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

[fifteenhex/qemu]: https://github.com/fifteenhex/qemu
[fifteenhex/u-boot]: https://github.com/fifteenhex/u-boot

The kernel-direct targets depend on the Buildroot rootfs for their CPU
(`BUILDROOT_CPU` in `target.conf`); `boot-target.sh` fails if it is
missing.  In CI every target's workflow runs *after* the `buildroot`
workflow (`workflow_run`) and restores what it needs from that
workflow's caches: the `buildroot` workflow builds each rootfs once and
builds `qemu-system-m68k` once — both the mainline build and the
`m68k-testrobot` fork — so nothing is rebuilt per target.  A target just
restores the QEMU build its `QEMU_SOURCE` names (`mvme147` grabs the
fork; the others grab mainline) and, for kernel-direct targets, the
rootfs.  Booting the kernel-direct targets through the full boot process
(ROM / bootloader) is a later milestone; `boot-target.sh` and
`target.conf` are structured so it can be added per target.

## Layout

- `sources.repos` — vcs2l manifest of external source trees.
- `scripts/` — dependency install, source fetch, build, and boot scripts.
- `configs/` — Buildroot defconfigs.
- `targets/` — per-target machine definitions.
- `.github/workflows/` — CI jobs.
