#!/bin/sh
# Fetch external source trees into src/ using vcs2l (the maintained fork
# of vcstool; the command is still `vcs`).
#
# Uses shallow clones - the trees (linux especially) are large and we
# only build a pinned tag/branch, so we don't need their history.  This
# is safe because every entry pins a tag/branch, not a raw commit hash
# (shallow clones can't resolve a bare hash).
#
# Usage: scripts/fetch-sources.sh [manifest]
#   manifest defaults to sources.repos (the shared trees).  Pass a
#   target's manifest, e.g. targets/mvme147/sources.repos, to fetch an
#   additional or alternate tree such as a QEMU fork.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
manifest=${1:-$root/sources.repos}

if [ ! -f "$manifest" ]; then
	echo "error: manifest '$manifest' not found" >&2
	exit 1
fi

mkdir -p "$root/src"
vcs import "$root/src" --shallow --input "$manifest"

# Record the exact commits that were checked out, so a build is
# reproducible and the CI log shows what was actually tested.  Best
# effort: exporting a shallow checkout can be finicky.
echo "Checked out:"
vcs export --exact "$root/src" || vcs status --hide-empty "$root/src" || true
