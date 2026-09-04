#!/usr/bin/env python3
"""Generate exact C64 room-$04 map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Phase 42 prepares Room $04 as ROM-tail data only; it is not reachable yet.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM04_RLE = bytes.fromhex(
    "51 00 02 00 d1 00 06 00 51 51 00 02 00 d1 00 06 "
    "00 51 31 20 02 c0 11 00 06 60 60 02 d0 01 00 06 "
    "60 60 02 d0 01 00 06 60 60 02 50 04 60 41 40 d0 "
    "04 55 20 41 20 30 53 30 04 b0 41 d0 04 d0 21 80 "
    "53 f0 01 40 06 f0 90 43 06 f0 90 40 06 f0 90 40 "
    "06 f0 90 40 06 f0 90 40 06 30 17 78 17 90 40 06 "
    "57 78 37 70 30 77 78 97 10 f7 f7 f7 f7 ff ff ff"
)

ROOM04_TILE_IDS = (0x03, 0x62, 0x3C, 0x60, 0x43, 0x66, 0x02, 0x4F)
ROOM04_COLOURS = (0x03, 0x03, 0x04, 0x07, 0x05, 0x07, 0x0D, 0x09)
ROOM04_PROPERTIES = (1, 3, 2, 3, 2, 3, 1, 4)

ROOM04_TILE_BITMAPS = (
    bytes.fromhex("11 55 11 ff 11 55 11 ff"),  # $03 / tile 3
    bytes.fromhex("c6 c6 ee 6c 20 20 6c ec"),  # $62 / tile 98
    bytes.fromhex("e7 cf 9f 00 00 00 00 00"),  # $3c / tile 60
    bytes.fromhex("38 20 70 20 70 10 38 08"),  # $60 / tile 96
    bytes.fromhex("ff aa ee 44 ee bb 00 00"),  # $43 / tile 67
    bytes.fromhex("1e 36 2c 3e 1a 17 0d 0b"),  # $66 / tile 102
    bytes.fromhex("00 ee ee ee 00 ee ee ee"),  # $02 / tile 2
    bytes.fromhex("6e 7e c7 d3 da c3 67 ef"),  # $4f / tile 79
)

PAL_BY_C64 = {
    0x03: 3, 0x04: 13, 0x07: 8, 0x05: 12, 0x0D: 9, 0x09: 1,
}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM04_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM04_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM04_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 04: {len(ROOM04_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
