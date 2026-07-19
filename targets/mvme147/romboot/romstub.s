| ROMboot module for 147Bug: copies the SPL from ROM bank 2 to the SPL
| text base and jumps to it.  Header per 147Bug ROMboot format.
    .org 0
    .globl _start
_start:
    .ascii "BOOT"              | +0x00 signature
    .long  entry - _start      | +0x04 entry offset (entry = base + this)
    .long  cksum_end - _start   | +0x08 length of the checksum region
    .word  0xffff              | +0x0c checksum word (patched by the builder)
    .word  0x0000              | +0x0e pad
entry:                          | +0x10
    move.l #0xffa00000 + (spl - _start), %a0   | source: SPL in ROM bank 2
    move.l #0x00400000, %a1                     | dest: SPL text base
    move.l #SPL_LEN, %d0
1:  move.b %a0@+, %a1@+
    subq.l #1, %d0
    bne.b  1b
    move.l #0x00400000, %a0
    jmp    %a0@
    .even
cksum_end:                      | checksum covers [_start, cksum_end)
spl:                            | SPL binary appended here by the builder
