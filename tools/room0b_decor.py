#!/usr/bin/env python3
"""Overlay exact C64 Room $0B decorations onto the generated PCE BAT."""
from __future__ import annotations

import argparse
import struct
from pathlib import Path

from room_rle import CHR_GAME, SCREEN_W

ROOM_Y0 = 3
SCREEN_X0 = 2
CHR_DECOR = CHR_GAME + 9

PAL_BY_C64 = {
    0x09: 1,   # brown
    0x01: 7,   # white
    0x0D: 9,   # light green
    0x0A: 10,  # light red
    0x05: 12,  # green
}

# Exact C64 Decor.room_list records for Room $0B.
ROOM0B_RECORDS = [
    (0x24, 0x12, 0x0C),  # red bottle
    (0x25, 0x12, 0x09),  # green bottle
    (0x20, 0x0C, 0x44),  # small bust
    (0x23, 0x0D, 0x3F),  # green pot plant
    (0x1E, 0x12, 0x20),  # C5 object
]

TYPE_BITMAPS = {
    0x0C: bytes.fromhex(
        "18 18 18 18 3c 00 76 00 "
        "7a 7a 7a 7a 7a 7a 00 7e"
    ),
    0x09: bytes.fromhex(
        "18 00 18 18 18 3c 2c 6e "
        "5e 5e ff 81 db 81 db 7e"
    ),
    0x44: bytes.fromhex(
        "01 09 0d 0a 08 48 28 4a "
        "4e 26 38 74 8c 92 90 92 "
        "40 80 a0 58 b0 40 9e a4 "
        "4a 44 48 48 12 02 01 00 "
        "53 51 88 8a 10 94 24 00 "
        "4a 50 54 20 20 40 00 00 "
        "01 01 01 00 00 00 00 00 "
        "7f 3f bf bf 9f df 6e 7e "
        "80 80 80 00 00 00 00 00"
    ),
    0x3F: bytes.fromhex(
        "92 b2 a6 d8 70 21 27 80 "
        "73 23 c6 9c 89 8d de 01 "
        "ff df ef 6f 77 37 3f 10 "
        "ff ff ff fe fe fc fc 08"
    ),
    0x20: bytes.fromhex(
        "00 00 00 00 01 03 0f 17 "
        "00 00 00 7c f8 f0 e0 c0 "
        "00 00 00 00 00 00 00 01 "
        "08 08 08 18 18 38 78 f8 "
        "37 4f 7f 7f 3f 41 74 38 "
        "c6 d9 ef f0 ff ff 00 00 "
        "03 cf bf 7e fd fd 01 00 "
        "f8 fc 1e ee 76 b6 d0 e0"
    ),
}

TYPE_PROPS = {
    0x0C: (1, 2, 0x0A),
    0x09: (1, 2, 0x05),
    0x44: (3, 3, bytes.fromhex("0d 0d 0d 0d 0d 0d 09 09 09")),
    0x3F: (2, 2, bytes.fromhex("0d 0d 09 09")),
    0x20: (4, 2, 0x01),
}

TYPE_ORDER = (0x0C, 0x09, 0x44, 0x3F, 0x20)


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
    assert len(out) == 25 * 32
    return bytes(out), first_char


def colours_for(type_id: int) -> list[int]:
    w, h, colour = TYPE_PROPS[type_id]
    count = w * h
    if isinstance(colour, int):
        return [colour] * count
    assert len(colour) == count
    return list(colour)


def overlay_screen_bat(base: bytes) -> bytes:
    if len(base) != SCREEN_W * 20 * 2:
        raise ValueError(f"room screen BAT has {len(base)} bytes, expected 1440")
    words = list(struct.unpack("<" + "H" * (len(base)//2), base))
    _, first_char = build_patterns()
    for c64_x, c64_y, type_id in ROOM0B_RECORDS:
        w, h, _ = TYPE_PROPS[type_id]
        local_x = c64_x - SCREEN_X0
        local_y = c64_y - ROOM_Y0
        char = first_char[type_id]
        colours = colours_for(type_id)
        ci = 0
        for dy in range(h):
            for dx in range(w):
                x, y = local_x + dx, local_y + dy
                if not (0 <= x < SCREEN_W and 0 <= y < 20):
                    raise ValueError(f"decor {type_id:02x} outside room at {x},{y}")
                pal = PAL_BY_C64[colours[ci]]
                words[y*SCREEN_W+x] = (pal << 12) | char
                char += 1
                ci += 1
    return struct.pack("<" + "H" * len(words), *words)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--screen-bat", type=Path, required=True)
    ap.add_argument("--patterns", type=Path, required=True)
    args = ap.parse_args()
    base = args.screen_bat.read_bytes()
    args.screen_bat.write_bytes(overlay_screen_bat(base))
    patterns, _ = build_patterns()
    args.patterns.write_bytes(patterns)
    print(f"room 0b decor: {len(ROOM0B_RECORDS)} records, {len(patterns)//32} chars")


if __name__ == "__main__":
    main()
