#!/usr/bin/env python3
"""Overlay exact C64 Room $0A decorations onto the generated PCE BAT."""
from __future__ import annotations

import argparse
import struct
from pathlib import Path

from room_rle import CHR_GAME, SCREEN_W

ROOM_Y0 = 3
SCREEN_X0 = 2
CHR_DECOR = CHR_GAME + 9

PAL_BY_C64 = {
    0x0F: 6,   # light grey
    0x08: 11,  # orange
    0x05: 12,  # green
    0x06: 14,  # blue
}

# Exact C64 Decor.room_list records for Room $0A.
ROOM0A_RECORDS = [
    (0x08, 0x12, 0x07),  # fireplace
    (0x04, 0x05, 0x08),  # books
    (0x04, 0x12, 0x09),  # green bottle
    (0x05, 0x12, 0x0B),  # blue bottle
]

TYPE_BITMAPS = {
    0x07: bytes.fromhex(
        "18 24 42 81 81 42 24 18 18 24 5a ad b5 5a 24 18 "
        "18 24 42 81 81 42 24 18 18 24 42 81 81 42 24 18 "
        "24 5a b5 ad 5a 24 18 24 24 5a a5 bd 5a 24 18 24 "
        "24 5a b5 b5 5a 24 18 24 24 5a ad ad 5a 24 18 24 "
        "5a b5 ad 5a ff 8f f0 60 5a bd a5 5a ff ff 00 00 "
        "5a ad b5 5a ff ff 00 00 42 81 81 42 ff f1 0f 06"
    ),
    0x08: bytes.fromhex(
        "80 9f 5f 40 9d 95 5d 5c 00 f8 fc 00 dc 5c ee ee "
        "00 00 00 00 38 28 28 30 01 01 02 02 39 29 52 52 "
        "94 9c 54 5c 9c 80 ff 7f d7 77 6b 3b 3b 00 ff ff "
        "28 28 b9 a9 b9 00 ff ff a1 a1 42 42 c1 01 ff fe"
    ),
    0x09: bytes.fromhex(
        "18 00 18 18 18 3c 2c 6e 5e 5e ff 81 db 81 db 7e"
    ),
    0x0B: bytes.fromhex(
        "18 18 18 18 3c 00 76 00 7a 7a 7a 7a 7a 7a 00 7e"
    ),
}

TYPE_PROPS = {
    0x07: (4, 3, 0x0F),
    0x08: (4, 2, 0x08),
    0x09: (1, 2, 0x05),
    0x0B: (1, 2, 0x06),
}

TYPE_ORDER = (0x07, 0x08, 0x09, 0x0B)


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
    assert len(out) == 24 * 32
    return bytes(out), first_char


def overlay_screen_bat(base: bytes) -> bytes:
    if len(base) != SCREEN_W * 20 * 2:
        raise ValueError(f"room screen BAT has {len(base)} bytes, expected 1440")
    words = list(struct.unpack("<" + "H" * (len(base)//2), base))
    _, first_char = build_patterns()
    for c64_x, c64_y, type_id in ROOM0A_RECORDS:
        w, h, colour = TYPE_PROPS[type_id]
        local_x = c64_x - SCREEN_X0
        local_y = c64_y - ROOM_Y0
        char = first_char[type_id]
        pal = PAL_BY_C64[colour]
        for dy in range(h):
            for dx in range(w):
                x, y = local_x + dx, local_y + dy
                if not (0 <= x < SCREEN_W and 0 <= y < 20):
                    raise ValueError(f"decor {type_id:02x} outside room at {x},{y}")
                words[y*SCREEN_W+x] = (pal << 12) | char
                char += 1
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
    print(f"room 0a decor: {len(ROOM0A_RECORDS)} records, {len(patterns)//32} chars")


if __name__ == "__main__":
    main()
