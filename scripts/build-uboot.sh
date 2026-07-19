#!/bin/sh
# Build U-Boot from a fetched source tree, cross-compiled for m68k.
#
# Usage: scripts/build-uboot.sh <source> <defconfig>
#   e.g. scripts/build-uboot.sh u-boot-m68k-testrobot mvme147_defconfig
#
# Builds out-of-tree under output/<source>/.  Requires the source fetched
# (scripts/fetch-sources.sh <manifest>) and the m68k cross toolchain
# installed (scripts/install-uboot-deps.sh).
set -eu

if [ $# -ne 2 ]; then
	echo "usage: $0 <source> <defconfig>   (e.g. u-boot-m68k-testrobot mvme147_defconfig)" >&2
	exit 2
fi
name=$1
defconfig=$2

root=$(cd "$(dirname "$0")/.." && pwd)
src=$root/src/$name
out=$root/output/$name

if [ ! -d "$src" ]; then
	echo "error: $src missing; run scripts/fetch-sources.sh first" >&2
	exit 1
fi

mkdir -p "$out"
cross=${CROSS_COMPILE:-m68k-linux-gnu-}
make -C "$src" O="$out" CROSS_COMPILE="$cross" "$defconfig"
make -C "$src" O="$out" CROSS_COMPILE="$cross" -j"$(nproc)"

echo "Built U-Boot in $out"
