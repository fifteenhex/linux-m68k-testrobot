#!/bin/sh
# Install the packages needed to build QEMU (m68k-softmmu in particular)
# on a Debian/Ubuntu system, e.g. a GitHub Actions ubuntu-latest runner.
#
# The list mirrors QEMU's own tests/docker/dockerfiles/debian.docker,
# trimmed to what a from-source system-emulation build actually needs
# (documentation and test extras are left out).
#
# Usage: sudo scripts/install-qemu-build-deps.sh
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
	bison \
	flex \
	ninja-build \
	pkgconf \
	python3 \
	python3-pip \
	python3-venv \
	python3-setuptools \
	python3-wheel \
	python3-tomli \
	libglib2.0-dev \
	libpixman-1-dev \
	libfdt-dev \
	libslirp-dev \
	zlib1g-dev

# QEMU's configure builds meson inside its own venv, but installing it
# system-wide keeps the build hermetic and lets configure reuse it.
$SUDO pip3 install --break-system-packages meson || $SUDO pip3 install meson

echo "QEMU build dependencies installed."
