#!/usr/bin/env python3
"""Small deterministic asset converter used during the Monty PCE port.

Converts a C64 hires 8x8 character (8 bytes, 1 bit/pixel) into a PC Engine
8x8 background pattern (32 bytes, 4 planar bits/pixel). Foreground pixels use
PCE colour index 1 and background pixels use index 0.
"""
from __future__ import annotations

# Room $00 definition bytes 0..7 from the annotated C64 reconstruction.
ROOM00_TILE_LIBRARY_INDEX = [0x0A, 0x0B, 0x01, 0x3A, 0x15, 0x00, 0x00, 0x00]
ROOM00_C64_COLOUR = [0x09, 0x09, 0x02, 0x03, 0x0B, 0x00, 0x00, 0x00]

# The library characters needed by room $00. Each entry is exactly 8 C64 rows.
C64_CHARS = {
    0x00: bytes.fromhex("30 ff 03 ff 30 ff 03 ff"),
    0x01: bytes.fromhex("00 fe fe fe 00 ef ef ef"),
    0x0A: bytes.fromhex("ee 44 11 bb bb 11 c4 ef"),
    0x0B: bytes.fromhex("00 00 00 80 a0 10 c0 ec"),
    0x15: bytes.fromhex("44 38 83 c6 44 6c 38 83"),
    0x3A: bytes.fromhex("ff 55 aa ff 00 00 00 00"),
}

# Pepto-like RGB approximations, used only to choose the nearest 3-bit/channel
# PCE VCE colour. The gameplay/geometry is independent of this table.
C64_RGB = {
    0x0: (0, 0, 0), 0x1: (208, 208, 208), 0x2: (104, 55, 43),
    0x3: (112, 164, 178), 0x4: (111, 61, 134), 0x5: (88, 141, 67),
    0x6: (53, 40, 121), 0x7: (184, 199, 111), 0x8: (111, 79, 37),
    0x9: (67, 57, 0), 0xA: (154, 103, 89), 0xB: (68, 68, 68),
    0xC: (108, 108, 108), 0xD: (154, 210, 132), 0xE: (108, 94, 181),
    0xF: (149, 149, 149),
}


def c64_hires_to_pce4(char: bytes) -> bytes:
    if len(char) != 8:
        raise ValueError("C64 character must be exactly 8 bytes")
    # PCE/SNES-like 4bpp: rows of planes 0/1, then rows of planes 2/3.
    out = bytearray()
    for row in char:
        out += bytes((row, 0x00))  # foreground pixel value = 0001b
    out += bytes(16)               # planes 2 and 3 are both zero
    assert len(out) == 32
    return bytes(out)


def rgb_to_vce(rgb: tuple[int, int, int]) -> int:
    r, g, b = (round(c * 7 / 255) for c in rgb)
    return (g << 6) | (r << 3) | b  # VCE bits: GGG RRR BBB


def room00_patterns() -> bytes:
    out = bytearray()
    for lib_index in ROOM00_TILE_LIBRARY_INDEX:
        out += c64_hires_to_pce4(C64_CHARS[lib_index])
    assert len(out) == 8 * 32
    return bytes(out)


def main() -> None:
    patterns = room00_patterns()
    print(f"room00 patterns: {len(patterns)} bytes")
    for slot, (lib, colour) in enumerate(zip(ROOM00_TILE_LIBRARY_INDEX, ROOM00_C64_COLOUR)):
        vce = rgb_to_vce(C64_RGB[colour])
        print(f"slot {slot}: C64 library ${lib:02X}, colour ${colour:X} -> VCE ${vce:03X}")
    print("pattern bytes:")
    for slot in range(8):
        p = patterns[slot * 32:(slot + 1) * 32]
        print(f"{slot}: " + " ".join(f"{x:02x}" for x in p))


if __name__ == "__main__":
    main()
