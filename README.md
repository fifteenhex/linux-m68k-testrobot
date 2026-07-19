# linux-m68k-testrobot

Automation for building and testing the m68k emulation work: QEMU
machine models, the u-boot ports for those boards, and Linux/m68k on
top.

This is a work in progress. It currently provides the CI plumbing to
install what is needed to build QEMU from source.

## Layout

- `scripts/install-qemu-build-deps.sh` — install QEMU's build
  dependencies on a Debian/Ubuntu system. Run it locally with
  `sudo scripts/install-qemu-build-deps.sh`.
- `.github/workflows/qemu-build-deps.yml` — GitHub Actions job that runs
  the script on `ubuntu-latest` and prints the resulting tool versions.

## Planned

- Build `qemu-system-m68k` and cache it.
- Build the u-boot images for each supported board.
- Boot each machine end to end and assert it reaches its firmware /
  bootloader prompt (regression tests).
