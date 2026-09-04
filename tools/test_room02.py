#!/usr/bin/env python3
import struct
from pathlib import Path
from room_rle import decode_room, ROOM_CELLS, SCREEN_W, CHR_GAME
from room02 import (
    ROOM02_RLE, ROOM02_TILE_IDS, ROOM02_COLOURS, ROOM02_PROPERTIES,
    ROOM02_TILE_BITMAPS, PAL_BY_C64, build_patterns, make_screen_bat,
)

ROOT = Path(__file__).resolve().parents[1]


def words(blob):
    return list(struct.unpack('<' + 'H'*(len(blob)//2), blob))


def main():
    cells = decode_room(ROOM02_RLE)
    assert len(cells) == ROOM_CELLS == 640
    assert ROOM02_TILE_IDS == (0x02,0x01,0x27,0x60,0x3d,0x42,0x77,0x55)
    assert ROOM02_COLOURS == (0x05,0x04,0x07,0x04,0x06,0x01,0x06,0x06)
    assert ROOM02_PROPERTIES == (1,1,2,3,2,2,0,4)
    assert ROOM02_TILE_BITMAPS[2] == bytes.fromhex('ff 01 6d 01 ff 00 00 00')
    assert ROOM02_TILE_BITMAPS[3] == bytes.fromhex('38 20 70 20 70 10 38 08')
    assert ROOM02_TILE_BITMAPS[6] == bytes.fromhex('ff ff ff ff ff ff ff ff')

    patterns = build_patterns()
    assert len(patterns) == 9*32
    assert patterns[:32] == bytes(32)
    bat = words(make_screen_bat(cells))
    assert len(bat) == SCREEN_W*20

    main_asm = (ROOT/'src/main.asm').read_text()
    tail = (ROOT/'src/room02_assets_tail.asm').read_text()
    physics = (ROOT/'src/monty_physics.asm').read_text()
    banking = (ROOT/'src/collision_banking.asm').read_text()
    loader = (ROOT/'src/room_loader.asm').read_text()
    world = (ROOT/'src/world.asm').read_text()

    assert 'include "room02_assets_tail.asm"' in main_asm
    assert main_asm.index('include "room02_assets_tail.asm"') > main_asm.index('include "monty_sprite.asm"')
    assert 'room02_collision_map_rom:' in tail
    assert 'room02_screen_bat:' in tail
    assert 'room02_tile_properties_rom:' in tail
    assert 'lda     room02_tile_properties,x' in physics
    assert '#<room02_collision_map' in physics and '#>room02_collision_map' in physics
    assert 'room02_collision_map:   ds 640' in banking
    assert 'room02_tile_properties: ds 8' in banking
    assert 'BANK(room02_collision_map)' not in banking
    assert 'call    room02_upload_patterns' in loader
    assert 'call    room02_draw_native' in loader
    assert 'call    room02_cache_collision' in loader
    assert 'BANK(room02_collision_map_rom)' in loader
    assert 'world_room_supported:' in world

    # Room02 remains an interior room; outer-edge policy must not be tied to it.
    guard = main_asm.index('lda     <collision_actual_room')
    guard_end = main_asm.index('.guard_room00_right:', guard)
    outer_left_guard = main_asm[guard:guard_end]
    assert 'cmp     #4' in outer_left_guard
    assert 'cmp     #1' in outer_left_guard
    assert 'lda     #$15' in outer_left_guard

    print('OK: Room 02 remains stable inside the active house route')


if __name__ == '__main__':
    main()
