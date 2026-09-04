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
    assert len(patterns) == 9*32 and patterns[:32] == bytes(32)
    bat = words(make_screen_bat(cells))
    assert len(bat) == SCREEN_W*20

    main_asm = (ROOT/'src/main.asm').read_text()
    tail = (ROOT/'src/room03_assets_tail.asm').read_text()
    loader = (ROOT/'src/room_loader.asm').read_text()
    banking = (ROOT/'src/collision_banking.asm').read_text()
    world = (ROOT/'src/world.asm').read_text()

    assert 'include "room03_assets_tail.asm"' in main_asm
    assert main_asm.index('include "room03_assets_tail.asm"') > main_asm.index('include "monty_sprite.asm"')
    assert 'room03_collision_map_rom:' in tail and 'room03_tile_properties_rom:' in tail
    assert 'call    room03_upload_patterns' in loader
    assert 'call    room03_draw_native' in loader
    assert 'call    room03_cache_collision' in loader
    assert 'BANK(room03_collision_map_rom)' in loader
    assert 'lda     #3' in loader and 'sta     <monty_room' in loader

    # Room03 reuses the proven Room02 RAM cache without changing physics.
    assert 'collision_actual_room' in banking
    assert 'cmp     #3' in banking
    assert 'bcc     .select_room' in banking
    assert 'lda     #2' in banking and 'sta     <monty_room' in banking
    assert 'lda     <collision_actual_room' in main_asm
    assert 'cmp     #4' in main_asm
    assert 'cmp     #5' in world

    print('OK: exact Room 03 assets active; left neighbor Room 04 now enabled')


if __name__ == '__main__':
    main()
