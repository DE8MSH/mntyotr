#!/usr/bin/env python3
"""Generate exact C64 room-$0B map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Room $0B sits directly below Room $02 and immediately right of Room $0E.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM0B_RLE = bytes.fromhex(
    "f1 f1 f1 f1 17 70 f1 50 17 80 91 00 03 80 17 90 "
    "71 10 03 80 17 90 71 10 03 30 45 17 a0 61 10 03 "
    "45 30 17 00 03 80 51 20 03 80 17 00 03 54 20 51 "
    "20 03 80 17 00 03 80 41 30 03 80 17 00 03 80 41 "
    "30 44 40 17 00 03 90 41 40 34 30 17 00 03 90 31 "
    "50 06 64 17 00 03 90 31 50 06 60 17 22 28 12 d0 "
    "06 60 17 22 28 22 c0 06 60 17 22 28 32 b0 06 60 "
    "21 12 28 42 80 91 f1 f1 f1 f1 ff ff"
)

ROOM0B_TILE_IDS = (0x05, 0x47, 0x65, 0x3B, 0x36, 0x62, 0x03, 0x51)
ROOM0B_COLOURS = (0x0A, 0x03, 0x07, 0x04, 0x01, 0x05, 0x0D, 0x08)
ROOM0B_PROPERTIES = (1, 1, 3, 2, 2, 3, 1, 4)

ROOM0B_TILE_BITMAPS = (
    bytes.fromhex("3d 79 1b db d9 9d b5 b5"),  # $05
    bytes.fromhex("36 00 7b 7b 7b 36 36 36"),  # $47
    bytes.fromhex("6c 44 d4 aa fe 00 6c 6c"),  # $65
    bytes.fromhex("ff 55 aa 00 55 aa ff 00"),  # $3b
    bytes.fromhex("ff 62 34 18 00 18 18 00"),  # $36
    bytes.fromhex("c6 c6 ee 6c 20 20 6c ec"),  # $62
    bytes.fromhex("11 55 11 ff 11 55 11 ff"),  # $03
    bytes.fromhex("49 19 f7 f7 e7 87 27 6d"),  # $51
)

PAL_BY_C64 = {
    0x0A: 10, 0x03: 3, 0x07: 8, 0x04: 13,
    0x01: 7, 0x05: 12, 0x0D: 9, 0x08: 11,
}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM0B_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM0B_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM0B_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 0b: {len(ROOM0B_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
