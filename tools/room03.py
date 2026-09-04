#!/usr/bin/env python3
"""Generate exact C64 room-$03 map, PCE BAT and room-custom patterns.

Primary reference: refactored/src/subsystems/room_data.asm + tiles.asm.
Phase 40 prepares Room $03 as ROM-tail data only; it is not yet reachable.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, SCREEN_W, CHR_GAME, decode_room

ROOM03_RLE = bytes.fromhex(
    "f1 f1 51 10 e1 20 51 31 f0 b0 f0 f0 f0 f0 f0 50 "
    "52 31 f0 c0 21 33 e0 22 90 73 40 04 f0 10 a3 10 "
    "04 52 b0 30 33 40 04 f0 10 30 33 40 04 f0 10 c0 "
    "04 b0 05 40 c0 04 70 36 05 40 c0 04 b0 05 40 c0 "
    "04 b0 05 40 c0 04 b0 05 40 f0 17 38 17 10 05 40 "
    "a3 f1 41 f3 43 a1 ff ff"
)

ROOM03_TILE_IDS = (0x01, 0x2F, 0x00, 0x65, 0x5F, 0x44, 0x11, 0x55)
ROOM03_COLOURS = (0x07, 0x03, 0x0B, 0x05, 0x03, 0x04, 0x06, 0x0E)
ROOM03_PROPERTIES = (1, 2, 1, 3, 3, 2, 1, 4)

ROOM03_TILE_BITMAPS = (
    bytes.fromhex("00 fe fe fe 00 ef ef ef"),  # $01
    bytes.fromhex("ff 03 03 03 ff 00 00 00"),  # $2f
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),  # $00
    bytes.fromhex("6c 44 d4 aa fe 00 6c 6c"),  # $65
    bytes.fromhex("28 1c 38 70 28 1c 38 70"),  # $5f
    bytes.fromhex("1e 72 c6 9e ba e2 8e ff"),  # $44
    bytes.fromhex("e7 c3 bd 24 24 bd c3 e7"),  # $11
    bytes.fromhex("18 7e ff ff ff ff ff ff"),  # $55
)

# Slot 15 is reserved for C64 light blue ($0e); it is initialized only when
# Room $03 becomes active in the next phase.
PAL_BY_C64 = {
    0x07: 8, 0x03: 3, 0x0B: 4, 0x05: 12,
    0x04: 13, 0x06: 14, 0x0E: 15,
}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> bytes:
    out = bytearray(32)
    for char in ROOM03_TILE_BITMAPS:
        out += c64_char_to_pce_tile(char)
    assert len(out) == 9 * 32
    return bytes(out)


def bat_word(code: int) -> int:
    if code == 0 or code >= 9:
        pal = 0
    else:
        pal = PAL_BY_C64[ROOM03_COLOURS[code - 1] & 0x0F]
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
    cells = decode_room(ROOM03_RLE)
    assert len(cells) == ROOM_CELLS
    args.map.write_bytes(bytes(cells))
    args.screen_bat.write_bytes(make_screen_bat(cells))
    args.patterns.write_bytes(build_patterns())
    print(f'room 03: {len(ROOM03_RLE)} compressed bytes -> {len(cells)} cells; 9 patterns')


if __name__ == '__main__':
    main()
