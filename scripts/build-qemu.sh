#!/bin/sh
# Build a usable qemu-system-m68k from the fetched QEMU source.
#
# Sources must already be fetched (scripts/fetch-sources.sh) and the
# build dependencies installed (scripts/install-qemu-build-deps.sh).
# Builds out-of-tree under output/qemu/.
#
# Usage: scripts/build-qemu.sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
src=$root/src/qemu
out=$root/output/qemu

if [ ! -d "$src" ]; then
	echo "error: $src missing; run scripts/fetch-sources.sh first" >&2
	exit 1
fi

mkdir -p "$out"
cd "$out"
"$src/configure" \
	--target-list=m68k-softmmu \
	--disable-docs \
	--disable-werror
ninja qemu-system-m68k

echo "Built $out/qemu-system-m68k"
