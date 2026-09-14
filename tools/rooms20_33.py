#!/usr/bin/env python3
"""Generate exact C64 Rooms $20-$33 from original Room.Data.

Source: Dave-Agent/monty-on-the-run refactored room_data.asm + tiles.asm.
Each output contains the C64 RLE decode, 36x20 BAT window, nine PCE patterns
(blank + eight room-custom C64 chars), and collision properties.

Room $30 is a completion-only special room whose original stream expands to
624 cells. The original renderer never reaches it through normal world-grid
navigation; for the PCE fixed 20-row cache we append the final 16 blank cells.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import ROOM_CELLS, CHR_GAME
from rooms10_1f import PAL_BY_C64, classify, c64_char_to_pce_tile, TILES as BASE_TILES

RLE_HEX = {
0x20: """f0 60 13 02 03 02 31 f0 50 02 00 22 41 f0 30 12 40 21 10 f0 90 31 10 f0 80 21 30 f0 90 11 30 f0 a0 01 20 01 f0 a0 11 10 01 f0 90 11 20 01 f0 70 21 30 01 f0 60 11 50 01 f0 e0 01 f0 e0 01 b0 e1 30 01 40 81 e0 21 10 41 f0 50 21 31 f0 80 21 01 f0 c0 11 01 f0 c0 11 01 f0 80 51 ff ff""",
0x21: """02 40 05 90 06 40 72 00 02 40 05 90 06 30 03 72 00 50 05 90 06 10 04 03 10 52 10 50 05 90 06 40 62 10 50 05 90 06 60 52 04 50 05 90 06 70 22 04 03 00 32 03 04 13 80 06 70 32 00 03 12 00 03 04 b0 06 80 32 00 02 f0 06 80 32 00 02 50 13 24 40 06 70 32 10 12 e0 06 50 03 04 42 00 12 e0 06 20 03 14 23 42 61 40 13 04 23 20 03 91 41 e0 04 13 10 61 61 b0 33 30 41 51 b0 03 14 70 21 61 03 80 03 04 03 90 11 71 04 03 60 04 03 90 21 71 03 04 03 30 04 03 14 03 70 31 f1 f1 ff ff""",
0x22: """61 50 06 80 81 40 31 30 06 80 21 50 10 02 03 20 11 30 06 90 21 40 10 01 20 21 30 06 80 21 40 02 00 31 02 11 40 06 90 41 03 02 01 10 11 03 21 10 02 13 02 06 70 31 02 03 21 20 11 03 21 40 06 70 11 03 51 10 03 10 31 40 06 80 11 03 02 11 10 30 41 40 06 80 31 13 02 00 20 21 00 41 10 06 90 21 02 20 20 21 40 31 b0 11 20 00 41 70 11 50 13 02 03 12 11 10 61 90 04 00 22 03 02 13 31 10 81 70 04 40 61 10 21 20 05 90 04 60 31 20 21 20 05 90 04 70 11 30 21 20 05 20 03 02 13 02 10 04 40 41 30 11 30 05 13 02 03 50 04 20 51 40 01 40 05 90 04 30 51 30 01 40 05 90 04 30 81 00 ff ff""",
0x23: """f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 b0 02 50 03 b0 c0 11 13 02 03 02 03 61 30 30 02 03 10 e1 10 41 10 40 41 10 61 40 31 00 03 10 30 41 30 04 20 21 30 41 02 10 30 21 50 04 30 11 20 31 40 30 11 13 02 03 02 03 00 04 40 01 40 31 20 20 21 02 03 10 13 02 04 40 01 30 31 30 00 31 70 04 a0 41 03 00 00 21 80 04 70 02 00 51 02 00 61 50 04 80 71 00 ff ff""",
0x24: """f5 65 04 70 f5 75 04 60 f5 85 04 50 f3 93 50 a3 06 07 c3 50 a3 08 05 c3 50 a3 15 c3 50 a3 15 c3 50 f1 f1 f0 f0 f0 f0 f0 f0 f0 f0 f1 d1 10 f0 f0 f0 f0 f0 f0 f0 f0 81 42 f1 10 f0 f0 ff ff ff ff""",
0x25: """a0 04 f5 35 90 04 f5 45 80 04 f5 55 80 f3 63 80 43 06 07 93 06 07 33 80 43 08 05 93 08 05 33 80 43 15 93 15 33 80 43 15 93 15 33 f1 f1 f0 f0 f0 f0 f0 f0 f0 f0 a1 32 71 12 61 f0 f0 f0 f0 f0 f0 f0 f0 f1 f1 f0 f0 ff ff""",
0x26: """07 f0 e0 17 f0 d0 17 f0 d0 17 c0 05 f0 27 b0 04 f0 27 b0 04 e0 03 37 a0 04 e0 03 47 90 04 c0 23 e0 04 c0 23 e0 04 a0 43 e0 04 a0 43 e0 04 80 63 e0 04 80 63 e0 04 60 83 e0 04 60 83 f2 08 30 a1 e2 08 90 51 d2 08 a0 51 c2 08 b0 51 f6 96 51 ff ff""",
0x27: """90 28 e0 21 00 80 28 f0 31 80 28 f0 31 70 28 50 48 50 31 70 28 70 02 70 31 40 48 80 02 80 21 f0 20 02 b0 48 d0 02 b0 f0 20 02 b0 f0 20 02 b0 f0 20 07 53 04 40 f0 90 02 40 f0 90 02 40 70 05 33 04 b0 02 40 70 02 30 02 b0 02 40 91 26 02 b0 51 91 20 02 a0 61 91 20 02 90 71 a1 10 02 80 81 a1 10 02 70 91 ff ff""",
0x28: """a1 10 03 70 91 c0 03 70 91 c0 03 70 91 c0 03 50 b1 c0 03 40 61 10 31 c0 03 30 51 40 21 60 05 44 06 20 41 90 60 03 70 31 b0 60 03 f0 70 60 03 f0 70 40 42 f0 50 20 32 f0 80 42 f0 a0 f0 90 52 30 32 20 92 10 12 60 f7 f7 f8 f8 f8 f8 f1 f1 f1 f1 ff ff""",
0x29: """f2 61 08 71 72 50 12 61 08 71 52 70 12 61 08 71 52 60 22 61 08 71 52 10 06 35 12 71 08 71 42 20 04 30 12 71 08 71 70 04 30 12 71 08 71 70 04 20 12 81 08 71 70 04 20 12 81 08 71 70 04 20 12 81 08 71 70 04 20 12 f1 11 70 04 20 12 f1 11 60 43 12 f1 11 33 70 12 f1 11 a0 22 f1 11 a7 12 f1 21 a1 12 f1 21 a1 12 f1 21 b2 f1 31 f1 f1 ff ff""",
0x2A: """f1 f1 00 22 10 02 20 b1 90 00 22 10 02 50 51 c0 00 22 10 02 60 31 d0 00 12 20 05 63 31 33 06 80 00 12 a0 31 30 02 80 00 12 b0 11 40 02 80 10 02 b0 11 40 02 80 10 02 f0 20 02 80 13 02 40 34 90 02 80 10 02 20 24 c0 02 80 d0 51 10 02 10 11 40 60 01 40 51 67 01 00 34 60 01 47 51 67 01 40 40 31 27 71 47 21 30 f1 f1 f1 f1 f1 f1 f1 f1 f1 f1 ff ff""",
0x2B: """b8 01 f2 22 c8 01 02 f0 00 d8 01 02 f0 e8 01 02 80 24 07 10 f8 01 02 83 10 05 10 f8 08 01 02 90 05 10 f8 18 01 02 80 05 10 f8 28 01 02 70 05 10 f8 38 01 02 60 05 10 f8 48 01 02 50 06 14 f8 58 01 02 70 f8 68 01 02 60 f8 78 01 02 50 f8 88 01 02 40 f8 98 01 12 20 f8 a8 01 32 f8 b8 01 22 f8 c8 01 12 f8 d8 01 02 f8 f8 ff ff""",
0x2C: """10 f1 d1 10 11 70 13 f0 10 10 01 80 13 f0 10 10 01 80 13 f0 10 10 01 72 05 13 06 e2 10 10 01 70 33 f0 00 10 01 70 33 b0 34 00 10 01 70 33 30 34 60 14 10 01 70 33 f0 00 10 01 70 33 f0 00 10 01 70 33 00 64 80 a0 33 30 64 50 a0 33 f0 00 a0 33 f0 00 a0 33 f0 00 f1 f1 51 57 f1 31 41 77 f1 21 41 77 f1 21 51 57 f1 31 ff ff""",
0x2D: """f0 e0 07 f0 e0 07 90 04 05 f0 20 07 b0 04 05 f0 00 07 d0 04 05 e0 07 d0 78 00 06 00 58 07 f0 60 06 60 07 f0 60 06 60 07 f0 60 06 60 07 00 04 05 f0 30 06 60 07 20 04 05 f0 10 06 60 07 40 04 05 f0 70 07 60 04 05 a0 06 10 87 80 04 05 80 06 a0 80 31 60 06 a0 70 02 f1 61 80 02 f1 51 90 02 f1 41 a0 02 f1 31 b3 02 f1 21 ff ff""",
0x2E: """f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 71 f0 70 60 a1 d0 f0 00 d1 00 f0 c0 01 10 34 05 f0 70 01 10 30 03 c0 82 10 01 10 30 03 10 32 10 52 90 01 10 30 03 f0 20 22 10 01 10 30 03 f0 70 01 10 12 10 32 f0 22 10 11 00 f0 c0 11 00 e0 22 20 22 40 11 00 90 52 c0 21 ff ff""",
0x2F: """f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 60 61 d0 31 60 f1 51 20 60 31 50 03 d0 70 01 70 03 d0 70 01 70 03 b0 04 06 70 51 20 03 40 66 05 00 70 01 70 03 d0 70 01 70 03 d0 70 01 70 03 d0 70 21 50 03 90 32 70 21 50 03 50 42 20 70 41 30 03 d0 70 f1 71 ff ff""",
0x30: """f0 f0 f0 60 08 70 f0 60 07 70 f0 60 07 70 f0 60 07 50 05 06 f0 60 07 40 05 16 f0 60 07 30 05 26 f0 60 07 20 05 36 f0 60 07 10 05 46 f0 60 07 20 42 f0 60 07 20 42 f0 60 07 20 42 f0 60 07 20 42 f0 20 c1 f0 30 03 00 03 00 03 00 03 00 03 00 03 00 f0 30 03 00 03 00 03 00 03 00 03 00 03 00 f4 f4 f4 f4 f4 f4 f4 ff ff""",
0x31: """f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 11 12 f1 31 12 51 f0 f0 f0 f0 f0 f0 f0 f0 91 42 f1 01 f0 f0 f0 f0 f0 f0 f0 f0 b1 12 b1 12 31 f0 f0 ff ff ff ff ff ff ff""",
0x32: """f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 c1 42 d1 f0 f0 f0 f0 f0 f0 f0 f0 41 12 e1 12 71 f0 f0 f0 f0 f0 f0 f0 f0 f1 41 32 61 f0 f0 ff ff""",
0x33: """f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 f0 10 f1 d1 f0 f0 f0 f0 f0 f0 f0 f0 10 81 32 71 12 61 f0 f0 f0 f0 f0 f0 f0 f0 f1 f1 f0 f0 ff ff ff""",
}

ROOM_DEFS = {
0x20: ((0x05,0x33,0x2a,0,0,0,0,0),(0x08,0x0d,0x05,0,0,0,0,0)),
0x21: ((0x1e,0x05,0x2a,0x33,0x60,0x6a,0,0),(0x09,0x08,0x05,0x0d,0x03,0x05,0,0)),
0x22: ((0x05,0x2a,0x33,0x6a,0x60,0x64,0,0),(0x08,0x0d,0x05,0x05,0x07,0x03,0,0)),
0x23: ((0x05,0x2a,0x33,0x64,0,0,0,0),(0x08,0x0d,0x05,0x03,0,0,0,0)),
0x24: ((0x5b,0x53,0x01,0x57,0x4e,0x58,0x59,0x5a),(0x0c,0x02,0x02,0x07,0x07,0x07,0x07,0x07)),
0x25: ((0x5b,0x53,0x01,0x4b,0x4e,0x58,0x59,0x5a),(0x0c,0x05,0x02,0x07,0x07,0x07,0x07,0x07)),
0x26: ((0x03,0x03,0x08,0x49,0x4a,0x55,0x1b,0x6e),(0x03,0x08,0x0c,0x01,0x01,0x0e,0x07,0x08)),
0x27: ((0x03,0x6b,0x6c,0x71,0x72,0x39,0x73,0x3b),(0x0c,0x03,0x03,0x03,0x03,0x05,0x03,0x08)),
0x28: ((0x03,0x3b,0x6b,0x6c,0x72,0x74,0x53,0x77),(0x0c,0x08,0x03,0x03,0x03,0x03,0x0e,0x0e)),
0x29: ((0x77,0x03,0x3b,0x6b,0x6c,0x72,0x55,0x5c),(0x0e,0x0c,0x08,0x03,0x03,0x03,0x0e,0x0e)),
0x2A: ((0x03,0x6b,0x6c,0x3b,0x73,0x71,0x4f,0),(0x0c,0x07,0x07,0x04,0x07,0x07,0x08,0)),
0x2B: ((0x29,0x03,0x3a,0x6c,0x6b,0x73,0x71,0x77),(0x0e,0x0c,0x05,0x07,0x07,0x07,0x07,0x0e)),
0x2C: ((0x04,0x6c,0x6b,0x35,0x71,0x72,0x4f,0),(0x04,0x03,0x03,0x05,0x03,0x03,0x06,0)),
0x2D: ((0x03,0x78,0x55,0x5d,0x5e,0x5f,0x24,0x04),(0x0c,0x0c,0x0e,0x0a,0x0a,0x06,0x07,0x08)),
0x2E: ((0x03,0x3a,0x6b,0x6c,0x71,0,0,0),(0x03,0x08,0x07,0x07,0x07,0,0,0)),
0x2F: ((0x03,0x3c,0x6b,0x72,0x74,0x6c,0,0),(0x03,0x04,0x07,0x07,0x07,0x07,0,0)),
0x30: ((0x4d,0x4e,0x4c,0x4e,0x4b,0x4e,0x49,0x4a),(0x0c,0x0a,0x08,0x0e,0x0d,0x0d,0x01,0x01)),
0x31: ((0x5b,0x54,0,0,0,0,0,0),(0x0c,0x0a,0,0,0,0,0,0)),
0x32: ((0x5b,0x55,0,0,0,0,0,0),(0x0c,0x04,0,0,0,0,0,0)),
0x33: ((0x5b,0x56,0,0,0,0,0,0),(0x0c,0x07,0,0,0,0,0,0)),
}

EXTRA_TILES = {
0x04:"bd 7e e7 db cb e7 7e bd",0x08:"99 33 66 cc 99 33 66 cc",0x1b:"ef ef ef ef ef ef ef 00",0x24:"11 ee ee ee 11 ee ee ee",
0x29:"c0 c0 f0 f0 fc fc ff ff",0x2a:"e0 f8 bc ce 76 7b 3d 0f",0x33:"07 1d 33 2f 6c 7c 78 40",0x35:"49 92 24 49 92 24 49 92",
0x3a:"ff 55 aa ff 00 00 00 00",0x3c:"e7 cf 9f 00 00 00 00 00",0x49:"18 18 18 18 18 18 18 18",0x4a:"18 3c 3c 18 18 18 18 18",
0x4b:"01 03 07 0f 1f 3f 7f ff",0x4c:"66 66 3c 18 18 3c 3c 3c",0x4d:"ff c0 b0 8c 83 ff 7e 3c",0x4e:"ff ff ff ff ff ff ff ff",
0x55:"18 7e ff ff ff ff ff ff",0x56:"22 66 ee ff ff ff 00 00",0x57:"80 c0 e0 f0 f8 fc fe ff",0x58:"00 0f 3f 7f 7f ff ff ff",
0x59:"00 f0 fc fe fe ff ff ff",0x5a:"ff ff ff 8f 87 e7 ff ff",0x5b:"ff 33 cc 33 aa 55 aa 00",0x5c:"39 39 11 93 df df 93 13",
0x5d:"e0 38 0e 03 00 00 00 00",0x5e:"00 00 00 80 e0 38 0e 03",0x5f:"28 1c 38 70 28 1c 38 70",0x60:"38 20 70 20 70 10 38 08",
0x64:"60 60 60 08 d8 f0 00 60",0x6a:"08 08 18 10 30 20 30 10",0x6e:"11 56 14 f8 10 60 40 80",0x77:"ff ff ff ff ff ff ff ff",
0x78:"91 55 31 1f 09 05 03 01",
}
TILES = dict(BASE_TILES)
TILES.update(EXTRA_TILES)
TILE_BITMAPS = {k: bytes.fromhex(v) for k, v in TILES.items()}


def decode_exact(room: int) -> list[int]:
    stream = bytes.fromhex(RLE_HEX[room])
    out: list[int] = []
    i = 0
    while i < len(stream):
        if i + 1 < len(stream) and stream[i] == 0xff and stream[i+1] == 0xff:
            break
        value = stream[i]
        i += 1
        out.extend([value & 0x0f] * ((value >> 4) + 1))
    if room == 0x30 and len(out) == 624:
        out.extend([0] * 16)
    assert len(out) == ROOM_CELLS, (room, len(out))
    return out


def room_data(room: int):
    ids, cols = ROOM_DEFS[room]
    cells = decode_exact(room)
    props = tuple(classify(t) for t in ids)
    patterns = bytearray(32)
    for t in ids:
        patterns += c64_char_to_pce_tile(TILE_BITMAPS[t])
    bat = bytearray()
    for y in range(20):
        row = cells[y*32:(y+1)*32]
        expanded = [row[0], row[0], *row, row[-1], row[-1]]
        for code in expanded:
            pal = 0 if code == 0 or code >= 9 else PAL_BY_C64[cols[code-1] & 15]
            bat += struct.pack('<H', (pal << 12) | (CHR_GAME + code))
    return bytes(cells), bytes(bat), bytes(patterns), props


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out-dir', type=Path, required=True)
    a = ap.parse_args()
    a.out_dir.mkdir(parents=True, exist_ok=True)
    for room in range(0x20, 0x34):
        cells, bat, patterns, props = room_data(room)
        p = f'room{room:02x}'
        (a.out_dir / f'{p}-map.dat').write_bytes(cells)
        (a.out_dir / f'{p}-screen-bat.dat').write_bytes(bat)
        (a.out_dir / f'{p}-patterns.dat').write_bytes(patterns)
        (a.out_dir / f'{p}-properties.dat').write_bytes(bytes(props))
    print('rooms 20-33: 20 exact C64 rooms generated (R30 padded to fixed PCE cache)')

if __name__ == '__main__':
    main()
