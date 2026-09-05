#!/usr/bin/env python3
"""Generate C64 room-$02 map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Room $02 is immediately left of room $01 in the original world grid.

The source RLE remains exact. Because the original death/respawn and piledriver
mechanics are not ported yet, generated runtime data adds a temporary property-3
ladder extension on the right side so testers cannot become progression-blocked.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM02_RLE = bytes.fromhex(
    "a2 f1 41 52 50 71 60 41 f0 f0 f0 f0 70 04 f0 60 "
    "76 04 f0 60 70 04 50 62 20 62 70 04 70 22 60 22 "
    "10 60 65 20 22 b0 f0 42 a0 f0 42 a0 f0 42 a0 f0 "
    "42 30 04 50 f0 42 30 04 33 10 f0 42 30 04 50 f0 "
    "42 30 04 50 e0 62 20 04 50 40 01 58 02 10 62 20 "
    "04 50 51 57 02 10 f2 02 b1 f2 32 ff ff"
)

ROOM02_TILE_IDS = (0x02, 0x01, 0x27, 0x60, 0x3D, 0x42, 0x77, 0x55)
ROOM02_COLOURS = (0x05, 0x04, 0x07, 0x04, 0x06, 0x01, 0x06, 0x06)
ROOM02_PROPERTIES = (1, 1, 2, 3, 2, 2, 0, 4)

ROOM02_TILE_BITMAPS = (
    bytes.fromhex("00 ee ee ee 00 ee ee ee"),
    bytes.fromhex("00 fe fe fe 00 ef ef ef"),
    bytes.fromhex("ff 01 6d 01 ff 00 00 00"),
    bytes.fromhex("38 20 70 20 70 10 38 08"),
    bytes.fromhex("c1 2b ab eb c1 00 00 00"),
    bytes.fromhex("fb f3 36 24 ec c8 98 f0"),
    bytes.fromhex("ff ff ff ff ff ff ff ff"),
    bytes.fromhex("18 7e ff ff ff ff ff ff"),
)

PAL_BY_C64 = {0x05: 12, 0x04: 13, 0x07: 8, 0x06: 14, 0x01: 7}

# Temporary debug ladder: extend the existing code-4/property-3 strip at col25
# upward, with a parallel col24 strip that emerges beside the solid upper-right
# platform. This keeps the exact source map inspectable while unblocking testing.
ROOM02_DEBUG_SCAFFOLD = tuple(
    [(y, 24) for y in range(7, 18)] + [(y, 25) for y in range(7, 12)]
)


def apply_debug_scaffold(cells: list[int]) -> list[int]:
    out = list(cells)
    for y, x in ROOM02_DEBUG_SCAFFOLD:
        out[y * 32 + x] = 4
    return out


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM02_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM02_COLOURS[code - 1] & 0x0F]
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
    source_cells = decode_room(ROOM02_RLE)
    assert len(source_cells) == ROOM_CELLS
    cells = apply_debug_scaffold(source_cells)
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 02: {len(ROOM02_RLE)} exact compressed bytes -> {len(cells)} cells + temporary traversal scaffold')


if __name__ == '__main__':
    main()
