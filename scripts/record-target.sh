#!/bin/sh
# Record a target's boot as a scaled, animated GIF.
#
# Usage: scripts/record-target.sh <target>   (e.g. q800)
#
# Only for targets with a graphical display (VIDEO=1 in target.conf).
# Boots the target under QEMU with the display grabbed frame-by-frame over
# QMP `screendump`, then assembles a downscaled GIF with ffmpeg at
# output/<target>-boot.gif.
#
# Env knobs: RECORD_SECONDS (default 120), RECORD_FPS (15),
# RECORD_WIDTH (480 px).
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

if [ "${VIDEO:-0}" != "1" ]; then
	echo "error: target '$target' has no video (VIDEO != 1 in target.conf)" >&2
	exit 1
fi
if [ "${BOOT_METHOD:-kernel-direct}" != "kernel-direct" ]; then
	echo "error: recording only supports kernel-direct targets so far" >&2
	exit 1
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
	echo "error: ffmpeg is required to build the GIF" >&2
	exit 1
fi

secs=${RECORD_SECONDS:-120}
fps=${RECORD_FPS:-15}
width=${RECORD_WIDTH:-480}

qemu=$root/output/${QEMU_SOURCE:-qemu}/qemu-system-m68k
vmlinux=$root/output/linux/$target/vmlinux
if [ ! -x "$qemu" ]; then
	echo "error: $qemu missing; build it first: scripts/build-qemu.sh" >&2
	exit 1
fi
if [ ! -f "$vmlinux" ]; then
	echo "error: $vmlinux missing; build it first: scripts/build-linux.sh $target" >&2
	exit 1
fi

work=$root/output/$target-record
frames=$work/frames
rm -rf "$work"
mkdir -p "$frames"
sock=$work/qmp.sock
log=$work/serial.log

# Assemble the QEMU command (kernel-direct).  console=tty0 mirrors the
# kernel log onto the framebuffer so the recording shows the boot, not
# just the penguin logo.
set -- -M "$QEMU_MACHINE" -kernel "$vmlinux" \
	-append "${KERNEL_APPEND:-} console=tty0" \
	-display none -serial "file:$log" -qmp "unix:$sock,server,nowait"
if [ -n "${BUILDROOT_CPU:-}" ]; then
	image=$root/output/$BUILDROOT_CPU/images/rootfs.cpio.lz4
	if [ ! -f "$image" ]; then
		echo "error: Buildroot image $image missing; build it first" >&2
		exit 1
	fi
	set -- "$@" -initrd "$image"
fi

echo "Recording $target for ${secs}s at ${fps} fps (${width}px wide)..."
"$qemu" "$@" ${QEMU_EXTRA:-} &
qpid=$!

# Grab frames over QMP: connect, negotiate, then screendump on a cadence.
nframes=$(( secs * fps ))
python3 - "$sock" "$frames" "$nframes" "$fps" <<'PY'
import json, os, socket, sys, time

sockpath, frames, nframes, fps = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
interval = 1.0 / fps

s = None
for _ in range(100):                      # wait for QEMU to create the socket
    try:
        s = socket.socket(socket.AF_UNIX)
        s.connect(sockpath)
        break
    except OSError:
        s = None
        time.sleep(0.1)
if s is None:
    sys.exit("could not connect to QMP socket")

f = s.makefile("rw")
f.readline()                              # QMP greeting
f.write(json.dumps({"execute": "qmp_capabilities"}) + "\n"); f.flush()
f.readline()

start = time.time()
for i in range(nframes):
    fn = os.path.join(frames, "%05d.ppm" % i)
    f.write(json.dumps({"execute": "screendump",
                        "arguments": {"filename": fn}}) + "\n")
    f.flush()
    f.readline()                          # command response
    delay = start + (i + 1) * interval - time.time()
    if delay > 0:
        time.sleep(delay)
PY

kill "$qpid" 2>/dev/null || true
wait "$qpid" 2>/dev/null || true

count=$(find "$frames" -name '*.ppm' | wc -l)
if [ "$count" -eq 0 ]; then
	echo "error: no frames were captured" >&2
	exit 1
fi
echo "Captured $count frames; encoding GIF..."

gif=$root/output/$target-boot.gif
# Two-pass palette for a good-looking GIF; downscale to $width, play at $fps.
ffmpeg -y -framerate "$fps" -i "$frames/%05d.ppm" \
	-vf "scale=${width}:-1:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" \
	-loglevel error "$gif"

echo "Wrote $gif ($(du -h "$gif" | cut -f1))"
