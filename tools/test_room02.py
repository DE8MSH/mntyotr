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

    # Exact source geometry remains pinned even though generated Phase-48 data
    # overlays a temporary right-side traversal ladder for runtime testing.
    for y in range(9, 16):
        assert cells[y*32 + 16:y*32 + 21] == [2,2,2,2,2]
    for y in range(12, 18):
        assert cells[y*32 + 25] == 4

    # Preserve the original C64 20-pixel ascent arc globally.
    exact_up = '$00,$03,$02,$02,$01,$02,$01,$01,$00,$01,$01,$01\n        db $00,$01,$01,$01,$00,$01,$00,$01,$00,$00,$ff'
    assert exact_up in physics
    assert sum((0,3,2,2,1,2,1,1,0,1,1,1,0,1,1,1,0,1,0,1,0,0)) == 20

    # Pre-world jump guard is topology-independent and only protects Room00 right.
    guard = main_asm.split('call    monty_update_input', 1)[1]
    guard = guard.split('.after_unsupported_jump_edge:', 1)[0]
    assert 'cmp     #2' in guard
    assert 'cmp     #4' not in guard
    assert 'lda     #$9b' in guard

    print('OK: Room 02 exact source geometry + original 20-pixel jump arc preserved')


if __name__ == '__main__':
    main()
