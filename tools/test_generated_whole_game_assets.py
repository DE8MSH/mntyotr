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

    # Exact R10-R1F decor payloads currently emitted by the source-derived decor
    # generator. Sizes are characters * 32 bytes.
    decor_sizes = {
        0x10: 736, 0x11: 1536, 0x12: 1056, 0x13: 192,
        0x1D: 1632, 0x1E: 832, 0x1F: 1792,
    }
    for room, expected in decor_sizes.items():
        require_size(build / f"room{room:02x}-decor-patterns.dat", expected)

    print(
        f"OK: generated payloads for 52 rooms, {len(enemy_files)} enemy banks, "
        f"and {len(decor_sizes)} late decor rooms"
    )


if __name__ == "__main__":
    main()
