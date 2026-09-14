#!/usr/bin/env python3
"""Generate isolated SNES Room $00 graphics from C64-semantic data.

No file outside snes/ is read. The tables mirror the already verified Room $00
semantics used by the PCE port, but the emitted format is native SNES: 4bpp CHR,
a 32x32 Mode-1 tilemap, and one 16-colour BGR555 CGRAM palette.

The SNES viewport is the 32x20 gameplay playfield (C64 columns 4..35), so decor
that belongs only to the C64/PCE side gutters is intentionally clipped.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import struct

ROOM_W = 32
ROOM_H = 20
MAP_W = 32
MAP_H = 32
MAP_Y = 4
C64_PLAYFIELD_X = 4
C64_PLAYFIELD_Y = 3

ROOM00_RLE = bytes.fromhex(
    "f1 41 02 90 f1 51 02 80 f1 61 02 70 f1 71 02 60 "
    "f3 63 80 f3 63 80 f3 63 80 23 c0 63 80 f0 20 33 "
    "80 f0 40 13 80 90 44 50 13 80 f0 50 03 80 70 34 "
    "90 03 80 50 34 f0 50 f0 f0 65 e0 95 65 f0 85 85 "
    "40 45 30 85 f5 f5 f5 f5 ff ff"
)

BASE_CHAR_ROWS = (
    bytes(8),
    bytes.fromhex("ee 44 11 bb bb 11 c4 ef"),
    bytes.fromhex("00 00 00 80 a0 10 c0 ec"),
    bytes.fromhex("00 fe fe fe 00 ef ef ef"),
    bytes.fromhex("ff 55 aa ff 00 00 00 00"),
    bytes.fromhex("44 38 83 c6 44 6c 38 83"),
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
    bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
)
BASE_COLOUR_BY_CODE = (0, 9, 9, 2, 3, 11, 0, 0, 0)

DECOR_BITMAPS = {
    0: bytes.fromhex("18 18 18 3c 3c 6e 5e 5e 5e 5e 5e 5e 5e 5e 5e ff"),
    1: bytes.fromhex(
        "18 18 18 18 18 18 18 18 18 18 18 18 18 18 18 18 "
        "18 18 18 18 18 18 18 18 18 18 18 18 18 18 18 18"
    ),
    2: bytes.fromhex(
        "00 00 00 00 03 06 0c 1f 00 00 00 00 ff fc fe ff "
        "00 00 00 00 c0 e0 70 30 00 0f 1f 0c 07 00 00 00 "
        "00 fe ff 06 fc 00 00 00 30 30 30 18 18 18 18 18"
    ),
    3: bytes.fromhex(
        "7f ff ff e0 ee e8 e8 e0 ff ff ff 18 1b 1a 1a 18 "
        "fe c1 fd 05 85 05 05 07 e0 e0 e0 ff ff e0 ee e8 "
        "18 18 18 ff ff 18 1b 1a 07 07 07 ff ff 07 87 07 "
        "e8 a0 a0 a0 a0 bf 83 7f 1a 18 18 18 18 ff ff ff "
        "07 07 07 07 07 ff ff fe"
    ),
    4: bytes.fromhex(
        "7f ff c0 db db db db 7f ff ff 61 6d 61 6f 6f ff "
        "ff ff bf bf bf bf 8f ff ff ff 84 bf 87 f7 87 ff "
        "fe ff 1f 7f 7f 7f 77 fe"
    ),
    5: bytes.fromhex(
        "00 00 00 2a 5d 3e 36 08 99 d3 6e 10 d3 6e 0c 08 "
        "ff df df 6e 6e 7e 3c 3c"
    ),
    6: bytes.fromhex(
        "00 00 00 2a 5d 3e 36 08 99 d3 6e 10 d3 6e 0c 08 "
        "ff df df 6e 6e 7e 3c 3c"
    ),
    0x43: bytes.fromhex(
        "00 00 00 07 1c 31 61 07 0c 08 18 d3 26 ac c9 69 "
        "00 00 00 c0 20 32 9a ce 1c 10 31 21 27 64 47 40 "
        "37 14 d7 7d 1b 3a 38 00 60 30 10 9c c0 c0 78 08 "
        "f6 fa f6 77 0f 03 00 00 ff ff ff 7e 7e 7e 3c 3c "
        "1e 0f 0e 06 00 00 00 00"
    ),
}

DECOR_PROPS = {
    0: (1, 2, 0x0C),
    1: (1, 4, 0x0C),
    2: (3, 2, bytes.fromhex("0c 0c 0c 07 07 0c")),
    3: (3, 3, 0x0F),
    4: (5, 1, 0x01),
    5: (1, 3, bytes.fromhex("07 0d 0a")),
    6: (1, 3, bytes.fromhex("08 05 0a")),
    0x43: (3, 3, bytes.fromhex("05 05 05 05 05 05 07 0a 08")),
}
DECOR_RECORDS = (
    (0x24, 0x10, 0),
    (0x24, 0x0C, 1),
    (0x24, 0x08, 1),
    (0x22, 0x06, 2),
    (0x17, 0x08, 3),
    (0x03, 0x08, 4),
    (0x0E, 0x0A, 5),
    (0x0C, 0x0C, 6),
    (0x21, 0x0F, 0x43),
)
DECOR_ORDER = (0, 1, 2, 3, 4, 5, 6, 0x43)

C64_RGB = (
    (0x00, 0x00, 0x00), (0xFF, 0xFF, 0xFF),
    (0x88, 0x39, 0x32), (0x67, 0xB6, 0xBD),
    (0x8B, 0x3F, 0x96), (0x55, 0xA0, 0x49),
    (0x40, 0x31, 0x8D), (0xBF, 0xCE, 0x72),
    (0x8B, 0x54, 0x29), (0x57, 0x42, 0x00),
    (0xB8, 0x69, 0x62), (0x50, 0x50, 0x50),
    (0x78, 0x78, 0x78), (0x94, 0xE0, 0x89),
    (0x78, 0x69, 0xC4), (0x9F, 0x9F, 0x9F),
)


def decode_room() -> list[int]:
    out: list[int] = []
    i = 0
    while i < len(ROOM00_RLE):
        if i + 1 < len(ROOM00_RLE) and ROOM00_RLE[i:i + 2] == b"\xff\xff":
            break
        value = ROOM00_RLE[i]
        i += 1
        out.extend([value & 0x0F] * ((value >> 4) + 1))
    if len(out) != ROOM_W * ROOM_H:
        raise ValueError(f"Room 00 decodes to {len(out)} cells, expected 640")
    if max(out) > 8:
        raise ValueError("Room 00 base map contains unsupported screen code")
    return out


def snes_4bpp(rows: bytes, colour: int) -> bytes:
    if len(rows) != 8 or not 0 <= colour <= 15:
        raise ValueError("bad tile input")
    planes01 = bytearray()
    planes23 = bytearray()
    for bits in rows:
        planes01 += bytes((bits if colour & 1 else 0, bits if colour & 2 else 0))
    for bits in rows:
        planes23 += bytes((bits if colour & 4 else 0, bits if colour & 8 else 0))
    data = bytes(planes01 + planes23)
    assert len(data) == 32
    return data


def decor_colours(type_id: int) -> list[int]:
    w, h, colour = DECOR_PROPS[type_id]
    count = w * h
    if isinstance(colour, int):
        return [colour] * count
    if len(colour) != count:
        raise ValueError(f"decor {type_id:02x} has invalid colour stream")
    return list(colour)


def make_chr() -> tuple[bytes, dict[int, int]]:
    out = bytearray()
    for code, rows in enumerate(BASE_CHAR_ROWS):
        out += snes_4bpp(rows, BASE_COLOUR_BY_CODE[code])

    first_tile: dict[int, int] = {}
    next_tile = len(BASE_CHAR_ROWS)
    for type_id in DECOR_ORDER:
        raw = DECOR_BITMAPS[type_id]
        w, h, _ = DECOR_PROPS[type_id]
        colours = decor_colours(type_id)
        if len(raw) != w * h * 8:
            raise ValueError(f"decor {type_id:02x}: invalid bitmap size")
        first_tile[type_id] = next_tile
        for i, colour in enumerate(colours):
            out += snes_4bpp(raw[i * 8:(i + 1) * 8], colour)
            next_tile += 1
    if next_tile != 50:
        raise AssertionError(f"expected 50 total tiles, got {next_tile}")
    return bytes(out), first_tile


def make_tilemap(cells: list[int], first_tile: dict[int, int]) -> bytes:
    words = [0] * (MAP_W * MAP_H)
    for y in range(ROOM_H):
        for x in range(ROOM_W):
            words[(MAP_Y + y) * MAP_W + x] = cells[y * ROOM_W + x]

    for c64_x, c64_y, type_id in DECOR_RECORDS:
        w, h, _ = DECOR_PROPS[type_id]
        tile = first_tile[type_id]
        for dy in range(h):
            for dx in range(w):
                local_x = c64_x + dx - C64_PLAYFIELD_X
                local_y = c64_y + dy - C64_PLAYFIELD_Y
                if 0 <= local_x < ROOM_W and 0 <= local_y < ROOM_H:
                    words[(MAP_Y + local_y) * MAP_W + local_x] = tile
                tile += 1

    return struct.pack("<" + "H" * len(words), *words)


def rgb_to_bgr555(rgb: tuple[int, int, int]) -> int:
    r, g, b = (round(c * 31 / 255) for c in rgb)
    return r | (g << 5) | (b << 10)


def make_palette() -> bytes:
    return struct.pack("<16H", *(rgb_to_bgr555(rgb) for rgb in C64_RGB))


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", type=Path, required=True)
    args = ap.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    cells = decode_room()
    chr_data, first_tile = make_chr()
    outputs = {
        "room00.chr": chr_data,
        "room00.map": make_tilemap(cells, first_tile),
        "c64.pal": make_palette(),
    }
    expected = {"room00.chr": 50 * 32, "room00.map": 32 * 32 * 2, "c64.pal": 16 * 2}
    for name, data in outputs.items():
        if len(data) != expected[name]:
            raise AssertionError(f"{name}: {len(data)} != {expected[name]}")
        path = args.out_dir / name
        path.write_bytes(data)
        print(f"wrote {path} ({len(data)} bytes)")

    print("Room 00: 640 logical cells, 50 SNES 4bpp tiles, exact decor clipped to 32-column playfield")


if __name__ == "__main__":
    main()
