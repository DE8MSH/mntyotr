#!/usr/bin/env python3
"""Generate exact C64 room-$06 map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM06_RLE = bytes.fromhex(
    "f1 f1 f1 01 e0 b1 70 05 a0 81 a0 05 46 50 61 c0 "
    "05 a0 51 d0 05 a0 51 d0 05 a0 d1 30 64 60 91 f0 "
    "00 47 51 00 03 f0 20 47 51 00 03 f0 00 37 20 51 "
    "00 03 f0 00 27 30 51 00 03 e0 37 40 51 00 03 42 "
    "20 22 30 37 40 51 00 03 c0 37 60 51 00 03 c0 17 "
    "00 08 60 51 00 03 a0 37 00 08 60 51 00 03 a0 37 "
    "00 08 60 57 00 03 00 d7 00 08 00 57 57 00 03 00 "
    "d7 00 08 00 57 ff ff ff"
)

ROOM06_TILE_IDS = (0x01, 0x2D, 0x5F, 0x3D, 0x61, 0x3B, 0x24, 0x65)
ROOM06_COLOURS = (0x02, 0x04, 0x03, 0x07, 0x05, 0x02, 0x07, 0x05)
ROOM06_PROPERTIES = (1, 2, 3, 2, 3, 2, 1, 3)

ROOM06_TILE_BITMAPS = (
    bytes.fromhex("00 fe fe fe 00 ef ef ef"),  # $01
    bytes.fromhex("fc fc ff ff ff 00 00 00"),  # $2d
    bytes.fromhex("28 1c 38 70 28 1c 38 70"),  # $5f
    bytes.fromhex("c1 2b ab eb c1 00 00 00"),  # $3d
    bytes.fromhex("9c 7c fc ec dc fc f8 e4"),  # $61
    bytes.fromhex("ff 55 aa 00 55 aa ff 00"),  # $3b
    bytes.fromhex("11 ee ee ee 11 ee ee ee"),  # $24
    bytes.fromhex("6c 44 d4 aa fe 00 6c 6c"),  # $65
)

PAL_BY_C64 = {0x02: 2, 0x03: 3, 0x04: 13, 0x05: 12, 0x07: 8}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM06_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM06_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM06_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 06: {len(ROOM06_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
