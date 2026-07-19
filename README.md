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
`targets/<name>/` (kernel config, `target.conf`).

| Machine | In QEMU | Boot method | Boot pipeline |
| --- | --- | --- | --- |
| Quadra 800 (`q800`) | Yes | kernel-direct | [![q800](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/q800.yml/badge.svg)](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/q800.yml) |
| m68k virt (`virt`) | Yes | kernel-direct | [![virt](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/virt.yml/badge.svg)](https://github.com/fifteenhex/linux-m68k-testrobot/actions/workflows/virt.yml) |

The first target is the **Quadra 800** (`q800`), a 68040 machine booted
with QEMU's direct kernel load (`-kernel`) plus the 68040 Buildroot
rootfs as an lz4 initramfs:

```sh
sudo scripts/install-qemu-build-deps.sh
sudo scripts/install-linux-deps.sh
sudo scripts/install-buildroot-deps.sh
scripts/fetch-sources.sh              # checkout qemu + linux + buildroot
scripts/build-qemu.sh                 # -> output/qemu/qemu-system-m68k
scripts/build-linux.sh q800           # -> output/linux/q800/vmlinux
scripts/build-buildroot.sh 68040      # -> output/68040/images/rootfs.cpio.lz4
scripts/boot-target.sh q800           # boot and check
```

The second target is the **m68k virt machine** (`virt`), QEMU's
pure-virtual m68k platform (goldfish TTY/RTC/PIC + virtio-mmio).  It
defaults to a 68040 CPU, so it reuses the same 68040 Buildroot rootfs;
the flow is identical (`scripts/build-linux.sh virt`,
`scripts/boot-target.sh virt`).

The boot depends on the Buildroot rootfs for the target's CPU
(`BUILDROOT_CPU` in `target.conf`); `boot-target.sh` fails if it is
missing.  In CI each target's workflow runs *after* the `buildroot`
workflow (`workflow_run`) and restores that rootfs from its cache, so
Buildroot is built once and shared rather than rebuilt per target.  The
same workflow also builds `qemu-system-m68k` once and caches it, which
the targets restore too, so QEMU is not rebuilt per target either.
Booting through the full boot process (ROM / bootloader) instead of
direct kernel load is a later milestone; `boot-target.sh` and
`target.conf` are structured so it can be added per target.

## Layout

- `sources.repos` — vcs2l manifest of external source trees.
- `scripts/` — dependency install, source fetch, build, and boot scripts.
- `configs/` — Buildroot defconfigs.
- `targets/` — per-target machine definitions.
- `.github/workflows/` — CI jobs.
