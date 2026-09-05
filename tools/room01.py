#!/usr/bin/env python3
"""Generate exact C64 room-$01 map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Room $01 is the room immediately left of room $00 in the original world grid.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM01_RLE = bytes.fromhex(
    "a3 21 00 08 00 51 00 08 00 41 04 53 50 11 00 08 "
    "20 21 10 08 00 41 04 b0 11 00 08 70 08 00 41 04 "
    "b0 11 00 08 70 08 20 21 04 c0 21 70 08 50 04 d0 "
    "41 40 08 50 03 63 80 81 50 03 00 33 e0 a1 03 f0 "
    "50 81 03 f0 f0 f0 f0 f0 f0 f0 f0 b0 55 d0 d0 08 "
    "50 35 60 d0 08 b0 46 d0 08 b0 46 d0 08 90 66 46 "
    "80 08 20 03 37 83 b6 10 08 00 f6 ff ff"
)

# room_defs room 1: first 8 bytes are tile-library indices, second 8 are C64
# colour-RAM bytes. VIC colour RAM is 4-bit, so $63 is colour $03.
ROOM01_TILE_IDS = (0x02, 0x63, 0x01, 0x0A, 0x40, 0x05, 0x55, 0x64)
ROOM01_COLOURS = (0x04, 0x03, 0x03, 0x05, 0x01, 0x0A, 0x06, 0x05)

# Exact Monty.SetTileProperty classification for the source tile IDs above.
# $56-$76 are property 3, so $63 and $64 are both climbable/vertical tiles.
ROOM01_PROPERTIES = (1, 3, 1, 1, 2, 1, 4, 3)

# Exact 8-byte entries from Tiles.tile_library.
ROOM01_TILE_BITMAPS = (
    bytes.fromhex("00 ee ee ee 00 ee ee ee"),  # tile $02
    bytes.fromhex("22 3e 66 44 cc f8 cc 46"),  # tile $63
    bytes.fromhex("00 fe fe fe 00 ef ef ef"),  # tile $01
    bytes.fromhex("ee 44 11 bb bb 11 c4 ef"),  # tile $0a
    bytes.fromhex("e6 b6 9f 00 00 00 00 00"),  # tile $40
    bytes.fromhex("3d 79 1b db d9 9d b5 b5"),  # tile $05
    bytes.fromhex("18 7e ff ff ff ff ff ff"),  # tile $55
    bytes.fromhex("60 60 60 08 d8 f0 00 60"),  # tile $64
)

# Shared palette slots already loaded by room00 assets, plus two new colours.
# C64 purple $04 -> slot 13, C64 blue $06 -> slot 14.
PAL_BY_C64 = {0x04: 13, 0x03: 3, 0x05: 12, 0x01: 7, 0x0A: 10, 0x06: 14}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    # C64 screen code 0 remains blank; custom slots become chars 1..8.
    out = bytearray(32)
    for char in ROOM01_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM01_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM01_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 01: {len(ROOM01_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
