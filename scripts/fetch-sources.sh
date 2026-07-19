#!/bin/sh
# Fetch the external source trees listed in sources.repos into src/ using
# vcs2l (the maintained fork of vcstool; the command is still `vcs`).
#
# Uses shallow clones - the trees (linux especially) are large and we
# only build a pinned tag, so we don't need their history.  This is safe
# because every entry pins a tag/branch, not a raw commit hash (shallow
# clones can't resolve a bare hash).
#
# Usage: scripts/fetch-sources.sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)

mkdir -p "$root/src"
vcs import "$root/src" --shallow --input "$root/sources.repos"

# Record the exact commits that were checked out, so a build is
# reproducible and the CI log shows what was actually tested.  Best
# effort: exporting a shallow checkout can be finicky.
echo "Checked out:"
vcs export --exact "$root/src" || vcs status --hide-empty "$root/src" || true
