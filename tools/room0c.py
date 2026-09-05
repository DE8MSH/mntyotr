#!/usr/bin/env python3
"""Generate C64 room-$0C map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Room $0C sits directly below Room $05 in the original world grid.

Mechanisms.Piledriver.InitState additionally plants raw C64 character $62 at
screen row $0F / column $1B. $62 is property 3. Our room maps store local screen
codes 0..8 rather than arbitrary global charset ids, so generated runtime data
uses Room0C code 5 (tile $6A, also property 3) at the same logical position.
The compressed room source remains byte-exact.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM0C_RLE = bytes.fromhex(
    "41 20 f1 71 41 20 f1 71 41 f0 00 91 41 f0 a0 f1 "
    "31 b0 f1 f1 81 70 e1 51 f0 90 21 f0 c0 01 f0 e0 "
    "03 70 05 f0 50 03 20 44 05 60 06 d0 03 70 05 60 "
    "06 d0 03 70 05 60 06 30 92 03 70 05 60 06 10 52 "
    "50 03 70 05 60 06 00 52 67 03 70 05 50 82 67 03 "
    "70 05 10 b2 77 f2 f2 f2 f2 ff ff"
)

ROOM0C_TILE_IDS = (0x05, 0x0F, 0x10, 0x28, 0x6A, 0x5F, 0x4F, 0x00)
ROOM0C_COLOURS = (0x0D, 0x05, 0x07, 0x03, 0x05, 0x02, 0x02, 0x00)
ROOM0C_PROPERTIES = (1, 1, 1, 2, 3, 3, 4, 1)

ROOM0C_TILE_BITMAPS = (
    bytes.fromhex("3d 79 1b db d9 9d b5 b5"),
    bytes.fromhex("c3 01 3c b5 98 01 c7 ef"),
    bytes.fromhex("33 99 cc 66 33 99 cc 66"),
    bytes.fromhex("ff c1 63 36 1c ff 00 00"),
    bytes.fromhex("08 08 18 10 30 20 30 10"),
    bytes.fromhex("28 1c 38 70 28 1c 38 70"),
    bytes.fromhex("6e 7e c7 d3 da c3 67 ef"),
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
)

PAL_BY_C64 = {0x0D: 9, 0x05: 12, 0x07: 8, 0x03: 3, 0x02: 2, 0x00: 0}

# C64 screen ($1B,$0F) -> logical room (23,12), because the room payload starts
# at screen column 4 / row 3. Code 5 is a native property-3 surrogate for raw
# global character $62 and is only the contact/head marker; runtime motion is in
# src/rising_bollard.asm.
ROOM0C_BOLLARD_HEAD = (12, 23)
ROOM0C_BOLLARD_CODE = 5


def apply_bollard_head(cells: list[int]) -> list[int]:
    out = list(cells)
    y, x = ROOM0C_BOLLARD_HEAD
    assert out[y*32+x] == 0
    out[y*32+x] = ROOM0C_BOLLARD_CODE
    return out


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM0C_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM0C_COLOURS[code - 1] & 0x0F]
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
    source_cells = decode_room(ROOM0C_RLE)
    assert len(source_cells) == ROOM_CELLS
    cells = apply_bollard_head(source_cells)
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 0c: {len(ROOM0C_RLE)} exact compressed bytes -> {len(cells)} cells + original bollard contact marker')


if __name__ == '__main__':
    main()
