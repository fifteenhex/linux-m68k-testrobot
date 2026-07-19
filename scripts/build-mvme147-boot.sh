#!/bin/sh
# Assemble the mvme147 ROMboot boot artifacts from a built U-Boot SPL.
#
# The MVME147 has no direct kernel/loader path in QEMU, so u-boot is
# started through 147Bug's ROMboot: 147Bug scans ROM bank 2 at power-up
# for a checksummed "BOOT" module and runs it.  This produces, under
# output/mvme147/:
#   - rombank2.bin        the SPL wrapped in such a BOOT module (a stub
#                         copies the SPL to its text base and jumps)
#   - nvram-romboot.img   MK48T02 NVRAM with the ROMboot scan enabled
#   - disk.img            a blank SCSI disk for the SPL to try to boot from
#
# Usage: scripts/build-mvme147-boot.sh
#
# Requires the U-Boot SPL at output/u-boot-m68k-testrobot/spl/u-boot-spl.bin
# (scripts/build-uboot.sh) plus the m68k toolchain + python3
# (scripts/install-uboot-deps.sh).
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
tools=$root/targets/mvme147/romboot
spl=$root/output/u-boot-m68k-testrobot/spl/u-boot-spl.bin
out=$root/output/mvme147

if [ ! -f "$spl" ]; then
	echo "error: SPL $spl missing;" >&2
	echo "       build it first: scripts/build-uboot.sh u-boot-m68k-testrobot mvme147_defconfig" >&2
	exit 1
fi

mkdir -p "$out"

# Wrap the SPL in a 147Bug ROMboot module for ROM bank 2.
CROSS_COMPILE="${CROSS_COMPILE:-m68k-linux-gnu-}" \
	python3 "$tools/build-romboot.py" "$spl" "$out/rombank2.bin"

# NVRAM with the power-up ROMboot scan enabled.
python3 "$tools/make-nvram.py" --romboot "$out/nvram-romboot.img"

# A blank SCSI disk: the SPL only needs a target to try to boot from.
truncate -s 16M "$out/disk.img" 2>/dev/null || \
	dd if=/dev/zero of="$out/disk.img" bs=1M count=16 >/dev/null 2>&1

echo "mvme147 ROMboot artifacts in $out"
