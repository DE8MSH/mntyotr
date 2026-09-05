#!/usr/bin/env python3
"""Generate exact C64 room-$0A map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Room $0A sits directly below Room $01 in the original world grid.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM0A_RLE = bytes.fromhex(
    "b1 10 02 00 f1 91 30 02 00 f1 d0 02 10 02 10 02 "
    "10 02 71 d0 02 10 02 10 02 10 02 40 21 d0 02 10 "
    "02 10 02 10 02 20 41 64 60 02 10 02 10 02 10 02 "
    "20 41 f0 00 02 40 02 20 41 f0 60 02 30 31 f0 60 "
    "02 40 21 f0 60 02 40 21 f0 40 63 31 b0 25 c0 31 "
    "b3 35 10 83 41 b0 35 b0 31 a0 45 34 50 51 a0 45 "
    "20 34 20 51 a0 45 70 71 21 70 45 50 91 81 75 e1 "
    "f1 f1 ff ff"
)

ROOM0A_TILE_IDS = (0x0C, 0x65, 0x43, 0x3A, 0x00, 0x00, 0x00, 0x00)
ROOM0A_COLOURS = (0x09, 0x05, 0x03, 0x04, 0x02, 0x00, 0x00, 0x00)
ROOM0A_PROPERTIES = (1, 3, 2, 2, 1, 1, 1, 1)

ROOM0A_TILE_BITMAPS = (
    bytes.fromhex("ff df b7 ff dd bb f7 ff"),  # $0c
    bytes.fromhex("6c 44 d4 aa fe 00 6c 6c"),  # $65
    bytes.fromhex("ff aa ee 44 ee bb 00 00"),  # $43
    bytes.fromhex("ff 55 aa ff 00 00 00 00"),  # $3a
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),  # $00
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
)

PAL_BY_C64 = {0x09: 1, 0x05: 12, 0x03: 3, 0x04: 13, 0x02: 2, 0x00: 0}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM0A_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM0A_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM0A_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 0a: {len(ROOM0A_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
