#!/bin/sh
# Build Buildroot for one m68k CPU variant using our defconfig.
#
# Usage: scripts/build-buildroot.sh <variant>   (e.g. 68030, 68040)
#
# Sources must already be fetched (scripts/fetch-sources.sh).  Each
# variant builds out-of-tree under output/<variant>/ so they don't
# clash.
set -eu

if [ $# -ne 1 ]; then
	echo "usage: $0 <variant>   (e.g. 68030, 68040)" >&2
	exit 2
fi
variant=$1

root=$(cd "$(dirname "$0")/.." && pwd)
buildroot=$root/src/buildroot
defconfig=$root/configs/buildroot/m68k_${variant}_defconfig
output=$root/output/$variant

if [ ! -d "$buildroot" ]; then
	echo "error: $buildroot missing; run scripts/fetch-sources.sh first" >&2
	exit 1
fi
if [ ! -f "$defconfig" ]; then
	echo "error: no defconfig for variant '$variant' ($defconfig)" >&2
	exit 1
fi

mkdir -p "$output"
make -C "$buildroot" O="$output" BR2_DEFCONFIG="$defconfig" defconfig
make -C "$buildroot" O="$output"

echo "Built Buildroot for m68k $variant; images in $output/images/"
