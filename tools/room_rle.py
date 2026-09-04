#!/usr/bin/env python3
"""Decode/verify Monty C64 room RLE streams.

Format from the annotated reconstruction:
  high nibble = repeat count - 1
  low nibble  = logical tile id
  FF FF       = stream terminator
A single FF remains a valid run of sixteen tile-15 cells.
"""
from __future__ import annotations

import argparse
from pathlib import Path

ROOM_W = 32
ROOM_H = 20
ROOM_CELLS = ROOM_W * ROOM_H

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
    rows = []
    for y in range(ROOM_H):
        row = cells[y * ROOM_W:(y + 1) * ROOM_W]
        rows.append("".join(format(v, "X") for v in row))
    return "\n".join(rows)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", type=Path, help="write decoded 640-byte logical map")
    args = ap.parse_args()

    cells = decode_room(ROOM00_RLE)
    print(f"room 00: {len(ROOM00_RLE)} compressed bytes -> {len(cells)} cells")
    print(ascii_map(cells))
    if args.write:
        args.write.parent.mkdir(parents=True, exist_ok=True)
        args.write.write_bytes(bytes(cells))
        print(f"wrote {args.write}")


if __name__ == "__main__":
    main()
