#!/usr/bin/env python3
import struct
from pathlib import Path
from room_rle import decode_room, ROOM_CELLS, SCREEN_W, CHR_GAME
from room03 import (
    ROOM03_RLE, ROOM03_TILE_IDS, ROOM03_COLOURS, ROOM03_PROPERTIES,
    ROOM03_TILE_BITMAPS, PAL_BY_C64, build_patterns, make_screen_bat,
)

ROOT = Path(__file__).resolve().parents[1]


def words(blob):
    return list(struct.unpack('<' + 'H'*(len(blob)//2), blob))


def main():
    cells = decode_room(ROOM03_RLE)
    assert len(cells) == ROOM_CELLS == 640
    assert ROOM03_TILE_IDS == (0x01,0x2f,0x00,0x65,0x5f,0x44,0x11,0x55)
    assert ROOM03_COLOURS == (0x07,0x03,0x0b,0x05,0x03,0x04,0x06,0x0e)
    assert ROOM03_PROPERTIES == (1,2,1,3,3,2,1,4)
    assert ROOM03_TILE_BITMAPS[1] == bytes.fromhex('ff 03 03 03 ff 00 00 00')
    assert ROOM03_TILE_BITMAPS[3] == bytes.fromhex('6c 44 d4 aa fe 00 6c 6c')
    assert ROOM03_TILE_BITMAPS[4] == bytes.fromhex('28 1c 38 70 28 1c 38 70')
    assert ROOM03_TILE_BITMAPS[5] == bytes.fromhex('1e 72 c6 9e ba e2 8e ff')

    patterns = build_patterns()
    assert len(patterns) == 9*32
    assert patterns[:32] == bytes(32)

    bat = words(make_screen_bat(cells))
    assert len(bat) == SCREEN_W*20
    for y in range(20):
        row = bat[y*SCREEN_W:(y+1)*SCREEN_W]
        assert row[0] == row[1] == row[2]
        assert row[-1] == row[-2] == row[-3]

    for code in sorted(set(cells) - {0}):
        if code >= 9:
            continue
        expected_pal = PAL_BY_C64[ROOM03_COLOURS[code-1] & 0x0f]
        samples = [w for w in bat if (w & 0x0fff) == CHR_GAME + code]
        assert samples
        assert all((w >> 12) == expected_pal for w in samples)

    main_asm = (ROOT/'src/main.asm').read_text()
    tail = (ROOT/'src/room03_assets_tail.asm').read_text()
    assert 'include "room03_assets_tail.asm"' in main_asm
    assert main_asm.index('include "room03_assets_tail.asm"') > main_asm.index('include "monty_sprite.asm"')
    assert 'room03_patterns:' in tail
    assert 'room03_collision_map_rom:' in tail
    assert 'room03_tile_properties_rom:' in tail
    assert 'room03_screen_bat:' in tail

    print('OK: exact Room 03 RLE/tiles/colours/properties prepared as ROM-tail assets')


if __name__ == '__main__':
    main()
