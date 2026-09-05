#!/usr/bin/env python3
from pathlib import Path

from room_rle import decode_room, ROOM_CELLS
from room01 import (
    ROOM01_RLE, ROOM01_PROPERTIES, ROOM01_CLOUD_COLUMNS,
    ROOM01_DEBUG_BRIDGE, ROOM01_DEBUG_SCAFFOLD,
    apply_debug_scaffold as scaffold01,
)
from room02 import ROOM02_RLE, ROOM02_PROPERTIES, ROOM02_DEBUG_SCAFFOLD, apply_debug_scaffold as scaffold02
from room09 import (
    ROOM09_RLE, ROOM09_TILE_IDS, ROOM09_COLOURS, ROOM09_PROPERTIES,
    ROOM09_TILE_BITMAPS, ROOM09_DEBUG_SCAFFOLD,
    apply_debug_scaffold as scaffold09, build_patterns,
)

ROOT = Path(__file__).resolve().parents[1]


def main():
    # Exact C64 source streams remain intact. Room01's old permanent climb shaft
    # is gone; the cloud columns are dynamically overlaid at runtime instead.
    base01 = decode_room(ROOM01_RLE)
    base02 = decode_room(ROOM02_RLE)
    assert len(base01) == len(base02) == ROOM_CELLS == 640

    run01 = scaffold01(base01)
    assert ROOM01_PROPERTIES[7] == 3      # code 8 / tile $64 = moving cloud collision
    assert ROOM01_CLOUD_COLUMNS == (8, 9, 10)
    assert ROOM01_DEBUG_SCAFFOLD == ROOM01_DEBUG_BRIDGE
    # The exact cloud path is empty in source/generated base data; runtime owns it.
    for y in range(1, 19):
        for x in ROOM01_CLOUD_COLUMNS:
            assert base01[y*32+x] == 0
            assert run01[y*32+x] == 0

    # Temporary property-2 access bridge remains from the right entry platform
    # to the moving cloud's real columns.
    assert ROOM01_PROPERTIES[4] == 2
    for x in range(11, 25):
        assert (17, x) in ROOM01_DEBUG_BRIDGE
        assert run01[17*32+x] == 5

    run02 = scaffold02(base02)
    assert ROOM02_PROPERTIES[3] == 3
    for y in range(7, 18):
        assert run02[y*32+24] == 4
    for y in range(7, 12):
        assert run02[y*32+25] == 4
    # Preserve proof that the unmodified Room02 source still has its wall.
    for y in range(9, 16):
        assert base02[y*32+16:y*32+21] == [2,2,2,2,2]

    base09 = decode_room(ROOM09_RLE)
    assert len(ROOM09_RLE) == 170 and len(base09) == 640
    assert ROOM09_TILE_IDS == (0x05,0x2c,0x3b,0x42,0x65,0x60,0x15,0x4f)
    assert ROOM09_COLOURS == (0x0a,0x02,0x08,0x03,0x05,0x03,0x0d,0x05)
    assert ROOM09_PROPERTIES == (1,2,2,2,3,3,1,4)
    assert ROOM09_PROPERTIES[5] == 3
    assert ROOM09_TILE_BITMAPS[1] == bytes.fromhex('cf df df cf 00 00 00 00')
    assert ROOM09_TILE_BITMAPS[6] == bytes.fromhex('44 38 83 c6 44 6c 38 83')
    assert len(build_patterns()) == 9*32

    run09 = scaffold09(base09)
    for y in range(15, 20):
        for x in (8, 9, 10):
            assert run09[y*32+x] == 6
    for x in range(11, 16):
        assert run09[15*32+x] == 6
    assert base09[14*32+15] == 5 and ROOM09_PROPERTIES[4] == 3
    assert (15, 15) in ROOM09_DEBUG_SCAFFOLD

    main_asm = (ROOT/'src/main.asm').read_text()
    world = (ROOT/'src/world.asm').read_text().lower()
    ext = (ROOT/'src/room050c_loader.asm').read_text()
    footer = (ROOT/'src/debug_footer_visible.asm').read_text()
    tail09 = (ROOT/'src/room09_assets_tail.asm').read_text()
    cloud = (ROOT/'src/rising_cloud.asm').read_text()
    room01_native = (ROOT/'src/room01_native.asm').read_text()

    assert 'include "room09_assets_tail.asm"' in main_asm
    assert 'include "debug_footer_visible.asm"' in main_asm
    assert 'include "rising_cloud.asm"' in main_asm
    assert 'call    rising_cloud_init' in main_asm
    assert 'call    rising_cloud_update' in main_asm
    assert main_asm.count('call    rising_cloud_room_sync') >= 2
    # Footer/commit are static debug text: draw once at startup, never per frame.
    assert main_asm.count('call    debug_footer_visible_draw') == 1
    assert 'main_y_before_step:        ds 1' in main_asm
    assert 'cmp     <main_y_before_step' in main_asm
    assert 'beq     .after_down_room_edge' in main_asm

    # Dynamic Room01 collision architecture + exact C64 cloud cadence/path.
    assert '.bss' in room01_native and 'room01_collision_map:' in room01_native
    assert 'ds 640' in room01_native
    assert 'room01_collision_map_rom:' in room01_native
    assert 'CLOUD_VIS_COL       = 12' in cloud
    assert 'CLOUD_CODE          = 8' in cloud
    assert 'inc     <rising_cloud_tick' in cloud
    assert 'and     #1' in cloud
    assert 'dec     <rising_cloud_y' in cloud
    assert 'ldy     #8' in cloud
    assert cloud.count('sta     [_di],y') >= 6
    assert 'call    rising_cloud_copy_room01_map' in cloud
    assert 'BANK(room01_collision_map_rom)' in cloud
    assert 'cmp     #$52' in cloud and 'cmp     #$da' in cloud

    assert 'cmp     #$09' in ext and '.room09:' in ext
    assert 'room09_cache_collision:' in ext
    assert 'room09_collision_map_rom:' in tail09
    assert 'cmp     #$09' in world
    assert '$01 up->$09' in world
    assert 'DEBUG_FOOTER_VISIBLE_BAT = 23*BAT_LINE' in footer

    compact = ''.join(world.split())
    assert 'db$ff,$2f,$2e,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$22,$ff,$ff,$ff,$ff,$ff,$ff,$06,$07,$08,$09,$ff,$ff' in compact
    assert 'db$2d,$2c,$27,$26,$33,$32,$31,$25,$24,$20,$21,$ff,$ff,$ff,$ff,$ff,$05,$04,$03,$02,$01,$00,$ff' in compact

    print('OK: dynamic Room01 rising cloud + access bridge + Room02/09 traversal aids + exact Room09 route')


if __name__ == '__main__':
    main()
