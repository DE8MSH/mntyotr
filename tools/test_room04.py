#!/usr/bin/env python3
import struct
from pathlib import Path
from room_rle import decode_room, ROOM_CELLS, SCREEN_W, CHR_GAME
from room04 import (
    ROOM04_RLE, ROOM04_TILE_IDS, ROOM04_COLOURS, ROOM04_PROPERTIES,
    ROOM04_TILE_BITMAPS, PAL_BY_C64, build_patterns, make_screen_bat,
)

ROOT = Path(__file__).resolve().parents[1]


def words(blob):
    return list(struct.unpack('<' + 'H'*(len(blob)//2), blob))


def main():
    cells = decode_room(ROOM04_RLE)
    assert len(cells) == ROOM_CELLS == 640
    assert ROOM04_TILE_IDS == (0x03,0x62,0x3c,0x60,0x43,0x66,0x02,0x4f)
    assert ROOM04_COLOURS == (0x03,0x03,0x04,0x07,0x05,0x07,0x0d,0x09)
    assert ROOM04_PROPERTIES == (1,3,2,3,2,3,1,4)
    assert ROOM04_TILE_BITMAPS[1] == bytes.fromhex('c6 c6 ee 6c 20 20 6c ec')
    assert ROOM04_TILE_BITMAPS[3] == bytes.fromhex('38 20 70 20 70 10 38 08')
    assert ROOM04_TILE_BITMAPS[5] == bytes.fromhex('1e 36 2c 3e 1a 17 0d 0b')
    assert ROOM04_TILE_BITMAPS[7] == bytes.fromhex('6e 7e c7 d3 da c3 67 ef')

    patterns = build_patterns()
    assert len(patterns) == 9*32 and patterns[:32] == bytes(32)
    bat = words(make_screen_bat(cells))
    assert len(bat) == SCREEN_W*20
    for y in range(20):
        row = bat[y*SCREEN_W:(y+1)*SCREEN_W]
        assert row[0] == row[1] == row[2]
        assert row[-1] == row[-2] == row[-3]

    main_asm = (ROOT/'src/main.asm').read_text()
    tail = (ROOT/'src/room04_assets_tail.asm').read_text()
    loader = (ROOT/'src/room_loader.asm').read_text()
    banking = (ROOT/'src/collision_banking.asm').read_text()
    world = (ROOT/'src/world.asm').read_text()

    assert 'include "room04_assets_tail.asm"' in main_asm
    assert main_asm.index('include "room04_assets_tail.asm"') > main_asm.index('include "monty_sprite.asm"')
    assert 'room04_patterns:' in tail
    assert 'room04_collision_map_rom:' in tail
    assert 'room04_tile_properties_rom:' in tail
    assert 'room04_screen_bat:' in tail
    assert 'call    room04_upload_patterns' in loader
    assert 'call    room04_draw_native' in loader
    assert 'call    room04_cache_collision' in loader
    assert 'BANK(room04_collision_map_rom)' in loader
    assert 'lda     #4' in loader and 'sta     <monty_room' in loader
    assert 'cmp     #3' in banking and 'bcc     .select_room' in banking
    assert 'world_room_supported:' in world
    compact = ''.join(world.lower().split())
    assert 'cmp#$10' in compact
    assert 'db$2b,$2a,$28,$29,$ff,$ff,$ff,$ff,$ff,$1f,$ff,$ff,$1b,$ff,$ff,$0f,$0c,$0d,$0e,$0b,$0a,$ff,$ff' in compact

    print('OK: exact Room 04 active and reachable through Room 0D from below')


if __name__ == '__main__':
    main()
