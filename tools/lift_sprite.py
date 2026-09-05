#!/usr/bin/env python3
"""Convert the authentic C64 two-sprite lift to native PCE sprite patterns.

Primary reference: refactored/src/subsystems/monty_spr.asm, lift_spr ($5D00).
Mechanisms.Lift displays ptr $74 at (x,y) and ptr $75 at (x,y+$15).
Both VIC sprites are multicolour: 2-bit pixel groups are doubled horizontally.
PCE output contains two 24x21 source sprites, each as the same 512-byte
TL/TR/BL/BR 16x16 group layout used by monty_sprite.py.
"""
from pathlib import Path

LIFT_SPR = bytes.fromhex(
    "00 3c 00 00 d7 00 00 7d 00 05 d7 50 3f ff fc ef "
    "ba ab ef bb ef ef ba ef eb bb ef ff ff ff 4f ff f1 70 00 0d "
    "70 00 0d 70 00 0d 40 00 01 70 00 0d 70 00 0d 70 00 0d 40 "
    "00 01 70 00 0d 70 00 0d 00 70 00 0d 40 00 01 70 00 0d 70 "
    "00 0d 70 00 0d 40 00 01 70 00 0d 70 00 0d 70 00 0d 40 00 "
    "01 70 00 0d 70 00 0d 70 00 0d 40 00 01 70 00 0d 70 00 0d "
    "70 00 0d 40 00 01 55 55 55 98 00 26 20 00 08 f4"
)
assert len(LIFT_SPR) == 128


def vic_multicolor_pixels(frame64: bytes) -> list[list[int]]:
    assert len(frame64) == 64
    raw = frame64[:63]
    rows = []
    for y in range(21):
        value = (raw[y*3] << 16) | (raw[y*3+1] << 8) | raw[y*3+2]
        row = []
        for pair in range(12):
            shift = 22 - pair*2
            colour = (value >> shift) & 0x03
            row.extend((colour, colour))
        assert len(row) == 24
        rows.append(row)
    return rows


def _plane_word(tile, plane, y):
    return sum((((tile[y][x] >> plane) & 1) << (15-x)) for x in range(16))


def pce_16x16(tile):
    out = bytearray()
    for plane in range(4):
        for y in range(16):
            word = _plane_word(tile, plane, y)
            out += bytes((word & 0xff, word >> 8))
    assert len(out) == 128
    return out


def convert_sprite(frame64: bytes) -> bytes:
    pix = vic_multicolor_pixels(frame64)
    chunks = []
    for y0 in (0, 16):
        for x0 in (0, 16):
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


def build() -> bytes:
    out = convert_sprite(LIFT_SPR[:64]) + convert_sprite(LIFT_SPR[64:])
    assert len(out) == 1024
    return out


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('--write', type=Path, required=True)
    args = ap.parse_args()
    data = build()
    args.write.write_bytes(data)
    print(f'lift sprites: 2 authentic C64 multicolour sprites -> {len(data)} bytes PCE SPR')


if __name__ == '__main__':
    main()
