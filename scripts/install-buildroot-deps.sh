#!/bin/sh
# Install what is needed to build Buildroot on a Debian/Ubuntu system
# (e.g. a GitHub Actions ubuntu-latest runner): Buildroot's mandatory
# host packages plus vcs2l for fetching the sources.
#
# Buildroot builds its own cross toolchain, so the host only needs a
# native compiler and the usual archive/util tools; see the "System
# requirements" section of the Buildroot manual.
#
# Usage: sudo scripts/install-buildroot-deps.sh
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
	wget \
	cpio \
	unzip \
	rsync \
	bc \
	file \
	sed \
	bzip2 \
	python3 \
	python3-pip \
	libncurses-dev

# vcs2l (maintained fork of vcstool) drives scripts/fetch-sources.sh.
$SUDO pip3 install --break-system-packages vcs2l || $SUDO pip3 install vcs2l

echo "Buildroot build dependencies installed."
