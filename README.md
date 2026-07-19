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

## Layout

- `sources.repos` — vcs2l manifest of external source trees.
- `scripts/` — dependency install, source fetch, and build scripts.
- `configs/` — Buildroot defconfigs.
- `.github/workflows/` — CI jobs.
