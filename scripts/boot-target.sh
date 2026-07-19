#!/bin/sh
# Boot a target under QEMU and check it reaches the expected point.
#
# Usage: scripts/boot-target.sh <target>   (e.g. q800)
#
# Requires qemu-system-m68k (scripts/build-qemu.sh) and the target's
# kernel (scripts/build-linux.sh <target>).  The target is described by
# targets/<target>/target.conf.
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

qemu=$root/output/qemu/qemu-system-m68k
vmlinux=$root/output/linux/$target/vmlinux

if [ ! -x "$qemu" ]; then
	echo "error: $qemu missing; run scripts/build-qemu.sh first" >&2
	exit 1
fi
if [ ! -f "$vmlinux" ]; then
	echo "error: $vmlinux missing; run scripts/build-linux.sh $target first" >&2
	exit 1
fi

case "${BOOT_METHOD:-kernel-direct}" in
kernel-direct) ;;
*)
	echo "error: boot method '${BOOT_METHOD}' not supported yet" >&2
	exit 1
	;;
esac

log=$root/output/$target-boot.log
mkdir -p "$root/output"
: > "$log"

echo "Booting $target (machine=$QEMU_MACHINE, method=kernel-direct)..."
# Route the console to a file (no display, no interactive monitor) so we
# can watch for the expected string.
"$qemu" -M "$QEMU_MACHINE" -kernel "$vmlinux" -append "$KERNEL_APPEND" \
	-display none -serial "file:$log" ${QEMU_EXTRA:-} &
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
	echo "PASS: '$BOOT_EXPECT' seen - $target booted via kernel-direct."
else
	echo "FAIL: '$BOOT_EXPECT' not seen within ${BOOT_TIMEOUT:-120}s." >&2
	exit 1
fi
