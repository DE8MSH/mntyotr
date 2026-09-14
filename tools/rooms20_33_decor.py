#!/usr/bin/env python3
"""Overlay exact original C64 decorations for hexadecimal Rooms $20-$33.

Source truth is Decor.room_list / Decor.type from the original game.  The base
room BATs come from rooms20_33.py; this pass overlays every static decoration at
its exact C64 character coordinate and emits one compact PCE pattern payload per
room that actually contains decor records.
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

# Exact Decor.room_list records: (C64 x, C64 y, decor type).
ROOM_RECORDS = {
    0x20: [(0x06,0x05,0x60),(0x03,0x11,0x0E),(0x06,0x10,0x0E),(0x1F,0x14,0x0E),(0x15,0x0E,0x0E),(0x1C,0x0A,0x0E)],
    0x21: [(0x04,0x07,0x0E),(0x07,0x0D,0x0E),(0x10,0x14,0x0E),(0x1A,0x14,0x0E),(0x23,0x0C,0x0E)],
    0x22: [(0x20,0x14,0x0E),(0x0B,0x0E,0x0E),(0x10,0x0B,0x0E),(0x03,0x0D,0x0E),(0x1F,0x05,0x0E)],
    0x23: [(0x03,0x04,0x60),(0x0F,0x05,0x5F),(0x15,0x03,0x60),(0x03,0x14,0x0E),(0x0D,0x0C,0x0E),(0x1A,0x0B,0x0E)],
    0x24: [(0x16,0x07,0x03),(0x06,0x07,0x03),(0x1E,0x08,0x3D),(0x21,0x09,0x3F),(0x24,0x08,0x05)],
    0x25: [(0x02,0x05,0x37),(0x03,0x08,0x39),(0x06,0x08,0x3B),(0x17,0x07,0x03)],
    0x26: [(0x03,0x0E,0x33),(0x08,0x0E,0x34),(0x21,0x08,0x2C),(0x21,0x08,0x2D),(0x1F,0x0A,0x2C),(0x1F,0x0A,0x2D),(0x1D,0x0C,0x2C),(0x1D,0x0C,0x2D),(0x1B,0x0E,0x2C),(0x1B,0x0E,0x2D),(0x23,0x06,0x2D),(0x24,0x06,0x2C),(0x1E,0x0F,0x2F),(0x23,0x0F,0x2F)],
    0x27: [(0x21,0x0E,0x34),(0x03,0x0E,0x32),(0x16,0x03,0x41),(0x22,0x05,0x2E),(0x23,0x14,0x2E),(0x1F,0x14,0x2E),(0x03,0x14,0x2E),(0x07,0x14,0x2E),(0x0B,0x14,0x2E)],
    0x28: [(0x24,0x0E,0x2C),(0x22,0x0E,0x2C),(0x21,0x0E,0x2D),(0x0F,0x0D,0x32)],
    0x29: [(0x19,0x0D,0x31),(0x14,0x12,0x5D),(0x17,0x12,0x5D),(0x1B,0x12,0x5E),(0x1F,0x12,0x5E),(0x22,0x12,0x5D),(0x02,0x0E,0x2C),(0x04,0x0E,0x2C),(0x06,0x0E,0x2C)],
    0x2B: [(0x03,0x12,0x5D),(0x08,0x12,0x5D),(0x0B,0x12,0x5E),(0x0F,0x12,0x5D),(0x13,0x12,0x5E),(0x16,0x12,0x5E)],
    0x2D: [(0x1D,0x04,0x34),(0x14,0x04,0x34),(0x1E,0x0B,0x33),(0x12,0x14,0x2E),(0x16,0x14,0x2E),(0x1A,0x14,0x2E),(0x1E,0x14,0x2E),(0x22,0x14,0x2E),(0x12,0x0E,0x33)],
    0x2E: [(0x18,0x08,0x34),(0x1C,0x09,0x35),(0x1E,0x08,0x33),(0x22,0x09,0x35)],
    0x30: [(0x20,0x0C,0x03)],
    0x31: [(0x08,0x05,0x37),(0x09,0x08,0x39),(0x0B,0x05,0x38),(0x0C,0x08,0x39),(0x0E,0x05,0x37),(0x0F,0x08,0x39),(0x12,0x08,0x3B),(0x18,0x09,0x3C),(0x19,0x05,0x38),(0x1A,0x08,0x39),(0x1D,0x05,0x37),(0x1E,0x08,0x39),(0x21,0x04,0x4D),(0x22,0x07,0x4F),(0x21,0x0A,0x50),(0x02,0x05,0x37),(0x03,0x08,0x39)],
    0x32: [(0x08,0x04,0x37),(0x09,0x07,0x39),(0x03,0x08,0x3B),(0x08,0x09,0x3C),(0x0A,0x08,0x3B),(0x15,0x08,0x3A),(0x1A,0x05,0x38),(0x1B,0x08,0x39),(0x1E,0x04,0x37),(0x1F,0x07,0x39),(0x21,0x04,0x38),(0x22,0x07,0x39),(0x1E,0x08,0x3B),(0x23,0x09,0x3C)],
    0x33: [(0x24,0x09,0x2C),(0x22,0x09,0x2C),(0x20,0x09,0x2C),(0x1E,0x09,0x2C),(0x1D,0x08,0x39),(0x1C,0x05,0x37),(0x1B,0x09,0x2C),(0x19,0x09,0x2C),(0x18,0x09,0x2D),(0x13,0x08,0x3B),(0x10,0x05,0x38),(0x11,0x08,0x39),(0x11,0x09,0x2C),(0x0F,0x09,0x2C),(0x0D,0x09,0x2C),(0x0B,0x09,0x2C),(0x0A,0x09,0x2C),(0x09,0x09,0x2D),(0x06,0x08,0x3A)],
}

# Type id -> (width, height, C64 bitmap chars, C64 colour stream).
TYPE_DATA = {
    0x03:(3,3,"7fffffe0eee8e8e0ffffff181b1a1a18fec1fd0585050507e0e0e0ffffe0eee8181818ffff181b1a070707ffff078707e8a0a0a0a0bf837f1a18181818ffffff0707070707fffffe","0f"*9),
    0x05:(1,3,"0000002a5d3e360899d36e10d36e0c08ffdfdf6e6e7e3c3c","070d0a"),
    0x0E:(2,2,"0f3f7f63e7d77873f03c9ebff9f93b9e17070707070f0f07c8e8e0e0e0c0c080","02020f0f"),
    0x2C:(2,2,"000000ff33333333000000ff333333333333333333ffc0c03333333333ffc0c0","0b"*4),
    0x2D:(1,2,"0000003f3333333333333333333f3030","0b"*2),
    0x2E:(2,2,"165916e850a02058519569170905050258a020d0285611fe0205050b156d917f","0c"*4),
    0x2F:(2,3,"fffff5eaf5eaf5eafeff57af57af57aff5eaffffffffffff57affffffff9fffffffffffffffffffffffffffffffffffe","07"*6),
    0x31:(5,5,"fffffffffffffffffffffffffffffffe39393993c7efef00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7c7c7c7c7c7c7c7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc7c7c7c7c7c7c7c7fffffffffffffffffffffffffffffffffffffff7e3e3e1e1ffffffffffffffffc7c7c7c7c7c7c7c7ffffffffffffffffffffffdf8f8f0f0ff0f0f8fcffffffff7f3f0f0100c0f0ffc7c7ff8300000001fcf8e00001071fff1f1f3f7fffffffff","0e"*25),
    0x32:(4,4,"0000070f0e0e0e0e000fff0007172b5500f0ff00e0e8d4aa0000c0f0707070700e0e0e0e0e0e0e0e2af4f8f8d42a552b562f1f172b15eaf470707070707070700e0e0f0700000000170700ff0f000303f8e000fff000c0c07070f0e0000000000000000000000000030303030300071fc0c0c0c0c000e0f80000000000000000","02"*16),
    0x33:(4,4,"0000031e756ad5ff077fdebd7af5faffe07ebb5dae57afff0000c078ae56abffaa00000000000000aa00010101010101aa00808080808080aa000000000000000000000f03030303010100ff80010101808000ff01808080000000f0c0c0c0c0030303030303030301010101000b17178080808000f0f8f8c0c0c0c0c0c0c0c0","08080808010101010101010101020201"),
    0x34:(4,4,"0000031e756ad5ff077fdebd7af5faffe07ebb5dae57afff0000c078ae56abffaa00000000000000aa00010101010101aa00808080808080aa000000000000000000000f03030303010100ff80010101808000ff01808080000000f0c0c0c0c0030303030303030301010101000b17178080808000f0f8f8c0c0c0c0c0c0c0c0","0e0e0e0e010101010101010101030301"),
    0x35:(1,3,"0000000000010303030303030302007fe7c3c3c3c3c3c3c3","010101"),
    0x37:(3,3,"000d04136e2912763692bc29452aea8140f09438b29665c9440dd9d94b32e4927708eaf0672d4af7245cd0d94b32e4b22e68474b1a000000f6128df964cafb7f9664c8245cd08800","05"*9),
    0x38:(3,3,"000d04136e2912763692bc29452aea8140f09438b29665c9440dd9d94b32e4927708eaf0672d4af7245cd0d94b32e4b22e68474b1a000000f6128df964cafb7f9664c8245cd08800","0d"*9),
    0x39:(1,3,"3d791bdbd99db5b53d791bdbd99db5b53d791bdbd99db5b5","09"*3),
    0x3A:(3,3,"7fffc7dac6dedeffffff39d611d5d6fffeffb7af9fafb7ffc0ffc0ffff7f000000ff00ffd7833838dbef07efdffe000000000000000000003838383838385cbe0000000000000000","07"*9),
    0x3B:(5,3,"3f405f5f401fcfe0ff00ffff00ffff00ff00ffff00ffff00ff00ffff00ffff00fc02fafa02f8f307efefe0ab7fc7bb38ffff0033ffffff00ffff0033ffffff00ffff0033ffffff00f7f70735fee3dd1c383838303730383800000000ff00000000000000ff00000000000000ff0000001c1c1c0cec0c1c1c","08"*15),
    0x3C:(2,2,"007f505f505f582f00fe0afa0afa1af4282f1417140b0a0f14f428e828d050f0","07"*4),
    0x3D:(2,3,"0000000005ab63f10000000aa5cfce85a153566d2562260015694a523c301000ffaa554a252a1f10ffab52aa54a4f808","080805050a0a"),
    0x3F:(2,2,"92b2a6d8702127807323c69c898dde01ffdfef6f77373f10fffffffefefcfc08","0d0d0909"),
    0x41:(3,3,"000000041c2c1c0a0000a0d8d079212000000040e090e000000c1d3e040d0206a658a02f1ab06080006070d8f8a000003d792810000000007e7ebcbcbc5858580000000000000000","0708030a0504080200"),
    0x4D:(3,3,"00030f1c383070607eff8100000047cf00c0f0381c0c8ec661e3c7c1c1c1c161cfcccccccccccccfc6c7c3c3c3c3c7c6637330381c0f0300efe700000081ff7ec68e0c1c38f0c000","0a"*9),
    0x4F:(1,3,"747474747474747474747474747474747474747474747474","01"*3),
    0x50:(2,1,"0000000000000001747474007474fafb","0f"*2),
    0x5D:(3,5,"ffffffffefefe7eb7f7f7f7e3cbb84cfffffdfbfbf7ef8f6e1e5f3fbfcffbfbfe7e3f0f9fc78a1c3c5973fffffffffff1faf57a6d6ece4f18f9f3f0473ffffffffcf1713c5f0fafff9fcfcfcfefefefeffffff7f7f7e7c79fffffff00d53a70fff1fa7d3cae4fcfc3b033f3f7fffffffffffffffffffffff","0e"*15),
    0x5E:(3,5,"fffffbfdfd7e1f6ffefefe7e3cdd21f3fffffffff7f7e7d7a3e9fcffffffffffe7c70f9f3f1e85c387a7cfdf3ffffdfdfff3e8c8a30f5ffff1f9fc20cefffffff8f5ea656b37278fffffff0fb0cae5f0fffffffefe7e3e9e9f3f3f3f7f7f7f7fffffffffffffffffdcc0fcfcfefffffffff8e5cb53273f3f","0e"*15),
    0x5F:(4,4,"00000000000006070101010100031f7f8080808000c0f8fe00000000000060e0020101030307f7f7ffc79ff7f7f7f3ffff8fe7bfbfbf9fff408080c0c0e0efef0703030101020706ffffdfcfe0ff7f1ffffff7e70ffffef8e0c0c0808040e06000000000000000000300010101010000c0008080808000000000000000000000","07"*16),
    0x60:(10,3,"0000000000000000000000000000000000000000000000000000000000000000000001061b1b6f6d000070b8ecfb7f9f00061b1b6fbffffe00f09090ece6f9be0000000040c0407000000000000000000000000000000000000000000001071f0000000106e6be9b0106679befffffffbdf7ffffffffffffe7fffffffdfdbdbffbfffffdfeffdf7fffffffffffffffff9090ece4e6d56a6e00000000008040b0071a5b6f7f1f0000fb6f9fefffff1c00effffeffffff1f00c739feffffff0000ffffffffffff0000ffefbbffffff7b1fbfffffffffffc100ffffffffffbff000bfeffbffffff1a079ce7f9f9f9e7a4f8","0f"*30),
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
        cols = bytes.fromhex(cols_hex)
        assert len(raw) == w*h*8, (room, typ, len(raw), w*h*8)
        assert len(cols) == w*h, (room, typ, len(cols), w*h)
        first[typ] = next_char
        for i in range(w*h):
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
