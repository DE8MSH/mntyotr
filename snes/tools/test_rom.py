#!/usr/bin/env python3
"""Static smoke test for the isolated SNES ROM image."""
from __future__ import annotations

import argparse
from pathlib import Path
import struct

HEADER = 0x7FC0


def u16(data: bytes, offset: int) -> int:
    return struct.unpack_from("<H", data, offset)[0]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("rom", type=Path)
    args = ap.parse_args()
    data = args.rom.read_bytes()

    assert len(data) == 32768, len(data)
    assert data[HEADER:HEADER + 21] == b"MONTY SNES PARALLEL  "
    assert data[HEADER + 21] == 0x20, "not LoROM/SlowROM"
    assert data[HEADER + 23] == 0x05, "unexpected ROM-size header byte"

    complement = u16(data, HEADER + 0x1C)
    checksum = u16(data, HEADER + 0x1E)
    assert (complement ^ checksum) == 0xFFFF
    assert (sum(data) & 0xFFFF) == checksum

    native_nmi = u16(data, 0x7FEA)
    emu_nmi = u16(data, 0x7FFA)
    reset = u16(data, 0x7FFC)
    assert 0x8000 <= native_nmi <= 0xFFFF
    assert 0x8000 <= emu_nmi <= 0xFFFF
    assert 0x8000 <= reset <= 0xFFFF

    print(f"ROM smoke OK: reset=${reset:04X} nmi=${native_nmi:04X} checksum=${checksum:04X}")


if __name__ == "__main__":
    main()
