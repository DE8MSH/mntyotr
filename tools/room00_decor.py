#!/usr/bin/env python3
"""Overlay the first exact C64 room-$00 decoration types onto the PCE BAT.

Primary reference: refactored/src/subsystems/decor_data.asm.
This phase ports the solid-colour decoration records used by room $00:
types 0,1,3,4 (lamp base/pole, window, MPL ST sign). Pattern-colour types
2,5,6,67 are intentionally left for the next decor phase.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path

from room_rle import CHR_GAME, SCREEN_W

ROOM_Y0 = 3
SCREEN_X0 = 2
CHR_DECOR = CHR_GAME + 9

# C64 colour -> dedicated PCE BG palette index for this phase.
# type 0/1 use $0c, type 3 uses $0f, type 4 uses $01.
PAL_BY_C64 = {0x0C: 9, 0x0F: 10, 0x01: 11}

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
}

# width, height, solid C64 colour
TYPE_PROPS = {
    0: (1, 2, 0x0C),
    1: (1, 4, 0x0C),
    3: (3, 3, 0x0F),
    4: (5, 1, 0x01),
}

# Exact room-$00 records from Decor.room_list for the solid subset.
ROOM00_RECORDS = [
    (0x24, 0x10, 0),
    (0x24, 0x0C, 1),
    (0x24, 0x08, 1),
    (0x17, 0x08, 3),
    (0x03, 0x08, 4),
]


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    # PCE 8x8 4bpp tile: planes 0/1 interleaved for 8 rows, then planes 2/3.
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def build_patterns() -> tuple[bytes, dict[int, int]]:
    out = bytearray()
    first_char: dict[int, int] = {}
    next_char = CHR_DECOR
    for type_id in (0, 1, 3, 4):
        raw = TYPE_BITMAPS[type_id]
        w, h, _ = TYPE_PROPS[type_id]
        assert len(raw) == w * h * 8
        first_char[type_id] = next_char
        for i in range(w * h):
            out += c64_char_to_pce_tile(raw[i*8:(i+1)*8])
            next_char += 1
    return bytes(out), first_char


def overlay_screen_bat(base: bytes) -> bytes:
    if len(base) != SCREEN_W * 20 * 2:
        raise ValueError(f"room screen BAT has {len(base)} bytes, expected 1440")
    words = list(struct.unpack("<" + "H" * (len(base)//2), base))
    _, first_char = build_patterns()
    for c64_x, c64_y, type_id in ROOM00_RECORDS:
        w, h, colour = TYPE_PROPS[type_id]
        local_x = c64_x - SCREEN_X0
        local_y = c64_y - ROOM_Y0
        if not (0 <= local_x < SCREEN_W and 0 <= local_y < 20):
            raise ValueError(f"decor type {type_id} starts outside room window")
        char = first_char[type_id]
        pal = PAL_BY_C64[colour]
        for dy in range(h):
            for dx in range(w):
                x, y = local_x + dx, local_y + dy
                if not (0 <= x < SCREEN_W and 0 <= y < 20):
                    raise ValueError(f"decor type {type_id} extends outside room window")
                words[y*SCREEN_W+x] = (pal << 12) | char
                char += 1
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
    print(f"room 00 decor: {len(ROOM00_RECORDS)} solid records, {len(patterns)//32} chars")


if __name__ == "__main__":
    main()
