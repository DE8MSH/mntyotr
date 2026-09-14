#!/usr/bin/env python3
"""Patch standard LoROM checksum/complement fields in a headerless 32 KiB ROM."""
from __future__ import annotations

import argparse
from pathlib import Path
import struct

HEADER = 0x7FC0
COMP = HEADER + 0x1C
CHECK = HEADER + 0x1E


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("rom", type=Path)
    args = ap.parse_args()
    data = bytearray(args.rom.read_bytes())
    if len(data) != 32768:
        raise SystemExit(f"expected 32768-byte LoROM, got {len(data)}")

    data[COMP:CHECK + 2] = b"\x00\x00\x00\x00"
    checksum = (sum(data) + 0x1FE) & 0xFFFF
    complement = checksum ^ 0xFFFF
    data[COMP:COMP + 2] = struct.pack("<H", complement)
    data[CHECK:CHECK + 2] = struct.pack("<H", checksum)
    args.rom.write_bytes(data)
    print(f"SNES checksum: {checksum:04X} complement: {complement:04X}")


if __name__ == "__main__":
    main()
