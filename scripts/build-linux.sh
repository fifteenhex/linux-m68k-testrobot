#!/bin/sh
# Cross-build a Linux/m68k kernel (vmlinux ELF) for a target.
#
# Usage: scripts/build-linux.sh <target>   (e.g. q800)
#
# The target's targets/<target>/target.conf selects the source tree and
# how the kernel is configured:
#   LINUX_SOURCE     checkout under src/ to build (default "linux", the
#                    shared mainline tree; a fork target sets its own).
#   LINUX_DEFCONFIG  in-tree defconfig to use (e.g. mvme147_defconfig).
#                    If unset, targets/<target>/linux.config is used as a
#                    config fragment, expanded with `make olddefconfig`.
set -eu

if [ $# -ne 1 ]; then
	echo "usage: $0 <target>   (e.g. q800)" >&2
	exit 2
fi
target=$1

root=$(cd "$(dirname "$0")/.." && pwd)
conf=$root/targets/$target/target.conf
if [ ! -f "$conf" ]; then
	echo "error: no target.conf for target '$target' ($conf)" >&2
	exit 1
fi
# shellcheck source=/dev/null
. "$conf"

src=$root/src/${LINUX_SOURCE:-linux}
out=$root/output/linux/$target

if [ ! -d "$src" ]; then
	echo "error: $src missing; run scripts/fetch-sources.sh first" >&2
	exit 1
fi

: "${CROSS_COMPILE:=m68k-linux-gnu-}"
export ARCH=m68k CROSS_COMPILE

mkdir -p "$out"
if [ -n "${LINUX_DEFCONFIG:-}" ]; then
	# Configure from an in-tree defconfig.
	make -C "$src" O="$out" "$LINUX_DEFCONFIG"
else
	# Configure from the target's config fragment.
	config=$root/targets/$target/linux.config
	if [ ! -f "$config" ]; then
		echo "error: no kernel config for target '$target' ($config)" >&2
		exit 1
	fi
	cp "$config" "$out/.config"
	make -C "$src" O="$out" olddefconfig
fi
make -C "$src" O="$out" -j"$(nproc)" vmlinux

echo "Built $out/vmlinux for target $target"
