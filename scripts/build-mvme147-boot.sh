#!/bin/sh
# Prepare the mvme147 ROMboot boot artifacts under output/mvme147/:
#   - rombank2.bin        the ROM bank 2 image = the U-Boot SPL, which is
#                         itself a 147Bug "BOOT" module (the ROMboot header
#                         and self-relocator are built into the SPL, see
#                         the U-Boot fork's arch/m68k/cpu/mc68000/start.S)
#   - nvram-romboot.img   MK48T02 NVRAM with the ROMboot scan enabled
#   - disk.img            a blank SCSI disk for the SPL to try to boot from
#
# Usage: scripts/build-mvme147-boot.sh
#
# Requires the U-Boot SPL at output/u-boot-m68k-testrobot/spl/u-boot-spl.bin
# (scripts/build-uboot.sh) and python3.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
spl=$root/output/u-boot-m68k-testrobot/spl/u-boot-spl.bin
out=$root/output/mvme147

if [ ! -f "$spl" ]; then
	echo "error: SPL $spl missing;" >&2
	echo "       build it first: scripts/build-uboot.sh u-boot-m68k-testrobot mvme147_defconfig" >&2
	exit 1
fi

mkdir -p "$out"

# The SPL is already a ROMboot module; use it as the ROM bank 2 image.
cp "$spl" "$out/rombank2.bin"

# NVRAM with the power-up ROMboot scan enabled.
python3 "$root/targets/mvme147/make-nvram.py" --romboot "$out/nvram-romboot.img"

# A blank SCSI disk: the SPL only needs a target to try to boot from.
truncate -s 16M "$out/disk.img" 2>/dev/null || \
	dd if=/dev/zero of="$out/disk.img" bs=1M count=16 >/dev/null 2>&1

echo "mvme147 ROMboot artifacts in $out"
