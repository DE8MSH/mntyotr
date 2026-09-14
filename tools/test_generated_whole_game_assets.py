#!/usr/bin/env python3
"""Verify generated whole-game payloads before pceas assembly.

This is deliberately separate from the source-parity auditor: source parity asks
whether the port matches the original tables, while this checks that build.sh
actually emitted every binary payload that the assembler will incbin.
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOMS = range(0x34)
MAP_SIZE = 32 * 20
BAT_SIZE = 36 * 20 * 2
BASE_PATTERN_SIZE = 9 * 32

# R0A stores its 24 exact decor characters after the 9 base room chars in the
# same file; room0a_assets_tail.asm incbins 288 + 768 bytes from this payload.
ROOM_PATTERN_SIZES = {0x0A: (9 + 24) * 32}

# Exact unique Decor character counts for every generated source-derived decor
# payload.  Multiple placements of one type share the same uploaded glyphs.
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
        f"and {len(DECOR_CHARS)} source-derived decor rooms"
    )


if __name__ == "__main__":
    main()
