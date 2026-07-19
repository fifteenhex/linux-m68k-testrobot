# Quadra 800 (`q800`)

A 68040 Macintosh, booted with QEMU's direct kernel load (`-kernel`)
plus the 68040 Buildroot rootfs as an lz4 initramfs.

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

(Commands are run from the repository root.)
