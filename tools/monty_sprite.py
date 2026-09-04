#!/usr/bin/env python3
"""Convert the first authentic C64 Monty walk frames to PCE 16x32 SPR data.

C64 frames are 24x21 1bpp (63 bytes + VIC padding byte). PCE sprite cells are
16x16 4bpp. Each Monty frame is represented by two adjacent 16x32 hardware
sprites so the original 24-pixel width is preserved without scaling.
"""
from pathlib import Path

# Authentic walk-left frames $50-$53 from the annotated reconstruction.
WALK_L = bytes.fromhex(
    "02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 21 b8 00 76 b8 00 "
    "76 2c 00 6f ec 00 1f 6c 00 1f 98 00 0f bc 00 6f 7c 00 3e 38 00 "
    "1c f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
    "02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 01 b8 00 16 b8 00 "
    "16 3c 00 2d fc 00 2d bc 00 1e 7c 00 0f f8 00 03 f0 00 01 e8 00 "
    "0f d8 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
    "02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 01 b8 00 06 b8 00 "
    "04 7c 00 0b fc 00 1b 7c 00 1c f8 00 0e fc 00 6f 7c 00 3e 38 00 "
    "1c f0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
    "02 00 00 1d c0 00 7d c0 00 7f a0 00 1e 70 00 01 b8 00 16 b8 00 "
    "36 3c 00 2d fc 00 2d bc 00 1e 7c 00 0f f8 00 03 f0 00 01 e0 00 "
    "0f c0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
)

FRAME_BYTES = 64


def c64_frame_pixels(frame: bytes):
    assert len(frame) == FRAME_BYTES
    rows = []
    for y in range(21):
        v = (frame[y*3] << 16) | (frame[y*3+1] << 8) | frame[y*3+2]
        rows.append([(v >> (23-x)) & 1 for x in range(24)])
    return rows


def pce_16x16(tile):
    """PCE SPR 16x16: 4 planes, 16 16-bit rows per plane; use plane 0 only."""
    out = bytearray()
    for plane in range(4):
        for y in range(16):
            word = 0
            for x in range(16):
                bit = tile[y][x] if plane == 0 else 0
                word |= bit << (15-x)
            out += bytes((word & 0xff, word >> 8))
    assert len(out) == 128
    return out


def convert_frame(frame: bytes):
    pix = c64_frame_pixels(frame)
    # two 16x32 sprites: left covers x=0..15, right x=16..23 + transparent pad.
    chunks = []
    for x0 in (0, 16):
        for y0 in (0, 16):
            tile = [[0]*16 for _ in range(16)]
            for y in range(16):
                sy = y0+y
                if sy >= 21:
                    continue
                for x in range(16):
                    sx = x0+x
                    if sx < 24:
                        tile[y][x] = pix[sy][sx]
            chunks.append(pce_16x16(tile))
    return b"".join(chunks)


def build_walk_left():
    assert len(WALK_L) == 4*FRAME_BYTES
    return b"".join(convert_frame(WALK_L[i:i+FRAME_BYTES]) for i in range(0, len(WALK_L), FRAME_BYTES))


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", type=Path)
    args = ap.parse_args()
    data = build_walk_left()
    assert len(data) == 4*512
    if args.write:
        args.write.write_bytes(data)
    print(f"Monty walk-left: 4 authentic C64 frames -> {len(data)} bytes PCE SPR")


if __name__ == "__main__":
    main()
