#!/usr/bin/env python3
"""Generate exact C64 room-$08 map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM08_RLE = bytes.fromhex(
    "f1 f1 40 31 f0 60 50 41 f0 40 50 41 f0 40 70 81 "
    "e0 f0 f1 f0 f0 f0 f0 f0 f0 f0 f0 f0 c0 27 f0 60 "
    "06 70 52 80 04 60 06 57 10 80 52 04 60 06 70 e0 "
    "04 60 06 70 e0 04 60 06 70 53 80 45 20 03 38 03 "
    "20 a3 b0 13 18 13 20 f3 f3 f3 f3 ff ff"
)

ROOM08_TILE_IDS = (0x01, 0x28, 0x1D, 0x6A, 0x40, 0x68, 0x37, 0x4F)
ROOM08_COLOURS = (0x01, 0x03, 0x09, 0x01, 0x04, 0x07, 0x05, 0x02)
ROOM08_PROPERTIES = (1, 2, 1, 3, 2, 3, 2, 4)

ROOM08_TILE_BITMAPS = (
    bytes.fromhex("00 fe fe fe 00 ef ef ef"),  # $01
    bytes.fromhex("ff c1 63 36 1c ff 00 00"),  # $28
    bytes.fromhex("ff c3 a5 99 99 a5 c3 ff"),  # $1d
    bytes.fromhex("08 08 18 10 30 20 30 10"),  # $6a
    bytes.fromhex("e6 b6 9f 00 00 00 00 00"),  # $40
    bytes.fromhex("00 18 08 18 24 7e 76 2c"),  # $68
    bytes.fromhex("ff ff 00 c6 7c 00 18 18"),  # $37
    bytes.fromhex("6e 7e c7 d3 da c3 67 ef"),  # $4f
)

PAL_BY_C64 = {0x01: 7, 0x02: 2, 0x03: 3, 0x04: 13, 0x05: 12, 0x07: 8, 0x09: 1}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM08_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM08_COLOURS[code - 1] & 0x0F]
    return (pal << 12) | (CHR_GAME + code)


def make_screen_bat(cells: list[int]) -> bytes:
    data = bytearray()
    for y in range(20):
        row = cells[y*32:(y+1)*32]
        expanded = [row[0], row[0], *row, row[-1], row[-1]]
        assert len(expanded) == SCREEN_W
        for code in expanded:
            data += struct.pack('<H', bat_word(code))
    return bytes(data)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--map', type=Path, required=True)
    ap.add_argument('--screen-bat', type=Path, required=True)
    ap.add_argument('--patterns', type=Path, required=True)
    args = ap.parse_args()
    cells = decode_room(ROOM08_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 08: {len(ROOM08_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
