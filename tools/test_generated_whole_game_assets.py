#!/usr/bin/env python3
"""Verify generated whole-game payloads before pceas assembly.

This is deliberately separate from the source-parity auditor: source parity asks
whether the port matches the original tables, while this checks that build.sh
actually emitted every binary payload that the assembler will incbin.
"""
from __future__ import annotations

import argparse
import re
import struct
from pathlib import Path

from rooms20_33_decor import (
    PAL_BY_C64 as LATE_PAL_BY_C64,
    ROOM_RECORDS as LATE_DECOR_RECORDS,
    TYPE_DATA as LATE_TYPE_DATA,
    ROOM_Y0 as LATE_ROOM_Y0,
    SCREEN_X0 as LATE_SCREEN_X0,
    build_room_patterns as build_late_decor_patterns,
)

ROOMS = range(0x34)
MAP_SIZE = 32 * 20
BAT_W = 36
BAT_H = 20
BAT_SIZE = BAT_W * BAT_H * 2
BASE_PATTERN_SIZE = 9 * 32

# R0A stores its 24 exact decor characters after the 9 base room chars in the
# same file; room0a_assets_tail.asm incbins 288 + 768 bytes from this payload.
ROOM_PATTERN_SIZES = {0x0A: (9 + 24) * 32}

# Exact unique Decor character counts for every generated source-derived decor
# payload. Multiple placements of one type share the same uploaded glyphs.
DECOR_CHARS = {
    0x10:23, 0x11:48, 0x12:33, 0x13:6, 0x1D:51, 0x1E:26, 0x1F:56,
    0x20:34, 0x21:4, 0x22:4, 0x23:50, 0x24:22, 0x25:36, 0x26:44,
    0x27:45, 0x28:22, 0x29:59, 0x2B:30, 0x2D:36, 0x2E:35, 0x30:9,
    0x31:54, 0x32:49, 0x33:51,
}


def require_size(path: Path, expected: int) -> None:
    if not path.exists():
        raise AssertionError(f"missing generated asset: {path.name}")
    got = path.stat().st_size
    if got != expected:
        raise AssertionError(f"{path.name}: {got} bytes, expected {expected}")


def verify_late_decor_payload(build: Path, room: int) -> None:
    """Prove that generated pattern bytes and final BAT cells match the guarded truth."""
    prefix = f"room{room:02x}"
    expected_patterns, first_char = build_late_decor_patterns(room)
    actual_patterns = (build / f"{prefix}-decor-patterns.dat").read_bytes()
    assert actual_patterns == expected_patterns, f"R{room:02X} decor pattern bytes differ"

    bat = (build / f"{prefix}-screen-bat.dat").read_bytes()
    words = struct.unpack("<" + "H" * (len(bat) // 2), bat)

    # Build the exact final cells. Later room_list records overwrite earlier
    # cells just as the original decoration pass does (important in R26).
    expected_cells: dict[tuple[int, int], int] = {}
    for c64_x, c64_y, typ in LATE_DECOR_RECORDS[room]:
        w, h, _bmp_hex, cols_hex = LATE_TYPE_DATA[typ]
        cols = bytes.fromhex(cols_hex)
        char = first_char[typ]
        ci = 0
        x0 = c64_x - LATE_SCREEN_X0
        y0 = c64_y - LATE_ROOM_Y0
        for dy in range(h):
            for dx in range(w):
                x, y = x0 + dx, y0 + dy
                assert 0 <= x < BAT_W and 0 <= y < BAT_H, (room, typ, x, y)
                expected_cells[(x, y)] = (LATE_PAL_BY_C64[cols[ci]] << 12) | char
                char += 1
                ci += 1

    for (x, y), expected in expected_cells.items():
        actual = words[y * BAT_W + x]
        assert actual == expected, (
            f"R{room:02X} Decor BAT mismatch at ({x},{y}): "
            f"${actual:04X} != ${expected:04X}"
        )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("build_dir", type=Path)
    ap.add_argument("--src-dir", type=Path, default=Path(__file__).resolve().parents[1] / "src")
    args = ap.parse_args()
    build = args.build_dir

    for room in ROOMS:
        prefix = f"room{room:02x}"
        require_size(build / f"{prefix}-map.dat", MAP_SIZE)
        require_size(build / f"{prefix}-screen-bat.dat", BAT_SIZE)
        if room != 0:
            require_size(build / f"{prefix}-patterns.dat", ROOM_PATTERN_SIZES.get(room, BASE_PATTERN_SIZE))

    # Every enemy payload referenced by the assembled asset tail must exist and
    # be a complete 4 KiB PCE slot upload image.
    enemy_tail = (args.src_dir / "enemy_room00_assets_tail.asm").read_text(errors="replace")
    enemy_files = sorted(set(re.findall(r'incbin\s+"(enemy-[^"]+\.dat)"', enemy_tail, re.I)))
    assert enemy_files, "no enemy incbins discovered"
    for filename in enemy_files:
        require_size(build / filename, 4096)

    for room, chars in DECOR_CHARS.items():
        require_size(build / f"room{room:02x}-decor-patterns.dat", chars * 32)

    # For $20-$33, do not stop at file size: compare every emitted decor pattern
    # byte and every final decorated BAT cell (tile index + PCE palette) against
    # the source-guarded room/x/y/type/colour tables.
    for room in sorted(LATE_DECOR_RECORDS):
        verify_late_decor_payload(build, room)

    # $2A/$2C/$2F really have no Decor.room_list entries. Their lack of a decor
    # payload is source truth, not an omitted build artifact.
    for room in (0x2A, 0x2C, 0x2F):
        path = build / f"room{room:02x}-decor-patterns.dat"
        if path.exists():
            raise AssertionError(f"unexpected decor payload for R{room:02X}")

    late_loader = (args.src_dir / "room20_33_decor_loader.asm").read_text(errors="replace")
    for needle in ("$20,$21,$22,$23", "$2b,$2d,$2e,$30,$31,$32,$33", "room33_decor_patterns"):
        assert needle in late_loader, needle

    print(
        f"OK: generated payloads for 52 rooms, {len(enemy_files)} enemy banks, "
        f"{len(DECOR_CHARS)} decor rooms; late Decor bytes/BAT placement/palettes exact"
    )


if __name__ == "__main__":
    main()
