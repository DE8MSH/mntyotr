#!/usr/bin/env python3
"""Convert the authentic C64 rising-cloud frames to native PCE sprite data.

Primary reference: refactored/src/subsystems/special_items_spr.asm.
Frames $98/$99/$9A are monochrome 24x21 VIC sprites. Runtime animation order is
$98,$99,$9A,$99. Each frame is emitted in the same TL/TR/BL/BR 16x16 layout
used by Monty's proven PCE sprite converter (512 bytes per frame).
"""
from pathlib import Path

CLOUD_98 = bytes.fromhex(
    "1c 00 00 3f 80 00 7e f8 00 fc ff e0 fd ff e7 78 "
    "3f 80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
    "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
    "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
)
CLOUD_99 = bytes.fromhex(
    "1c 00 00 3f 80 00 7f f8 00 ff 7f e0 fe ff f3 78 "
    "3f 80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
    "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
    "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
)
CLOUD_9A = bytes.fromhex(
    "1c 00 00 3f 80 00 7f f8 00 ff ff e0 ff 3f f9 78 "
    "1f 80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
    "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 "
    "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
)
assert all(len(f) == 64 for f in (CLOUD_98, CLOUD_99, CLOUD_9A))


def pixels(frame64: bytes):
    raw = frame64[:63]
    rows = []
    for y in range(21):
        v = (raw[y*3] << 16) | (raw[y*3+1] << 8) | raw[y*3+2]
        rows.append([(v >> (23-x)) & 1 for x in range(24)])
    return rows


def plane_word(tile, plane, y):
    return sum((((tile[y][x] >> plane) & 1) << (15-x)) for x in range(16))


def pce_16x16(tile):
    out = bytearray()
    for plane in range(4):
        for y in range(16):
            w = plane_word(tile, plane, y)
            out += bytes((w & 0xff, w >> 8))
    assert len(out) == 128
    return out


def convert(frame64: bytes):
    pix = pixels(frame64)
    chunks = []
    for y0 in (0,16):
        for x0 in (0,16):
            tile = [[0]*16 for _ in range(16)]
            for y in range(16):
                for x in range(16):
                    sy, sx = y0+y, x0+x
                    if sy < 21 and sx < 24:
                        tile[y][x] = pix[sy][sx]
            chunks.append(pce_16x16(tile))
    out = b''.join(chunks)
    assert len(out) == 512
    return out


def build():
    out = b''.join(convert(f) for f in (CLOUD_98, CLOUD_99, CLOUD_9A))
    assert len(out) == 1536
    return out


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('--write', type=Path, required=True)
    args = ap.parse_args()
    data = build()
    args.write.write_bytes(data)
    print(f'cloud sprites: 3 authentic C64 frames -> {len(data)} bytes PCE SPR')


if __name__ == '__main__':
    main()
