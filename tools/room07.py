#!/usr/bin/env python3
"""Generate exact C64 room-$07 map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM07_RLE = bytes.fromhex(
    "f1 f1 70 31 57 31 90 90 11 57 11 b0 90 11 57 11 "
    "b0 a0 71 c0 f0 f0 f0 f0 f0 f0 41 a0 34 20 55 20 "
    "81 f0 10 05 30 60 61 c0 05 30 f0 a0 05 30 f0 a0 "
    "46 f0 70 02 60 f0 40 02 10 02 60 f0 10 02 10 02 "
    "10 02 60 e0 02 10 02 10 02 10 02 20 33 b0 02 10 "
    "02 10 02 10 02 10 02 20 33 a3 e7 53 a3 e7 53 ff "
    "ff"
)

ROOM07_TILE_IDS = (0x01, 0x47, 0x0C, 0x3A, 0x3B, 0x39, 0x4F, 0x00)
ROOM07_COLOURS = (0x01, 0x03, 0x05, 0x04, 0x02, 0x08, 0x02, 0x00)
ROOM07_PROPERTIES = (1, 1, 1, 2, 2, 2, 4, 1)

ROOM07_TILE_BITMAPS = (
    bytes.fromhex("00 fe fe fe 00 ef ef ef"),  # $01
    bytes.fromhex("36 00 7b 7b 7b 36 36 36"),  # $47
    bytes.fromhex("ff df b7 ff dd bb f7 ff"),  # $0c
    bytes.fromhex("ff 55 aa ff 00 00 00 00"),  # $3a
    bytes.fromhex("ff 55 aa 00 55 aa ff 00"),  # $3b
    bytes.fromhex("55 aa ff 55 aa 00 00 00"),  # $39
    bytes.fromhex("6e 7e c7 d3 da c3 67 ef"),  # $4f
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),  # $00
)

PAL_BY_C64 = {0x00: 0, 0x01: 7, 0x02: 2, 0x03: 3, 0x04: 13, 0x05: 12, 0x08: 11}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM07_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM07_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM07_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 07: {len(ROOM07_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
