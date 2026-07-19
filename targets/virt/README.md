# m68k virt (`virt`)

QEMU's pure-virtual m68k platform (goldfish TTY/RTC/PIC + virtio-mmio),
booted with QEMU's direct kernel load (`-kernel`).  It defaults to a
68040 CPU, so it reuses the same 68040 Buildroot rootfs as the
[Quadra 800](../q800/README.md) — the flow is identical:

```sh
sudo scripts/install-qemu-build-deps.sh
sudo scripts/install-linux-deps.sh
sudo scripts/install-buildroot-deps.sh
scripts/fetch-sources.sh              # checkout qemu + linux + buildroot
scripts/build-qemu.sh                 # -> output/qemu/qemu-system-m68k
scripts/build-linux.sh virt           # -> output/linux/virt/vmlinux
scripts/build-buildroot.sh 68040      # -> output/68040/images/rootfs.cpio.lz4
scripts/boot-target.sh virt           # boot and check
```

(Commands are run from the repository root.)
