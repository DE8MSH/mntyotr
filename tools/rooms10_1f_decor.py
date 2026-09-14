#!/usr/bin/env python3
"""Overlay exact original C64 decorations for Rooms $10-$1F.

Reads the base BATs emitted by rooms10_1f.py, replaces the corresponding cells
with decor characters from Decor.room_list, and emits one compact PCE pattern
payload per room. Only rooms that have original decor records receive a payload.
"""
from __future__ import annotations

import argparse
import struct
from pathlib import Path
from room_rle import CHR_GAME, SCREEN_W

ROOM_Y0 = 3
SCREEN_X0 = 2
CHR_DECOR = CHR_GAME + 9

PAL_BY_C64 = {
    0x00:0, 0x09:1, 0x02:2, 0x03:3, 0x0B:4, 0x0C:5, 0x0F:6, 0x01:7,
    0x07:8, 0x0D:9, 0x0A:10, 0x08:11, 0x05:12, 0x04:13, 0x06:14, 0x0E:15,
}

# Exact Decor.room_list entries for the new block.
ROOM_RECORDS = {
    0x10: [(0x22,0x0A,0x47),(0x23,0x10,0x45),(0x03,0x13,0x51),(0x04,0x04,0x51),(0x0A,0x04,0x51)],
    0x11: [(0x03,0x10,0x45),(0x05,0x10,0x45),(0x04,0x0D,0x45),(0x0C,0x12,0x45),(0x12,0x04,0x47),(0x0A,0x0A,0x48),(0x17,0x04,0x46),(0x21,0x09,0x53)],
    0x12: [(0x23,0x09,0x48),(0x15,0x08,0x48),(0x15,0x04,0x48),(0x04,0x06,0x4B),(0x03,0x09,0x27),(0x05,0x0A,0x4A),(0x1D,0x0E,0x47)],
    0x13: [(0x0E,0x11,0x49),(0x03,0x09,0x48),(0x1A,0x09,0x48)],
    0x1D: [(0x0B,0x0B,0x57),(0x11,0x04,0x5B),(0x0C,0x14,0x57),(0x12,0x11,0x58)],
    0x1E: [(0x07,0x10,0x5C),(0x1B,0x13,0x57),(0x0D,0x11,0x57)],
    0x1F: [(0x19,0x0D,0x5A),(0x0D,0x0B,0x57),(0x18,0x07,0x57),(0x0E,0x10,0x57)],
}

# Type id -> (width, height, C64 bitmap chars, C64 colour stream).
TYPE_DATA = {
    0x27: (5,2,"071f3f3f7c787870ffffffff00000000ffffffff00000000ffffffff00000000e0f8fcfc3e1e1e0e70707070707070fc000000000000000000000000000000000000000000000000e0e0e0e0e0e0e3f","0a"*10),
    0x45: (2,3,"0001010303030307008080c0c0c0c0e00707070f0f0f0f1fe0e0e0f0f0f0f0f81f1f3f3f3f00fffff8f8fcfcfc00ffff","080801010808"),
    0x46: (2,5,"00071c306060c1c300f0182c76faf3e3c7cf5f6e34180f01c38306060c38e080020301010101010140c0808080808080010101010101010180808080808080800101010101040f3f808080808020f0fc","0a0a0a0a010101010f0f"),
    0x47: (2,4,"0f06010101010101e0c0000000000000010101010101010100000000000000000508172f5f3fff004060f0f8fcfeff001f17170b05000000f0f0f0e0c0000000","010101010c0c0707"),
    0x48: (2,2,"7fb3ccccccccccccfecd333333333333ccccccccccccb37f333333333333cdfe","0f0f0f0f"),
    0x49: (2,1,"00000000ff7cecc0000e1931f131190e","0101"),
    0x4A: (2,1,"007098cccfcc987000000000ff3e3928","0101"),
    0x4B: (3,3,"0f181f181b191b18ff00ff75adddad75f018f818b8b8b8b81f1e1e1e1f16130fffdbdbdbffdbfffff8787878f868c8f0000f1b366dff80ff00ff6ddbb6ff00ff00f0c87ce6ff01ff","010101010101080808"),
    0x51: (3,3,"7ff1c4cececececeffc3183434343434fe8f237373737373cececececececece34343434343434347373737373737373cececececec4f17f343434343418c3ff7373737373238ffe","0f"*9),
    0x53: (4,5,"ff80bfa0a7aeadadff00ff00ff73ed2dff00ff00ff986b6bff01fd05e5f57575adaeafadadadadacad73ffedededed336b98ff9b6a796a9b75f5f575f5f5f575a7a0a0a0a0a0a0a0ff0000e098d59994ff000000945c5494e505050505050505a0a0a1a3a5a1a1a1000c12904c02120c0000649695f49494050545c545454545a1a1a1a0a0bf80ff00100f0000ff00ff0000ff0000ff00ff0505854505fd01ff","07"*20),
    0x57: (3,2,"00000000001f3f3100003e63c1ffff680000000080f8fcbc373337373f303f1f6b696b98ff00ffffbcbcbc8cfc0cfcf8","04"*6),
    0x58: (5,5,"0000000014080808000000070807000024181818ff181818000000e010e000000000000028101010141408080808080800000000070f0c0d18245a5a99ff00ff00000000e0f030b02828101010101010081c1c143e362b351d191b3b32347464e7dba5bda5db663cb898d8dc4c2c2e26103838287c6cd4ac2b352a352f3b3030ef60ff7ff9301010ff00ffffff3c2424f706fffe9f0c0808d4ac54acf4dc0c0c200000000100010710306060f060f0fc1818246618000000080c06060f060f3f04000000800080e0","07"*25),
    0x5A: (10,5,"0000000000000000000000000000000000000000000000000000000001061c300000003fff3060c0000000f0fe31180c000000000080e03000000000000000000102040810102040a0500000000000000000000000000000000000000000000000000103070e1c1c61c386860c181931800020204080009c060301313070f0e0180c8687c36160300000000080c1e1e1408080808000000000000000000000000000000000000000000080c0f0fefbf33c3f30373636363030ff00fededede0000ff007f677f600000ff003838383e0030ff006666006600f1f1323232323232000000000000000000000000000000000000000000010307c383037fffe0c0001f0606ffff7e3c18ff6666ffff000000ff6666ffff7e3c18ff6666ffff000000ff6666ffff7e3c18e70707ffff070300000000000080c0e000000000000000000e0c0c0800000000187e7ee7e77e7e181818180000000000187e7ee7e77e7e181818180000000000187e7ee7e77e7e181818180000000000187e7ee7e77e7e1870303010000000000000000000000000","0c0c0c080808080c0f0f0c0c0808080808080f0f0c0c0707070707070f0f0c0c0c0c0c0c0c0c0f0c0c0e0c0e0c0e0c0e0c0e"),
    0x5B: (5,4,"eae0504844424140a80200000000008000a00a00000000000000e06060606060000000000000000040404040402020204020100c0e07030100000000010181b9c0c0c0c0c0c0808000000000000000002020201010101010000000000000017f7bf3e7ce1e79f180000000000080c0e000000000000000001f1f000000000000fe800000000000030000000000077fff50307070f8ffffff000000000000f0fc","0c"*20),
    0x5C: (5,4,"000000000000000000000706060606060005500000000000154000000000000157070a122242820200000000000000000303030303030101000000008080819d0204083070e0c080020202020204040400000000000000000000000000010307decfe773789e8f0100000000000080fe04040408080808080000000000000f3f0a0c0e0e1fffffff0000000000e0feff7f010000000000c0f8f8000000000000","0c"*20),
}


def c64_char_to_pce_tile(char: bytes) -> bytes:
    assert len(char) == 8
    return b"".join(bytes((b, 0)) for b in char) + bytes(16)


def room_types(room: int) -> list[int]:
    out: list[int] = []
    for _, _, typ in ROOM_RECORDS[room]:
        if typ not in out:
            out.append(typ)
    return out


def build_room_patterns(room: int) -> tuple[bytes, dict[int, int]]:
    out = bytearray()
    first: dict[int, int] = {}
    next_char = CHR_DECOR
    for typ in room_types(room):
        w, h, bmp_hex, cols_hex = TYPE_DATA[typ]
        raw = bytes.fromhex(bmp_hex)
        assert len(raw) == w * h * 8, (room, typ, len(raw), w*h*8)
        assert len(bytes.fromhex(cols_hex)) == w * h
        first[typ] = next_char
        for i in range(w * h):
            out += c64_char_to_pce_tile(raw[i*8:(i+1)*8])
            next_char += 1
    assert next_char <= CHR_GAME + 80, (room, next_char)
    return bytes(out), first


def overlay_room(room: int, base: bytes) -> bytes:
    assert len(base) == SCREEN_W * 20 * 2
    words = list(struct.unpack("<" + "H" * (len(base)//2), base))
    _, first = build_room_patterns(room)
    for c64_x, c64_y, typ in ROOM_RECORDS[room]:
        w, h, _, cols_hex = TYPE_DATA[typ]
        cols = bytes.fromhex(cols_hex)
        char = first[typ]
        ci = 0
        local_x = c64_x - SCREEN_X0
        local_y = c64_y - ROOM_Y0
        for dy in range(h):
            for dx in range(w):
                x, y = local_x + dx, local_y + dy
                if not (0 <= x < SCREEN_W and 0 <= y < 20):
                    raise ValueError(f"R{room:02X} decor {typ:02X} outside room at {x},{y}")
                pal = PAL_BY_C64[cols[ci]]
                words[y*SCREEN_W+x] = (pal << 12) | char
                char += 1
                ci += 1
    return struct.pack("<" + "H" * len(words), *words)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out-dir', type=Path, required=True)
    args = ap.parse_args()
    for room in sorted(ROOM_RECORDS):
        prefix = f'room{room:02x}'
        bat_path = args.out_dir / f'{prefix}-screen-bat.dat'
        bat_path.write_bytes(overlay_room(room, bat_path.read_bytes()))
        patterns, _ = build_room_patterns(room)
        (args.out_dir / f'{prefix}-decor-patterns.dat').write_bytes(patterns)
        print(f'R{room:02X}: {len(ROOM_RECORDS[room])} decor records, {len(patterns)//32} chars')

if __name__ == '__main__':
    main()
