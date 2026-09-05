#!/usr/bin/env python3
"""Generate exact C64 room-$05 map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Room $05 sits immediately left of Room $04 in the original world grid.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM05_RLE = bytes.fromhex(
    "f1 f1 f1 f1 91 f0 30 11 31 f0 30 04 60 31 b0 42 "
    "20 04 12 40 21 10 04 f0 10 04 60 10 01 10 04 12 "
    "f0 04 60 10 01 10 04 90 23 30 83 10 01 10 04 f0 "
    "90 10 01 10 04 f0 90 10 01 10 04 f0 90 10 01 10 "
    "04 70 87 05 20 47 10 01 10 04 f0 00 05 70 10 31 "
    "05 f0 05 70 21 20 05 f0 05 70 21 20 05 f0 05 70 "
    "21 20 05 f0 05 70 31 10 05 f0 05 70 46 00 05 00 "
    "f6 76 46 00 05 00 f6 76 ff ff"
)

ROOM05_TILE_IDS = (0x01, 0x41, 0x2B, 0x65, 0x67, 0x00, 0x3F, 0x63)
ROOM05_COLOURS = (0x01, 0x05, 0x03, 0x04, 0x07, 0x0D, 0x02, 0x03)
ROOM05_PROPERTIES = (1, 2, 2, 3, 3, 1, 2, 3)

ROOM05_TILE_BITMAPS = (
    bytes.fromhex("00 fe fe fe 00 ef ef ef"),  # $01
    bytes.fromhex("ff ff ff 00 ff 00 00 00"),  # $41
    bytes.fromhex("ff 66 66 ee 66 66 00 00"),  # $2b
    bytes.fromhex("6c 44 d4 aa fe 00 6c 6c"),  # $65
    bytes.fromhex("c3 c3 c3 bb bb c3 c3 c3"),  # $67
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),  # $00
    bytes.fromhex("c3 db 99 3c ff e3 00 00"),  # $3f
    bytes.fromhex("22 3e 66 44 cc f8 cc 46"),  # $63
)

PAL_BY_C64 = {
    0x01: 7, 0x05: 12, 0x03: 3, 0x04: 13,
    0x07: 8, 0x0D: 9, 0x02: 2,
}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM05_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM05_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM05_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 05: {len(ROOM05_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
