#!/usr/bin/env python3
"""Generate exact C64 room-$0D map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Room $0D is part of the real route from Room $03 to Room $04.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM0D_RLE = bytes.fromhex(
    "f1 f1 81 f0 60 41 f0 a0 f0 f0 f0 f0 f1 21 c0 81 "
    "70 71 24 31 f0 50 21 20 31 f0 b0 31 f0 e0 01 f0 "
    "f0 f0 f0 f0 22 20 12 f0 70 50 32 f0 50 53 52 f0 "
    "30 23 a2 23 22 b0 13 f2 52 70 f2 b2 30 f2 f2 ff ff"
)

ROOM0D_TILE_IDS = (0x05, 0x0F, 0x4F, 0x19, 0x00, 0x00, 0x00, 0x00)
ROOM0D_COLOURS = (0x0D, 0x05, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00)
ROOM0D_PROPERTIES = (1, 1, 4, 1, 1, 1, 1, 1)

ROOM0D_TILE_BITMAPS = (
    bytes.fromhex("3d 79 1b db d9 9d b5 b5"),  # $05
    bytes.fromhex("c3 01 3c b5 98 01 c7 ef"),  # $0f
    bytes.fromhex("6e 7e c7 d3 da c3 67 ef"),  # $4f
    bytes.fromhex("00 00 00 00 00 00 00 00"),  # $19
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),  # $00
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
)

PAL_BY_C64 = {0x0D: 9, 0x05: 12, 0x02: 2, 0x00: 0}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM0D_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM0D_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM0D_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 0d: {len(ROOM0D_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
