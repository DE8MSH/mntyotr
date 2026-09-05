#!/usr/bin/env python3
"""Convert the original C64 3x8 piledriver head glyphs to two PCE 16x16 sprites."""
from __future__ import annotations
import argparse
from pathlib import Path

COL0 = bytes.fromhex('0f 0f 00 ff ff ff 7f 00')
COL1 = bytes.fromhex('ff ff 00 ff ff ff ff 00')
COL2 = bytes.fromhex('f0 f0 00 ff ff ff fe 00')


def sprite16(tile_rows: list[int], x0: int) -> bytes:
    # PCE 16x16 sprite: 4 bitplanes, 16 rows, two bytes/plane-row.
    out = bytearray()
    for plane in range(4):
        for y in range(16):
            bits = 0
            for x in range(16):
                srcx = x0 + x
                on = False
                if y < 8 and srcx < 24:
                    col = srcx // 8
                    bit = 7 - (srcx & 7)
                    on = bool(tile_rows[col*8+y] & (1 << bit))
                if on and plane == 0:
                    bits |= 1 << (15-x)
            out += bytes(((bits >> 8) & 0xff, bits & 0xff))
    assert len(out) == 128
    return bytes(out)


def build() -> bytes:
    rows = list(COL0 + COL1 + COL2)
    data = sprite16(rows, 0) + sprite16(rows, 16)
    assert len(data) == 256
    return data


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--write', type=Path, required=True)
    args = ap.parse_args()
    data = build()
    args.write.write_bytes(data)
    print(f'piledriver sprite: authentic C64 24x8 head -> {len(data)} bytes')

if __name__ == '__main__':
    main()
