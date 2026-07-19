#!/bin/sh
# Install what is needed to cross-build a Linux/m68k kernel on a
# Debian/Ubuntu system (e.g. a GitHub Actions ubuntu-latest runner):
# the kernel build tools, the m68k cross toolchain, and vcs2l for
# fetching the sources.
#
# Usage: sudo scripts/install-linux-deps.sh
set -eu

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	SUDO="sudo"
fi

export DEBIAN_FRONTEND=noninteractive

$SUDO apt-get update

$SUDO apt-get install --no-install-recommends -y \
	build-essential \
	ca-certificates \
	git \
	bc \
	bison \
	flex \
	cpio \
	kmod \
	libssl-dev \
	libelf-dev \
	python3 \
	python3-pip \
	gcc-m68k-linux-gnu

# vcs2l (maintained fork of vcstool) drives scripts/fetch-sources.sh.
$SUDO pip3 install --break-system-packages vcs2l || $SUDO pip3 install vcs2l

echo "Linux build dependencies installed."
