#!/usr/bin/env python3
"""Decode/verify Monty C64 room RLE and generate PCE room tables.

Primary reference: Dave-Agent/monty-on-the-run/refactored/src/subsystems/room.asm.
RLE expands to the 32x20 playfield.  On the C64 that playfield is copied to
screen columns 4..35, rows 3..22; CreatePlayfieldBorder mirrors its edge chars
into columns 2..3 and 36..37.  Character 0 stays blank and room slots 0..7 are
installed as screen character codes 1..8 by SetupTileGraphics.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import struct

ROOM_W = 32
ROOM_H = 20
ROOM_CELLS = ROOM_W * ROOM_H
SCREEN_W = 36                 # C64 cols 2..37 inclusive
CHR_GAME = 256                # must match src/platform.inc

ROOM00_RLE = bytes.fromhex(
    "f1 41 02 90 f1 51 02 80 f1 61 02 70 f1 71 02 60 "
    "f3 63 80 f3 63 80 f3 63 80 23 c0 63 80 f0 20 33 "
    "80 f0 40 13 80 90 44 50 13 80 f0 50 03 80 70 34 "
    "90 03 80 50 34 f0 50 f0 f0 65 e0 95 65 f0 85 85 "
    "40 45 30 85 f5 f5 f5 f5 ff ff"
)


def decode_room(stream: bytes) -> list[int]:
    out: list[int] = []
    i = 0
    while i < len(stream):
        if i + 1 < len(stream) and stream[i] == 0xFF and stream[i + 1] == 0xFF:
            i += 2
            break
        value = stream[i]
        i += 1
        out.extend([value & 0x0F] * ((value >> 4) + 1))
    if len(out) != ROOM_CELLS:
        raise ValueError(f"decoded {len(out)} cells, expected {ROOM_CELLS}")
    return out


def ascii_map(cells: list[int]) -> str:
    return "\n".join(
        "".join(format(v, "X") for v in cells[y * ROOM_W:(y + 1) * ROOM_W])
        for y in range(ROOM_H)
    )


def bat_word(tile_slot: int) -> int:
    if not 0 <= tile_slot <= 7:
        raise ValueError(f"room00 expects custom tile slot 0..7, got {tile_slot}")
    # C64 SetupTileGraphics: slot 0..7 becomes screen character code 1..8.
    code = tile_slot + 1
    return (code << 12) | (CHR_GAME + code)


def make_bat(cells: list[int]) -> bytes:
    """32x20 playfield BAT, using the C64 screen-code 1..8 mapping."""
    data = bytearray()
    for tile in cells:
        data += struct.pack("<H", bat_word(tile))
    return bytes(data)


def make_screen_bat(cells: list[int]) -> bytes:
    """20x36 C64-visible room window (screen columns 2..37).

    Each row is: left edge twice, 32 playfield chars, right edge twice.  This is
    exactly the geometry produced by Room.CreatePlayfieldBorder after the 32x20
    DrawRoomPlayfield copy.
    """
    data = bytearray()
    for y in range(ROOM_H):
        row = cells[y*ROOM_W:(y+1)*ROOM_W]
        expanded = [row[0], row[0], *row, row[-1], row[-1]]
        assert len(expanded) == SCREEN_W
        for tile in expanded:
            data += struct.pack("<H", bat_word(tile))
    return bytes(data)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", type=Path, help="write decoded 640-byte logical map")
    ap.add_argument("--bat", type=Path, help="write 1280-byte 32x20 PCE BAT table")
    ap.add_argument("--screen-bat", type=Path, help="write 1440-byte 36x20 C64 screen-window BAT")
    args = ap.parse_args()

    cells = decode_room(ROOM00_RLE)
    print(f"room 00: {len(ROOM00_RLE)} compressed bytes -> {len(cells)} cells")
    print(ascii_map(cells))
    if args.write:
        args.write.parent.mkdir(parents=True, exist_ok=True)
        args.write.write_bytes(bytes(cells))
        print(f"wrote {args.write} ({args.write.stat().st_size} bytes)")
    if args.bat:
        args.bat.parent.mkdir(parents=True, exist_ok=True)
        args.bat.write_bytes(make_bat(cells))
        print(f"wrote {args.bat} ({args.bat.stat().st_size} bytes)")
    if args.screen_bat:
        args.screen_bat.parent.mkdir(parents=True, exist_ok=True)
        args.screen_bat.write_bytes(make_screen_bat(cells))
        print(f"wrote {args.screen_bat} ({args.screen_bat.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
