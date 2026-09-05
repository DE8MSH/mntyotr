#!/usr/bin/env python3
"""Generate exact C64 room-$09 map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Room $09 is directly above Room $01 in the original world grid.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM09_RLE = bytes.fromhex(
    "f1 e1 00 f0 70 06 20 21 00 f0 70 06 30 11 00 f0 "
    "70 06 30 11 00 f0 70 06 30 11 00 51 48 91 20 06 "
    "30 11 00 40 61 20 05 41 20 06 30 11 00 e0 05 10 "
    "21 20 06 20 21 00 e0 05 20 21 10 06 20 21 00 e0 "
    "05 20 21 10 06 20 21 00 32 a0 05 20 21 10 06 20 "
    "21 00 e0 05 30 21 00 06 20 31 20 43 60 05 30 21 "
    "00 06 20 01 20 e0 05 30 21 00 06 20 01 20 60 23 "
    "10 14 00 05 00 24 21 00 06 20 01 20 e0 05 30 21 "
    "00 06 20 01 20 e0 05 30 21 00 06 20 01 20 e0 05 "
    "20 37 00 06 20 31 d7 00 05 00 57 00 06 00 57 d7 "
    "00 05 00 57 00 06 00 57 ff ff"
)

ROOM09_TILE_IDS = (0x05, 0x2C, 0x3B, 0x42, 0x65, 0x60, 0x15, 0x4F)
ROOM09_COLOURS = (0x0A, 0x02, 0x08, 0x03, 0x05, 0x03, 0x0D, 0x05)
ROOM09_PROPERTIES = (1, 2, 2, 2, 3, 3, 1, 4)

ROOM09_TILE_BITMAPS = (
    bytes.fromhex("3d 79 1b db d9 9d b5 b5"),  # $05
    bytes.fromhex("cf df df cf 00 00 00 00"),  # $2c
    bytes.fromhex("ff 55 aa 00 55 aa ff 00"),  # $3b
    bytes.fromhex("fb f3 36 24 ec c8 98 f0"),  # $42
    bytes.fromhex("6c 44 d4 aa fe 00 6c 6c"),  # $65
    bytes.fromhex("38 20 70 20 70 10 38 08"),  # $60
    bytes.fromhex("44 38 83 c6 44 6c 38 83"),  # $15
    bytes.fromhex("6e 7e c7 d3 da c3 67 ef"),  # $4f
)

PAL_BY_C64 = {0x0A: 10, 0x02: 2, 0x08: 11, 0x03: 3, 0x05: 12, 0x0D: 9}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM09_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM09_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM09_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 09: {len(ROOM09_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
