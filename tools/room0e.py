#!/usr/bin/env python3
"""Generate exact C64 room-$0E map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Room $0E is the down-neighbour of Room $03 on the real route to Room $04.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM0E_RLE = bytes.fromhex(
    "f1 f1 f0 03 20 a1 08 f0 03 60 31 38 f0 03 80 11 "
    "38 f0 03 70 21 38 f0 03 60 51 18 e1 00 03 00 d1 "
    "81 03 50 03 30 03 91 51 20 03 50 03 30 33 20 31 "
    "01 70 03 50 03 30 33 30 21 80 03 20 44 20 33 40 "
    "11 80 03 a0 33 30 21 60 54 90 13 20 31 60 05 d0 "
    "77 11 60 05 f0 40 21 10 46 05 90 47 30 41 60 05 "
    "d0 37 51 60 05 d0 92 60 05 90 d2 f2 f2 ff ff"
)

ROOM0E_TILE_IDS = (0x05, 0x0F, 0x6A, 0x36, 0x60, 0x3A, 0x26, 0x4F)
ROOM0E_COLOURS = (0x0D, 0x05, 0x01, 0x03, 0x07, 0x04, 0x07, 0x02)
ROOM0E_PROPERTIES = (1, 1, 3, 2, 3, 2, 1, 4)

ROOM0E_TILE_BITMAPS = (
    bytes.fromhex("3d 79 1b db d9 9d b5 b5"),  # $05
    bytes.fromhex("c3 01 3c b5 98 01 c7 ef"),  # $0f
    bytes.fromhex("08 08 18 10 30 20 30 10"),  # $6a
    bytes.fromhex("ff 62 34 18 00 18 18 00"),  # $36
    bytes.fromhex("38 20 70 20 70 10 38 08"),  # $60
    bytes.fromhex("ff 55 aa ff 00 00 00 00"),  # $3a
    bytes.fromhex("ff 00 3e 22 3a 0a eb b8"),  # $26
    bytes.fromhex("6e 7e c7 d3 da c3 67 ef"),  # $4f
)

PAL_BY_C64 = {0x0D: 9, 0x05: 12, 0x01: 7, 0x03: 3, 0x07: 8, 0x04: 13, 0x02: 2}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM0E_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM0E_COLOURS[code - 1] & 0x0F]
    return (pal << 12) | (CHR_GAME + code)


def make_screen_bat(cells: list[int]) -> bytes:
    data = bytearray()
    for y in range(20):
        row = cells[y*32:(y+1)*32]
        expanded = [row[0], row[0], *row, row[-1], row[-1]]
        for code in expanded:
            data += struct.pack('<H', bat_word(code))
    return bytes(data)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--map', type=Path, required=True)
    ap.add_argument('--screen-bat', type=Path, required=True)
    ap.add_argument('--patterns', type=Path, required=True)
    args = ap.parse_args()
    cells = decode_room(ROOM0E_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 0e: {len(ROOM0E_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
