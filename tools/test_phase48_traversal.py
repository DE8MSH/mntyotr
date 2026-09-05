#!/usr/bin/env python3
from pathlib import Path

from room_rle import decode_room, ROOM_CELLS
from room01 import ROOM01_RLE, ROOM01_PROPERTIES, ROOM01_DEBUG_SCAFFOLD, apply_debug_scaffold as scaffold01
from room02 import ROOM02_RLE, ROOM02_PROPERTIES, ROOM02_DEBUG_SCAFFOLD, apply_debug_scaffold as scaffold02
from room09 import (
    ROOM09_RLE, ROOM09_TILE_IDS, ROOM09_COLOURS, ROOM09_PROPERTIES,
    ROOM09_TILE_BITMAPS, build_patterns,
)

ROOT = Path(__file__).resolve().parents[1]


def main():
    # Exact C64 source streams remain intact; only generated runtime maps receive
    # temporary traversal scaffolds while missing mechanics/death are developed.
    base01 = decode_room(ROOM01_RLE)
    base02 = decode_room(ROOM02_RLE)
    assert len(base01) == len(base02) == ROOM_CELLS == 640

    run01 = scaffold01(base01)
    assert ROOM01_PROPERTIES[7] == 3
    assert (13, 11) in ROOM01_DEBUG_SCAFFOLD
    for y in range(0, 19):
        for x in (8, 9, 10):
            assert run01[y*32+x] == 8
    # The scaffold follows C64 UpdateRisingCloud's screen columns $0C-$0E,
    # i.e. logical room columns 8..10 after the four-column C64 border offset.

    run02 = scaffold02(base02)
    assert ROOM02_PROPERTIES[3] == 3
    for y in range(7, 18):
        assert run02[y*32+24] == 4
    for y in range(7, 12):
        assert run02[y*32+25] == 4
    # Preserve proof that the unmodified source still has the original wall.
    for y in range(9, 16):
        assert base02[y*32+16:y*32+21] == [2,2,2,2,2]

    cells09 = decode_room(ROOM09_RLE)
    assert len(ROOM09_RLE) == 170 and len(cells09) == 640
    assert ROOM09_TILE_IDS == (0x05,0x2c,0x3b,0x42,0x65,0x60,0x15,0x4f)
    assert ROOM09_COLOURS == (0x0a,0x02,0x08,0x03,0x05,0x03,0x0d,0x05)
    assert ROOM09_PROPERTIES == (1,2,2,2,3,3,1,4)
    assert ROOM09_TILE_BITMAPS[1] == bytes.fromhex('cf df df cf 00 00 00 00')
    assert ROOM09_TILE_BITMAPS[6] == bytes.fromhex('44 38 83 c6 44 6c 38 83')
    assert len(build_patterns()) == 9*32

    main_asm = (ROOT/'src/main.asm').read_text()
    world = (ROOT/'src/world.asm').read_text().lower()
    ext = (ROOT/'src/room050c_loader.asm').read_text()
    footer = (ROOT/'src/debug_footer_visible.asm').read_text()
    tail09 = (ROOT/'src/room09_assets_tail.asm').read_text()

    assert 'include "room09_assets_tail.asm"' in main_asm
    assert 'include "debug_footer_visible.asm"' in main_asm
    assert main_asm.count('call    debug_footer_visible_draw') >= 2
    assert 'cmp     #$09' in ext and '.room09:' in ext
    assert 'room09_cache_collision:' in ext
    assert 'room09_collision_map_rom:' in tail09
    assert 'cmp     #$09' in world
    assert '$01 up->$09' in world
    assert 'DEBUG_FOOTER_VISIBLE_BAT = 23*BAT_LINE' in footer

    # Exact world row1 col20 is $09; row2 col20 below is $01.
    compact = ''.join(world.split())
    assert 'db$ff,$2f,$2e,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$22,$ff,$ff,$ff,$ff,$ff,$ff,$06,$07,$08,$09,$ff,$ff' in compact
    assert 'db$2d,$2c,$27,$26,$33,$32,$31,$25,$24,$20,$21,$ff,$ff,$ff,$ff,$ff,$05,$04,$03,$02,$01,$00,$ff' in compact

    print('OK: Phase 48 Room01/02 traversal scaffolds + exact Room09 upward test route + visible footer')


if __name__ == '__main__':
    main()
