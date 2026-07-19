#!/bin/sh
# Download a target's boot ROM (firmware) into output/roms/.
#
# Usage: scripts/fetch-rom.sh <target>
#
# Reads ROM_URL (and optional ROM_SHA256) from targets/<target>/
# target.conf and downloads the ROM to output/roms/<basename>.  Skips
# the download if the file is already present.
set -eu

if [ $# -ne 1 ]; then
	echo "usage: $0 <target>   (e.g. mvme147)" >&2
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

: "${ROM_URL:?target.conf for '$target' has no ROM_URL}"

dir=$root/output/roms
mkdir -p "$dir"
dest=$dir/$(basename "$ROM_URL")

if [ -f "$dest" ]; then
	echo "ROM already present: $dest"
	exit 0
fi

echo "Downloading $ROM_URL"
if command -v curl >/dev/null 2>&1; then
	curl -fSL -o "$dest.tmp" "$ROM_URL"
elif command -v wget >/dev/null 2>&1; then
	wget -O "$dest.tmp" "$ROM_URL"
else
	echo "error: need curl or wget to download the ROM" >&2
	exit 1
fi
mv "$dest.tmp" "$dest"

if [ -n "${ROM_SHA256:-}" ]; then
	echo "$ROM_SHA256  $dest" | sha256sum -c - || {
		echo "error: ROM checksum mismatch" >&2
		rm -f "$dest"
		exit 1
	}
fi

echo "ROM at $dest"
