#!/bin/sh
# Download (but don't build) all Buildroot source tarballs for a CPU
# variant into the shared download directory, so a later build finds
# them already present.  Point BR2_DL_DIR at a directory shared across
# variants and cached between CI runs.
#
# Usage: BR2_DL_DIR=/some/dl scripts/download-buildroot-sources.sh <variant>
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

dl=""
if [ -n "${BR2_DL_DIR:-}" ]; then
	mkdir -p "$BR2_DL_DIR"
	dl="BR2_DL_DIR=$BR2_DL_DIR"
fi

mkdir -p "$output"
make -C "$buildroot" O="$output" BR2_DEFCONFIG="$defconfig" $dl defconfig
make -C "$buildroot" O="$output" $dl source

echo "Downloaded Buildroot sources for m68k $variant into ${BR2_DL_DIR:-$buildroot/dl}"
