#!/usr/bin/env python3
import struct
from pathlib import Path
from room02 import ROOM02_RLE, make_screen_bat
from room_rle import decode_room, SCREEN_W
from room02_decor import (
    build_patterns, overlay_screen_bat, ROOM02_RECORDS, TYPE_DATA, TYPE_ORDER,
    CHR_DECOR, PAL_BY_C64,
)

ROOT = Path(__file__).resolve().parents[1]


def words(blob):
    return list(struct.unpack('<' + 'H'*(len(blob)//2), blob))


def main():
    base = make_screen_bat(decode_room(ROOM02_RLE))
    decorated = overlay_screen_bat(base)
    patterns, first = build_patterns()

    assert ROOM02_RECORDS == (
        (0x04,0x0c,0x19), (0x22,0x0a,0x08), (0x03,0x12,0x05),
        (0x07,0x12,0x06), (0x20,0x11,0x42),
    )
    assert TYPE_ORDER == (0x19,0x08,0x05,0x06,0x42)
    assert len(patterns) == 57*32
    assert len(TYPE_DATA[0x19][2]) == 27*8
    assert len(TYPE_DATA[0x08][2]) == 8*8
    assert TYPE_DATA[0x05][2] == TYPE_DATA[0x06][2]

    bat = words(decorated)
    for c64_x, c64_y, type_id in ROOM02_RECORDS:
        w, h, _raw, colours = TYPE_DATA[type_id]
        char = first[type_id]
        for i, colour in enumerate(colours):
            dy, dx = divmod(i, w)
            x = c64_x - 2 + dx
            y = c64_y - 3 + dy
            word = bat[y*SCREEN_W+x]
            assert (word & 0x0fff) == char + i
            assert (word >> 12) == PAL_BY_C64[colour]

    main_asm = (ROOT/'src/main.asm').read_text()
    tail = (ROOT/'src/room02_assets_tail.asm').read_text()
    loader = (ROOT/'src/room_loader.asm').read_text()
    decor_loader = (ROOT/'src/room02_decor_loader.asm').read_text()
    assert 'include "room02_decor_loader.asm"' in main_asm
    assert 'room02_decor_patterns:' in tail
    assert 'incbin "room02-decor-patterns.dat"' in tail
    assert 'call    room02_upload_decor' in loader
    assert 'BANK(room02_decor_patterns)' in decor_loader
    assert '57 chars * 32 bytes = 1824 bytes' in decor_loader

    print('OK: exact Room 02 five decor records, 57 chars, palettes and bank-safe upload')


if __name__ == '__main__':
    main()
