#!/usr/bin/env python3
import struct
from pathlib import Path

from room_rle import decode_room, ROOM_CELLS, SCREEN_W
from room05 import (
    ROOM05_RLE, ROOM05_TILE_IDS, ROOM05_COLOURS, ROOM05_PROPERTIES,
    ROOM05_TILE_BITMAPS, build_patterns as build05, make_screen_bat as bat05,
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
    cells05 = check_room(ROOM05_RLE, ROOM05_TILE_IDS, ROOM05_COLOURS,
                         ROOM05_PROPERTIES, ROOM05_TILE_BITMAPS, build05, bat05)
    check_room(ROOM0C_RLE, ROOM0C_TILE_IDS, ROOM0C_COLOURS,
               ROOM0C_PROPERTIES, ROOM0C_TILE_BITMAPS, build0c, bat0c)

    assert len(ROOM05_RLE) == 122
    assert ROOM05_TILE_IDS == (0x01,0x41,0x2b,0x65,0x67,0x00,0x3f,0x63)
    assert ROOM05_COLOURS == (0x01,0x05,0x03,0x04,0x07,0x0d,0x02,0x03)
    assert ROOM05_PROPERTIES == (1,2,2,3,3,1,2,3)
    assert ROOM05_TILE_BITMAPS[1] == bytes.fromhex('ff ff ff 00 ff 00 00 00')
    assert ROOM05_TILE_BITMAPS[4] == bytes.fromhex('c3 c3 c3 bb bb c3 c3 c3')

    assert len(ROOM0C_RLE) == 91
    assert ROOM0C_TILE_IDS == (0x05,0x0f,0x10,0x28,0x6a,0x5f,0x4f,0x00)
    assert ROOM0C_COLOURS == (0x0d,0x05,0x07,0x03,0x05,0x02,0x02,0x00)
    assert ROOM0C_PROPERTIES == (1,1,1,2,3,3,4,1)
    assert ROOM0C_TILE_BITMAPS[3] == bytes.fromhex('ff c1 63 36 1c ff 00 00')
    assert ROOM0C_TILE_BITMAPS[6] == bytes.fromhex('6e 7e c7 d3 da c3 67 ef')

    bottom = cells05[18*32:20*32]
    assert 0 in bottom and 5 in bottom

    world = parse_world_grid()
    assert world[2][0x11] == 0x04
    assert world[2][0x10] == 0x05
    assert world[3][0x10] == 0x0c
    assert world[3][0x0f] == 0x0f
    assert world[4][0x10] == 0x11

    main_asm = (ROOT/'src/main.asm').read_text()
    ext = (ROOT/'src/room050c_loader.asm').read_text()
    world_asm = (ROOT/'src/world.asm').read_text()
    for room in ('05','0c'):
        assert f'include "room{room}_assets_tail.asm"' in main_asm
        assert f'room{room}_collision_map_rom' in ext
        assert f'room{room}_upload_patterns' in ext
        assert f'room{room}_draw_native' in ext
        assert f'room{room}_cache_collision' in ext
    assert 'include "room050c_loader.asm"' in main_asm
    assert 'call    room_load_pending_extended' in main_asm
    assert 'jmp     room_load_pending' in ext
    assert 'cmp     #6' in world_asm
    assert 'cmp     #$0c' in world_asm

    # $04 left remains supported; don't tie this check to comments/phase labels.
    guard = main_asm.split('call    monty_update_input', 1)[1]
    guard = guard.split('.after_unsupported_jump_edge:', 1)[0]
    assert 'cmp     #4' not in guard

    print('OK: exact Room 05/0C assets + $04->$05->$0C continuation wiring')


if __name__ == '__main__':
    main()
