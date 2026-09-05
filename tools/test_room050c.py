#!/usr/bin/env python3
import struct
from pathlib import Path

from room_rle import decode_room, ROOM_CELLS, SCREEN_W
from room05 import (
    ROOM05_RLE, ROOM05_TILE_IDS, ROOM05_COLOURS, ROOM05_PROPERTIES,
    ROOM05_TILE_BITMAPS, build_patterns as build05, make_screen_bat as bat05,
)
from room06 import (
    ROOM06_RLE, ROOM06_TILE_IDS, ROOM06_COLOURS, ROOM06_PROPERTIES,
    ROOM06_TILE_BITMAPS, build_patterns as build06, make_screen_bat as bat06,
)
from room07 import (
    ROOM07_RLE, ROOM07_TILE_IDS, ROOM07_COLOURS, ROOM07_PROPERTIES,
    ROOM07_TILE_BITMAPS, build_patterns as build07, make_screen_bat as bat07,
)
from room08 import (
    ROOM08_RLE, ROOM08_TILE_IDS, ROOM08_COLOURS, ROOM08_PROPERTIES,
    ROOM08_TILE_BITMAPS, build_patterns as build08, make_screen_bat as bat08,
)
from room0c import (
    ROOM0C_RLE, ROOM0C_TILE_IDS, ROOM0C_COLOURS, ROOM0C_PROPERTIES,
    ROOM0C_TILE_BITMAPS, build_patterns as build0c, make_screen_bat as bat0c,
)

ROOT = Path(__file__).resolve().parents[1]


def words(blob):
    return list(struct.unpack('<' + 'H'*(len(blob)//2), blob))


def check_room(stream, ids, colours, props, bitmaps, build, make_bat):
    cells = decode_room(stream)
    assert len(cells) == ROOM_CELLS == 640
    assert len(ids) == len(colours) == len(props) == len(bitmaps) == 8
    patterns = build()
    assert len(patterns) == 9*32 and patterns[:32] == bytes(32)
    bat = words(make_bat(cells))
    assert len(bat) == SCREEN_W*20
    return cells


def parse_world_grid():
    text = (ROOT/'src/world.asm').read_text()
    block = text.split('world_room_grid:', 1)[1]
    rows = []
    for line in block.splitlines():
        line = line.strip()
        if not line.startswith('db '):
            if rows:
                break
            continue
        rows.append([int(tok.strip()[1:], 16) for tok in line[3:].split(',')])
    return rows


def main():
    rooms = (
        (ROOM05_RLE, ROOM05_TILE_IDS, ROOM05_COLOURS, ROOM05_PROPERTIES, ROOM05_TILE_BITMAPS, build05, bat05),
        (ROOM06_RLE, ROOM06_TILE_IDS, ROOM06_COLOURS, ROOM06_PROPERTIES, ROOM06_TILE_BITMAPS, build06, bat06),
        (ROOM07_RLE, ROOM07_TILE_IDS, ROOM07_COLOURS, ROOM07_PROPERTIES, ROOM07_TILE_BITMAPS, build07, bat07),
        (ROOM08_RLE, ROOM08_TILE_IDS, ROOM08_COLOURS, ROOM08_PROPERTIES, ROOM08_TILE_BITMAPS, build08, bat08),
        (ROOM0C_RLE, ROOM0C_TILE_IDS, ROOM0C_COLOURS, ROOM0C_PROPERTIES, ROOM0C_TILE_BITMAPS, build0c, bat0c),
    )
    for args in rooms:
        check_room(*args)

    assert len(ROOM06_RLE) == 120
    assert ROOM06_TILE_IDS == (0x01,0x2d,0x5f,0x3d,0x61,0x3b,0x24,0x65)
    assert ROOM06_COLOURS == (0x02,0x04,0x03,0x07,0x05,0x02,0x07,0x05)
    assert ROOM06_PROPERTIES == (1,2,3,2,3,2,1,3)

    assert len(ROOM07_RLE) == 97
    assert ROOM07_TILE_IDS == (0x01,0x47,0x0c,0x3a,0x3b,0x39,0x4f,0x00)
    assert ROOM07_COLOURS == (0x01,0x03,0x05,0x04,0x02,0x08,0x02,0x00)
    assert ROOM07_PROPERTIES == (1,1,1,2,2,2,4,1)

    assert len(ROOM08_RLE) == 77
    assert ROOM08_TILE_IDS == (0x01,0x28,0x1d,0x6a,0x40,0x68,0x37,0x4f)
    assert ROOM08_COLOURS == (0x01,0x03,0x09,0x01,0x04,0x07,0x05,0x02)
    assert ROOM08_PROPERTIES == (1,2,1,3,2,3,2,4)

    # Exact upper route from the original 6x23 world grid.
    world = parse_world_grid()
    assert world[1][0x11:0x15] == [0x06,0x07,0x08,0x09]
    assert world[2][0x10:0x15] == [0x05,0x04,0x03,0x02,0x01]
    assert world[3][0x10] == 0x0c

    main_asm = (ROOT/'src/main.asm').read_text()
    ext = (ROOT/'src/room050c_loader.asm').read_text()
    tail05 = (ROOT/'src/room05_assets_tail.asm').read_text()
    world_asm = (ROOT/'src/world.asm').read_text()

    for room in ('06','07','08'):
        assert f'include "room{room}_assets_tail.asm"' in tail05
        assert f'room{room}_patterns' in ext
        assert f'room{room}_screen_bat' in ext
        assert f'room{room}_collision_map_rom' in ext
    assert 'include "room050c_loader.asm"' in main_asm
    assert 'call    room_load_pending_extended' in main_asm
    assert 'room_ext_patterns_lo:' in ext
    assert 'room_ext_bat_lo:' in ext
    assert 'room_ext_collision_lo:' in ext
    assert 'cmp     #$0f' in world_asm

    # $04 left remains supported; don't tie this check to comments/phase labels.
    guard = main_asm.split('call    monty_update_input', 1)[1]
    guard = guard.split('.after_unsupported_jump_edge:', 1)[0]
    assert 'cmp     #4' not in guard

    print('OK: exact Rooms 05-08/0C assets + contiguous upper-house route + compact tail loader')


if __name__ == '__main__':
    main()
