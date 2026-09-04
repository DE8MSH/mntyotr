#!/usr/bin/env python3
"""Overlay exact C64 room-$00 decorations onto the PCE BAT.

Primary reference: refactored/src/subsystems/decor_data.asm.
Phase 31 completes all room-$00 decor records, including type $43 sad_flowers
with its exact 3x3 bitmap and per-character C64 colour stream.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path

from room_rle import CHR_GAME, SCREEN_W

ROOM_Y0 = 3
SCREEN_X0 = 2
CHR_DECOR = CHR_GAME + 9

# Compact PCE palette allocation. 0..4 are used by the base room; decor uses
# 5..12. Values are C64 colour numbers, not PCE colour values.
PAL_BY_C64 = {
    0x0C: 5,  # medium grey
    0x0F: 6,  # light grey
    0x01: 7,  # white
    0x07: 8,  # yellow
    0x0D: 9,  # light green
    0x0A: 10, # light red
    0x08: 11, # orange
    0x05: 12, # green
}

# Exact 8-byte C64 character bitmaps, concatenated in row-major character order.
TYPE_BITMAPS = {
    0: bytes.fromhex(
        "18 18 18 3c 3c 6e 5e 5e "
        "5e 5e 5e 5e 5e 5e 5e ff"
    ),
    1: bytes.fromhex(
        "18 18 18 18 18 18 18 18 "
        "18 18 18 18 18 18 18 18 "
        "18 18 18 18 18 18 18 18 "
        "18 18 18 18 18 18 18 18"
    ),
    2: bytes.fromhex(
        "00 00 00 00 03 06 0c 1f "
        "00 00 00 00 ff fc fe ff "
        "00 00 00 00 c0 e0 70 30 "
        "00 0f 1f 0c 07 00 00 00 "
        "00 fe ff 06 fc 00 00 00 "
        "30 30 30 18 18 18 18 18"
    ),
    3: bytes.fromhex(
        "7f ff ff e0 ee e8 e8 e0 "
        "ff ff ff 18 1b 1a 1a 18 "
        "fe c1 fd 05 85 05 05 07 "
        "e0 e0 e0 ff ff e0 ee e8 "
        "18 18 18 ff ff 18 1b 1a "
        "07 07 07 ff ff 07 87 07 "
        "e8 a0 a0 a0 a0 bf 83 7f "
        "1a 18 18 18 18 ff ff ff "
        "07 07 07 07 07 ff ff fe"
    ),
    4: bytes.fromhex(
        "7f ff c0 db db db db 7f "
        "ff ff 61 6d 61 6f 6f ff "
        "ff ff bf bf bf bf 8f ff "
        "ff ff 84 bf 87 f7 87 ff "
        "fe ff 1f 7f 7f 7f 77 fe"
    ),
    5: bytes.fromhex(
        "00 00 00 2a 5d 3e 36 08 "
        "99 d3 6e 10 d3 6e 0c 08 "
        "ff df df 6e 6e 7e 3c 3c"
    ),
    6: bytes.fromhex(
        "00 00 00 2a 5d 3e 36 08 "
        "99 d3 6e 10 d3 6e 0c 08 "
        "ff df df 6e 6e 7e 3c 3c"
    ),
    0x43: bytes.fromhex(
        "00 00 00 07 1c 31 61 07 "
        "0c 08 18 d3 26 ac c9 69 "
        "00 00 00 c0 20 32 9a ce "
        "1c 10 31 21 27 64 47 40 "
        "37 14 d7 7d 1b 3a 38 00 "
        "60 30 10 9c c0 c0 78 08 "
        "f6 fa f6 77 0f 03 00 00 "
        "ff ff ff 7e 7e 7e 3c 3c "
        "1e 0f 0e 06 00 00 00 00"
    ),
}

# width, height, either a solid C64 colour int or an exact per-character stream.
TYPE_PROPS = {
    0: (1, 2, 0x0C),
    1: (1, 4, 0x0C),
    2: (3, 2, bytes.fromhex("0c 0c 0c 07 07 0c")),
    3: (3, 3, 0x0F),
    4: (5, 1, 0x01),
    5: (1, 3, bytes.fromhex("07 0d 0a")),
    6: (1, 3, bytes.fromhex("08 05 0a")),
    0x43: (3, 3, bytes.fromhex("05 05 05 05 05 05 07 0a 08")),
}

# Exact room-$00 records from Decor.room_list, in source order.
ROOM00_RECORDS = [
    (0x24, 0x10, 0),
    (0x24, 0x0C, 1),
    (0x24, 0x08, 1),
    (0x22, 0x06, 2),
    (0x17, 0x08, 3),
    (0x03, 0x08, 4),
    (0x0E, 0x0A, 5),
    (0x0C, 0x0C, 6),
    (0x21, 0x0F, 0x43),
]

TYPE_ORDER = (0, 1, 2, 3, 4, 5, 6, 0x43)


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> tuple[bytes, dict[int, int]]:
    out = bytearray()
    first_char: dict[int, int] = {}
    next_char = CHR_DECOR
    for type_id in TYPE_ORDER:
        raw = TYPE_BITMAPS[type_id]
        w, h, _ = TYPE_PROPS[type_id]
        assert len(raw) == w * h * 8
        first_char[type_id] = next_char
        for i in range(w * h):
            out += c64_char_to_pce_tile(raw[i*8:(i+1)*8])
            next_char += 1
    return bytes(out), first_char


def colours_for(type_id: int) -> list[int]:
    w, h, colour = TYPE_PROPS[type_id]
    count = w * h
    if isinstance(colour, int):
        return [colour] * count
    if len(colour) != count:
        raise ValueError(f"decor type {type_id} colour stream has {len(colour)} bytes, expected {count}")
    return list(colour)


def overlay_screen_bat(base: bytes) -> bytes:
    if len(base) != SCREEN_W * 20 * 2:
        raise ValueError(f"room screen BAT has {len(base)} bytes, expected 1440")
    words = list(struct.unpack("<" + "H" * (len(base)//2), base))
    _, first_char = build_patterns()
    for c64_x, c64_y, type_id in ROOM00_RECORDS:
        w, h, _ = TYPE_PROPS[type_id]
        local_x = c64_x - SCREEN_X0
        local_y = c64_y - ROOM_Y0
        if not (0 <= local_x < SCREEN_W and 0 <= local_y < 20):
            raise ValueError(f"decor type {type_id} starts outside room window")
        char = first_char[type_id]
        colours = colours_for(type_id)
        ci = 0
        for dy in range(h):
            for dx in range(w):
                x, y = local_x + dx, local_y + dy
                if not (0 <= x < SCREEN_W and 0 <= y < 20):
                    raise ValueError(f"decor type {type_id} extends outside room window")
                pal = PAL_BY_C64[colours[ci]]
                words[y*SCREEN_W+x] = (pal << 12) | char
                char += 1
                ci += 1
    return struct.pack("<" + "H" * len(words), *words)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--screen-bat", type=Path, required=True,
                    help="existing 36x20 BAT; overwritten with decor overlay")
    ap.add_argument("--patterns", type=Path, required=True,
                    help="write generated PCE decor patterns")
    args = ap.parse_args()
    base = args.screen_bat.read_bytes()
    decorated = overlay_screen_bat(base)
    patterns, _ = build_patterns()
    args.screen_bat.write_bytes(decorated)
    args.patterns.write_bytes(patterns)
    print(f"room 00 decor: {len(ROOM00_RECORDS)} records, {len(patterns)//32} chars")


if __name__ == "__main__":
    main()
