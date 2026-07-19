#!/bin/sh
# Install the packages needed to cross-build U-Boot for m68k (and to
# assemble the mvme147 ROMboot artifacts) on a Debian/Ubuntu system.
#
# Usage: sudo scripts/install-uboot-deps.sh
set -eu

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	SUDO="sudo"
fi

export DEBIAN_FRONTEND=noninteractive

$SUDO apt-get update

# gcc-m68k-linux-gnu provides the cross toolchain (and m68k-linux-gnu-as
# / -objcopy used to build the ROMboot stub); python3 drives the ROMboot
# and NVRAM builders.
$SUDO apt-get install --no-install-recommends -y \
	build-essential \
	git \
	bc \
	bison \
	flex \
	libssl-dev \
	gcc-m68k-linux-gnu \
	python3 \
	python3-pip

# vcs2l (maintained fork of vcstool) drives scripts/fetch-sources.sh.
$SUDO pip3 install --break-system-packages vcs2l || $SUDO pip3 install vcs2l

echo "U-Boot build dependencies installed."
