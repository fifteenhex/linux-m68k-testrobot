#!/usr/bin/env python3
"""Build a 147Bug ROMboot image (ROM bank 2) that autoboots the u-boot SPL.

147Bug scans ROM at power-up for a "BOOT" module, verifies its checksum,
and jumps to its entry point.  This wraps the SPL in such a module: the
entry is a small stub that copies the SPL to its text base (0x400000)
and jumps to it.

Usage: build-romboot.py <u-boot-spl.bin> [rombank2.bin]

Then boot with:
  qemu-system-m68k -M mvme147 -bios 147bug2.5-combined.bin -nographic \
      -drive if=mtd,file=nvram-romboot.img,format=raw \
      -device loader,file=rombank2.bin,addr=0xffa00000,force-raw=on \
      -drive id=hd,file=disk.img,format=raw,if=none -device scsi-hd,drive=hd

The NVRAM must have ROMboot enabled (byte 0x7f2='Y', 0x7f4='R'); use
make-nvram.py --romboot.
"""
import struct
import subprocess
import sys
import os

HERE = os.path.dirname(os.path.abspath(__file__))
CROSS = os.environ.get("CROSS_COMPILE", "m68k-linux-gnu-")


def build(spl_path, out_path):
    spl = open(spl_path, "rb").read()

    # Assemble the header+stub with the SPL length baked in (the move.l
    # #len,d0 encoding depends on it, so offsets are stable).
    obj = "/tmp/romstub.o"
    binf = "/tmp/romstub.bin"
    subprocess.run([CROSS + "as", "--defsym", "SPL_LEN=%d" % len(spl),
                    "-o", obj, os.path.join(HERE, "romstub.s")], check=True)
    subprocess.run([CROSS + "objcopy", "-O", "binary", obj, binf], check=True)
    stub = bytearray(open(binf, "rb").read())

    # Checksum: 147Bug XORs every 16-bit word in [base, base+len) seeded
    # with 0xFFFF and requires the result to be 0, i.e. the XOR of all
    # words must be 0xFFFF.  The length field is at +0x08, the checksum
    # word at +0x0c.
    length = struct.unpack(">I", stub[8:12])[0]
    stub[0x0c:0x0e] = b"\x00\x00"
    x = 0
    for i in range(0, length, 2):
        x ^= struct.unpack(">H", stub[i:i + 2])[0]
    stub[0x0c:0x0e] = struct.pack(">H", x ^ 0xFFFF)

    img = bytes(stub) + spl
    open(out_path, "wb").write(img)
    print("wrote %s: %d bytes (module header+stub 0x%x + spl %d)"
          % (out_path, len(img), length, len(spl)))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "rombank2.bin")
    build(sys.argv[1], out)
