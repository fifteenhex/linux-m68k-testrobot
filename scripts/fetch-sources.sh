#!/bin/sh
# Fetch the external source trees listed in sources.repos into src/ using
# vcs2l (the maintained fork of vcstool; the command is still `vcs`).
#
# Usage: scripts/fetch-sources.sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)

mkdir -p "$root/src"
vcs import "$root/src" --input "$root/sources.repos"

# Record the exact commits that were checked out, so a build is
# reproducible and the CI log shows what was actually tested.
echo "Checked out:"
vcs export --exact "$root/src"
