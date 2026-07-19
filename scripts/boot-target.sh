#!/bin/sh
# Boot a target under QEMU and check it reaches the expected point.
#
# Usage: scripts/boot-target.sh <target>   (e.g. q800)
#
# The target is described by targets/<target>/target.conf.  Depending on
# BOOT_METHOD it needs different artifacts built/fetched first:
#   kernel-direct - qemu (build-qemu.sh) + kernel (build-linux.sh), plus
#                   the Buildroot rootfs if BUILDROOT_CPU is set.
#   rom           - qemu + the firmware ROM (fetch-rom.sh).
# QEMU_SOURCE selects which QEMU build under output/ to use (default
# "qemu", the mainline build; a fork target sets its own).
set -eu

if [ $# -ne 1 ]; then
	echo "usage: $0 <target>   (e.g. q800)" >&2
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

qemu_source=${QEMU_SOURCE:-qemu}
qemu=$root/output/$qemu_source/qemu-system-m68k
if [ ! -x "$qemu" ]; then
	echo "error: $qemu missing; build it first: scripts/build-qemu.sh $qemu_source" >&2
	exit 1
fi

log=$root/output/$target-boot.log
mkdir -p "$root/output"
: > "$log"

# Base QEMU arguments; per-method args are appended below.  Using the
# positional parameters preserves argument quoting.
set -- -M "$QEMU_MACHINE" -display none -serial "file:$log"

method=${BOOT_METHOD:-kernel-direct}
case "$method" in
kernel-direct)
	vmlinux=$root/output/linux/$target/vmlinux
	if [ ! -f "$vmlinux" ]; then
		echo "error: $vmlinux missing; run scripts/build-linux.sh $target first" >&2
		exit 1
	fi
	set -- "$@" -kernel "$vmlinux" -append "${KERNEL_APPEND:-}"

	# If the target has a Buildroot rootfs (BUILDROOT_CPU), require it
	# and attach it according to ROOTFS_METHOD.
	if [ -n "${BUILDROOT_CPU:-}" ]; then
		images=$root/output/$BUILDROOT_CPU/images
		case "${ROOTFS_METHOD:-initramfs}" in
		initramfs) image=$images/rootfs.cpio.lz4 ;;
		*)
			echo "error: unknown ROOTFS_METHOD '${ROOTFS_METHOD}'" >&2
			exit 1
			;;
		esac
		if [ ! -f "$image" ]; then
			echo "error: Buildroot image $image missing;" >&2
			echo "       build it first: scripts/build-buildroot.sh $BUILDROOT_CPU" >&2
			exit 1
		fi
		set -- "$@" -initrd "$image"
	fi
	;;
rom)
	: "${ROM_URL:?target.conf sets BOOT_METHOD=rom but has no ROM_URL}"
	rom=$root/output/roms/$(basename "$ROM_URL")
	if [ ! -f "$rom" ]; then
		echo "error: ROM $rom missing; fetch it first: scripts/fetch-rom.sh $target" >&2
		exit 1
	fi
	set -- "$@" -bios "$rom"
	;;
*)
	echo "error: boot method '$method' not supported yet" >&2
	exit 1
	;;
esac

echo "Booting $target (machine=$QEMU_MACHINE, method=$method, qemu=$qemu_source)..."
# Route the console to a file (no display, no interactive monitor) so we
# can watch for the expected string.
"$qemu" "$@" ${QEMU_EXTRA:-} &
qpid=$!

# Stop as soon as we see the expected string, or after the timeout.
deadline=$(( $(date +%s) + ${BOOT_TIMEOUT:-120} ))
status=fail
while kill -0 "$qpid" 2>/dev/null; do
	if grep -q "$BOOT_EXPECT" "$log" 2>/dev/null; then
		status=pass
		break
	fi
	if [ "$(date +%s)" -ge "$deadline" ]; then
		break
	fi
	sleep 1
done

kill "$qpid" 2>/dev/null || true
wait "$qpid" 2>/dev/null || true

echo "----- boot log -----"
cat "$log"
echo "--------------------"

if [ "$status" = pass ]; then
	echo "PASS: '$BOOT_EXPECT' seen - $target booted via $method."
else
	echo "FAIL: '$BOOT_EXPECT' not seen within ${BOOT_TIMEOUT:-120}s." >&2
	exit 1
fi
