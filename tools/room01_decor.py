#!/usr/bin/env python3
"""Overlay exact C64 room-$01 decorations onto the PCE BAT.

Primary reference: refactored/src/subsystems/decor_data.asm.
Room $01 has two records in Decor.room_list:
  $01,$03,$11,$42  -> type 66 purple_flowers (4x4)
  $01,$1d,$07,$41  -> type 65 bunch_flower   (3x3)
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path

from room_rle import CHR_GAME, SCREEN_W

ROOM_Y0 = 3
SCREEN_X0 = 2
CHR_DECOR = CHR_GAME + 9

# Reuse the palette layout already loaded by room00 + room01 extras.
PAL_BY_C64 = {
    0x00: 0,   # black/background
    0x02: 2,   # red
    0x03: 3,   # cyan
    0x04: 13,  # purple (room01 extra palette)
    0x05: 12,  # green
    0x07: 8,   # yellow
    0x08: 11,  # orange
    0x0A: 10,  # light red
}

# Exact row-major 8-byte C64 character cells.
BUNCH_FLOWER = bytes.fromhex(
    "00 00 00 04 1c 2c 1c 0a "
    "00 00 a0 d8 d0 79 21 20 "
    "00 00 00 40 e0 90 e0 00 "
    "00 0c 1d 3e 04 0d 02 06 "
    "a6 58 a0 2f 1a b0 60 80 "
    "00 60 70 d8 f8 a0 00 00 "
    "3d 79 28 10 00 00 00 00 "
    "7e 7e bc bc bc 58 58 58 "
    "00 00 00 00 00 00 00 00"
)
BUNCH_COLOURS = bytes.fromhex("07 08 03 0a 05 04 08 02 00")

PURPLE_FLOWERS = bytes.fromhex(
    "00 00 01 07 0f 1f 3f 3f "
    "00 00 80 c1 e2 e6 e6 ef "
    "00 3f ff ff ff ff bf bf "
    "00 e0 f0 f8 f8 f8 fc fc "
    "7f 7f 3c 3c 11 1f 0c 00 "
    "fe be 7e ce 8f 07 c7 e7 "
    "9f c0 78 0f 21 70 f0 e0 "
    "e4 04 0c 18 f0 00 00 00 "
    "00 00 00 00 00 00 00 00 "
    "67 7f 3f 0e 0e 0e 07 00 "
    "80 00 00 00 00 00 00 00 "
    "00 00 00 00 00 00 00 00 "
    "01 00 00 00 00 00 00 00 "
    "df df df df ef 6f 77 3f "
    "f8 f0 f0 f0 f0 e0 e0 80 "
    "00 00 00 00 00 00 00 00"
)
PURPLE_COLOURS = bytes.fromhex("04 04 04 04 04 05 05 04 05 05 05 05 08 08 08 08")

# Preserve source room_list order: type $42 first, then $41.
TYPE_DATA = {
    0x42: (4, 4, PURPLE_FLOWERS, PURPLE_COLOURS),
    0x41: (3, 3, BUNCH_FLOWER, BUNCH_COLOURS),
}
ROOM01_RECORDS = (
    (0x03, 0x11, 0x42),
    (0x1D, 0x07, 0x41),
)
TYPE_ORDER = (0x42, 0x41)


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
    assert len(out) == 25 * 32
    return bytes(out), first


def overlay_screen_bat(base: bytes) -> bytes:
    if len(base) != SCREEN_W * 20 * 2:
        raise ValueError(f"room screen BAT has {len(base)} bytes, expected 1440")
    words = list(struct.unpack('<' + 'H'*(len(base)//2), base))
    _, first = build_patterns()
    for c64_x, c64_y, type_id in ROOM01_RECORDS:
        w, h, _raw, colours = TYPE_DATA[type_id]
        local_x = c64_x - SCREEN_X0
        local_y = c64_y - ROOM_Y0
        char = first[type_id]
        for i, colour in enumerate(colours):
            dy, dx = divmod(i, w)
            x, y = local_x + dx, local_y + dy
            if not (0 <= x < SCREEN_W and 0 <= y < 20):
                raise ValueError(f"decor type {type_id:02x} outside room window")
            pal = PAL_BY_C64[colour]
            words[y*SCREEN_W+x] = (pal << 12) | char
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
    print(f'room 01 decor: {len(ROOM01_RECORDS)} records, {len(patterns)//32} chars')


if __name__ == '__main__':
    main()
