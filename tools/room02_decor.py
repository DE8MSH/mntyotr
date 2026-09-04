#!/usr/bin/env python3
"""Overlay exact C64 room-$02 decorations onto the PCE BAT.

Primary reference: refactored/src/subsystems/decor_data.asm.
Room $02 records, in original room_list order:
  $02,$04,$0c,$19 -> grandfather_clock (type 25, 3x9, brown)
  $02,$22,$0a,$08 -> books             (type 8, 4x2, orange)
  $02,$03,$12,$05 -> yellow_flower     (type 5, 1x3)
  $02,$07,$12,$06 -> brown_flower      (type 6, 1x3)
  $02,$20,$11,$42 -> purple_flowers    (type 66, 4x4)
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path

from room_rle import CHR_GAME, SCREEN_W
from room01_decor import PURPLE_FLOWERS, PURPLE_COLOURS

ROOM_Y0 = 3
SCREEN_X0 = 2
CHR_DECOR = CHR_GAME + 9

PAL_BY_C64 = {
    0x04: 13,  # purple
    0x05: 12,  # green
    0x07: 8,   # yellow
    0x08: 11,  # orange
    0x09: 1,   # brown
    0x0A: 10,  # light red
    0x0D: 9,   # light green
}

GRANDFATHER_CLOCK = bytes.fromhex(
    "1f 3f 70 67 ef cf df dd ff ff 00 ff e7 7e fb fb "
    "f8 fc 0e e6 f7 f3 fb bb df db db df cd ef 6f 67 "
    "fb f7 e7 df bf 7f 7e e7 fb db db f3 b7 f6 f6 e6 "
    "73 30 3f 15 1f 15 1d 19 ff 00 ff ff 81 18 18 18 "
    "ce 0c fc a8 f8 a8 b8 98 19 19 19 19 19 19 19 19 "
    "18 18 18 18 19 19 19 19 98 98 98 98 58 d8 d8 d8 "
    "19 19 19 19 19 19 19 19 18 18 18 18 18 18 18 18 "
    "98 18 18 18 18 18 18 18 19 19 19 19 19 19 19 1a "
    "18 18 18 18 18 18 18 98 18 18 18 18 18 18 18 18 "
    "1b 1b 1b 19 18 18 18 18 98 98 98 18 18 24 7e df "
    "18 18 18 18 18 18 18 18 18 18 18 1c 14 16 1b 3d "
    "9f 9b df 7e 3c 00 81 ff 18 18 18 38 28 68 d8 bc "
    "3f 7f fe fe ff 7f 0f 60 ff 00 55 aa 00 ff ff 00 "
    "fc fe 7f 7f ff fe f0 06"
)
BOOKS = bytes.fromhex(
    "80 9f 5f 40 9d 95 5d 5c 00 f8 fc 00 dc 5c ee ee "
    "00 00 00 00 38 28 28 30 01 01 02 02 39 29 52 52 "
    "94 9c 54 5c 9c 80 ff 7f d7 77 6b 3b 3b 00 ff ff "
    "28 28 b9 a9 b9 00 ff ff a1 a1 42 42 c1 01 ff fe"
)
YELLOW_FLOWER = bytes.fromhex(
    "00 00 00 2a 5d 3e 36 08 99 d3 6e 10 d3 6e 0c 08 "
    "ff df df 6e 6e 7e 3c 3c"
)

YELLOW_FLOWER_COLOURS = bytes.fromhex("07 0d 0a")
BROWN_FLOWER_COLOURS = bytes.fromhex("08 05 0a")

TYPE_DATA = {
    0x19: (3, 9, GRANDFATHER_CLOCK, bytes([0x09]) * 27),
    0x08: (4, 2, BOOKS, bytes([0x08]) * 8),
    0x05: (1, 3, YELLOW_FLOWER, YELLOW_FLOWER_COLOURS),
    0x06: (1, 3, YELLOW_FLOWER, BROWN_FLOWER_COLOURS),
    0x42: (4, 4, PURPLE_FLOWERS, PURPLE_COLOURS),
}
ROOM02_RECORDS = (
    (0x04, 0x0C, 0x19),
    (0x22, 0x0A, 0x08),
    (0x03, 0x12, 0x05),
    (0x07, 0x12, 0x06),
    (0x20, 0x11, 0x42),
)
TYPE_ORDER = (0x19, 0x08, 0x05, 0x06, 0x42)


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> tuple[bytes, dict[int, int]]:
    out = bytearray()
    first: dict[int, int] = {}
    next_char = CHR_DECOR
    for type_id in TYPE_ORDER:
        w, h, raw, colours = TYPE_DATA[type_id]
        assert len(raw) == w * h * 8
        assert len(colours) == w * h
        first[type_id] = next_char
        for i in range(w * h):
            out += c64_char_to_pce_tile(raw[i*8:(i+1)*8])
            next_char += 1
    assert len(out) == 57 * 32
    return bytes(out), first


def overlay_screen_bat(base: bytes) -> bytes:
    if len(base) != SCREEN_W * 20 * 2:
        raise ValueError(f"room screen BAT has {len(base)} bytes, expected 1440")
    words = list(struct.unpack('<' + 'H'*(len(base)//2), base))
    _, first = build_patterns()
    for c64_x, c64_y, type_id in ROOM02_RECORDS:
        w, h, _raw, colours = TYPE_DATA[type_id]
        local_x = c64_x - SCREEN_X0
        local_y = c64_y - ROOM_Y0
        char = first[type_id]
        for i, colour in enumerate(colours):
            dy, dx = divmod(i, w)
            x, y = local_x + dx, local_y + dy
            if not (0 <= x < SCREEN_W and 0 <= y < 20):
                raise ValueError(f"decor type {type_id:02x} outside room window")
            words[y*SCREEN_W+x] = (PAL_BY_C64[colour] << 12) | char
            char += 1
    return struct.pack('<' + 'H'*len(words), *words)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--screen-bat', type=Path, required=True)
    ap.add_argument('--patterns', type=Path, required=True)
    args = ap.parse_args()
    args.screen_bat.write_bytes(overlay_screen_bat(args.screen_bat.read_bytes()))
    patterns, _ = build_patterns()
    args.patterns.write_bytes(patterns)
    print(f'room 02 decor: {len(ROOM02_RECORDS)} records, {len(patterns)//32} chars')


if __name__ == '__main__':
    main()
