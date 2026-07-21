#!/bin/sh
# Prepare the mvme147 ROMboot boot artifacts under output/mvme147/:
#   - rombank2.bin        the ROM bank 2 image = the U-Boot SPL, which is
#                         itself a 147Bug "BOOT" module (see the U-Boot
#                         fork's arch/m68k/cpu/mc68000/start.S)
#   - nvram-romboot.img   MK48T02 NVRAM with the ROMboot scan enabled
#   - disk.img            a SCSI disk with a DOS MBR and a FAT16 partition 1
#                         holding u-boot.img and vmlinux; the SPL loads
#                         u-boot.img to start full U-Boot (BOOT_DEVICE_SATA,
#                         partition 1, CONFIG_SPL_FS_LOAD_PAYLOAD_NAME=
#                         u-boot.img), and full U-Boot loads vmlinux off the
#                         same partition to boot Linux
#
# Usage: scripts/build-mvme147-boot.sh
#
# Requires the SPL and u-boot.img under output/u-boot-m68k-testrobot/
# (scripts/build-uboot.sh), the kernel at output/linux/mvme147/vmlinux
# (scripts/build-linux.sh mvme147), python3, and the disk tools mkfs.fat
# (dosfstools), mcopy (mtools) and sfdisk (util-linux).
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
ubdir=$root/output/u-boot-m68k-testrobot
spl=$ubdir/spl/u-boot-spl.bin
uboot=$ubdir/u-boot.img
vmlinux=$root/output/linux/mvme147/vmlinux
out=$root/output/mvme147

for f in "$spl" "$uboot"; do
	if [ ! -f "$f" ]; then
		echo "error: $f missing;" >&2
		echo "       build it first: scripts/build-uboot.sh u-boot-m68k-testrobot mvme147_defconfig" >&2
		exit 1
	fi
done
if [ ! -f "$vmlinux" ]; then
	echo "error: $vmlinux missing; build it first: scripts/build-linux.sh mvme147" >&2
	exit 1
fi

mkdir -p "$out"

# The SPL is already a ROMboot module; use it as the ROM bank 2 image.
cp "$spl" "$out/rombank2.bin"

# NVRAM with the power-up ROMboot scan enabled.
python3 "$root/targets/mvme147/make-nvram.py" --romboot "$out/nvram-romboot.img"

# SCSI disk: a DOS MBR with one bootable FAT16 partition (type 0x06) at
# sector 2048, holding u-boot.img and vmlinux in its root.  Built with
# mtools/mkfs.fat so no loop device or root is needed.
export MTOOLS_SKIP_CHECK=1
part=$out/part.img
psectors=30720			# 15 MiB partition
truncate -s $((psectors * 512)) "$part"
mkfs.fat -F 16 -h 2048 -n MVME147 "$part" >/dev/null
mcopy -i "$part" "$uboot" ::u-boot.img
mcopy -i "$part" "$vmlinux" ::vmlinux

truncate -s 16M "$out/disk.img"
printf 'label: dos\nstart=2048, size=%d, type=6, bootable\n' "$psectors" \
	| sfdisk -q "$out/disk.img" >/dev/null
dd if="$part" of="$out/disk.img" bs=512 seek=2048 conv=notrunc status=none
rm -f "$part"

echo "mvme147 ROMboot artifacts in $out"
