#!/usr/bin/env python3
"""Generate exact C64 room-$0F map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm +
Monty.SetTileProperty. Room $0F is the first ESCAPE TUNNEL room.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM0F_RLE = bytes.fromhex(
    "f1 f1 d1 70 91 21 80 04 90 81 01 a0 04 90 81 01 "
    "a0 04 90 81 a1 00 04 10 f1 01 81 20 04 30 e1 51 "
    "50 04 90 06 30 31 21 70 35 70 06 40 21 01 12 f0 "
    "30 06 60 01 12 50 35 a0 06 70 22 f0 30 06 70 32 "
    "60 35 70 06 70 32 f0 20 06 70 32 30 35 a0 06 70 "
    "32 08 f0 10 06 70 32 18 40 35 50 47 50 32 28 40 "
    "06 f0 20 32 63 00 06 00 f3 13 32 63 00 06 00 f3 "
    "13 ff ff"
)

ROOM0F_TILE_IDS = (0x25, 0x0F, 0x02, 0x64, 0x27, 0x6B, 0x31, 0x16)
ROOM0F_COLOURS = (0x02, 0x06, 0x03, 0x03, 0x04, 0x07, 0x05, 0x05)
# Exact Monty.SetTileProperty ranges:
# 00-26=>1, 27-46=>2, 47-4D=>1, 4E-55=>4, 56-76=>3, 77+=>0.
ROOM0F_PROPERTIES = (1, 1, 1, 3, 2, 3, 2, 1)

ROOM0F_TILE_BITMAPS = (
    bytes.fromhex("7f c3 fe fc fd ff 91 ff"),  # $25
    bytes.fromhex("c3 01 3c b5 98 01 c7 ef"),  # $0f
    bytes.fromhex("00 ee ee ee 00 ee ee ee"),  # $02
    bytes.fromhex("60 60 60 08 d8 f0 00 60"),  # $64
    bytes.fromhex("ff 01 6d 01 ff 00 00 00"),  # $27
    bytes.fromhex("00 76 76 76 00 fb fb fb"),  # $6b
    bytes.fromhex("ff c3 6e 78 cf 00 00 00"),  # $31
    bytes.fromhex("c1 73 1e 80 00 78 ce e3"),  # $16
)

PAL_BY_C64 = {0x02: 2, 0x03: 3, 0x04: 13, 0x05: 12, 0x06: 14, 0x07: 8}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)  # char 0 blank
    for char in ROOM0F_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM0F_COLOURS[code - 1] & 0x0F]
    return (pal << 12) | (CHR_GAME + code)


def make_screen_bat(cells: list[int]) -> bytes:
    data = bytearray()
    for y in range(20):
        row = cells[y * 32:(y + 1) * 32]
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
    cells = decode_room(ROOM0F_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 0f: {len(ROOM0F_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
