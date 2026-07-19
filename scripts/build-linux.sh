#!/bin/sh
# Cross-build a Linux/m68k kernel (vmlinux ELF, for QEMU -kernel direct
# boot) using a target's kernel config.
#
# Usage: scripts/build-linux.sh <target>   (e.g. q800)
#
# The target's config (targets/<target>/linux.config) is a config
# fragment: it is expanded with `make olddefconfig`, so it only needs to
# carry the options that matter for the target.
set -eu

if [ $# -ne 1 ]; then
	echo "usage: $0 <target>   (e.g. q800)" >&2
	exit 2
fi
target=$1

root=$(cd "$(dirname "$0")/.." && pwd)
src=$root/src/linux
config=$root/targets/$target/linux.config
out=$root/output/linux/$target

if [ ! -d "$src" ]; then
	echo "error: $src missing; run scripts/fetch-sources.sh first" >&2
	exit 1
fi
if [ ! -f "$config" ]; then
	echo "error: no kernel config for target '$target' ($config)" >&2
	exit 1
fi

: "${CROSS_COMPILE:=m68k-linux-gnu-}"
export ARCH=m68k CROSS_COMPILE

mkdir -p "$out"
cp "$config" "$out/.config"
make -C "$src" O="$out" olddefconfig
make -C "$src" O="$out" -j"$(nproc)" vmlinux

echo "Built $out/vmlinux for target $target"
