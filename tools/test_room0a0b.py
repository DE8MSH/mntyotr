#!/usr/bin/env python3
import struct
from pathlib import Path

from room_rle import decode_room, ROOM_CELLS, SCREEN_W
from room0a import (
    ROOM0A_RLE, ROOM0A_TILE_IDS, ROOM0A_COLOURS, ROOM0A_PROPERTIES,
    ROOM0A_TILE_BITMAPS, build_patterns as build0a, make_screen_bat as bat0a,
)
from room0b import (
    ROOM0B_RLE, ROOM0B_TILE_IDS, ROOM0B_COLOURS, ROOM0B_PROPERTIES,
    ROOM0B_TILE_BITMAPS, build_patterns as build0b, make_screen_bat as bat0b,
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
    check_room(ROOM0A_RLE, ROOM0A_TILE_IDS, ROOM0A_COLOURS, ROOM0A_PROPERTIES,
               ROOM0A_TILE_BITMAPS, build0a, bat0a)
    check_room(ROOM0B_RLE, ROOM0B_TILE_IDS, ROOM0B_COLOURS, ROOM0B_PROPERTIES,
               ROOM0B_TILE_BITMAPS, build0b, bat0b)

    assert len(ROOM0A_RLE) == 116
    assert ROOM0A_TILE_IDS == (0x0c,0x65,0x43,0x3a,0x00,0x00,0x00,0x00)
    assert ROOM0A_COLOURS == (0x09,0x05,0x03,0x04,0x02,0x00,0x00,0x00)
    assert ROOM0A_PROPERTIES == (1,3,2,2,1,1,1,1)
    assert ROOM0A_TILE_BITMAPS[1] == bytes.fromhex('6c 44 d4 aa fe 00 6c 6c')
    assert ROOM0A_TILE_BITMAPS[2] == bytes.fromhex('ff aa ee 44 ee bb 00 00')

    assert len(ROOM0B_RLE) == 124
    assert ROOM0B_TILE_IDS == (0x05,0x47,0x65,0x3b,0x36,0x62,0x03,0x51)
    assert ROOM0B_COLOURS == (0x0a,0x03,0x07,0x04,0x01,0x05,0x0d,0x08)
    assert ROOM0B_PROPERTIES == (1,1,3,2,2,3,1,4)
    assert ROOM0B_TILE_BITMAPS[1] == bytes.fromhex('36 00 7b 7b 7b 36 36 36')
    assert ROOM0B_TILE_BITMAPS[7] == bytes.fromhex('49 19 f7 f7 e7 87 27 6d')

    world = parse_world_grid()
    assert len(world) == 6 and all(len(row) == 23 for row in world)
    # Exact C64 topology around the newly exposed floor openings.
    assert world[2][0x14] == 0x01 and world[3][0x14] == 0x0a
    assert world[2][0x13] == 0x02 and world[3][0x13] == 0x0b
    assert world[3][0x12] == 0x0e
    assert world[3][0x11] == 0x0d and world[2][0x11] == 0x04

    main_asm = (ROOT/'src/main.asm').read_text()
    loader = (ROOT/'src/room_loader.asm').read_text()
    world_asm = (ROOT/'src/world.asm').read_text()
    for room in ('0a','0b'):
        name = f'room{room}_assets_tail.asm'
        assert f'include "{name}"' in main_asm
        assert main_asm.index(f'include "{name}"') > main_asm.index('include "monty_sprite.asm"')
        assert f'call    room{room}_upload_patterns' in loader
        assert f'call    room{room}_draw_native' in loader
        assert f'call    room{room}_cache_collision' in loader
        assert f'BANK(room{room}_collision_map_rom)' in loader
        assert f'cmp     #${room}' in world_asm

    # Growing selector tables must use long jumps to their common helpers.
    assert loader.count('jmp     room_tail_cache_collision') >= 6
    assert loader.count('jmp     room_upload_9_patterns') >= 7
    assert loader.count('jmp     room_draw_native_36x20') >= 7

    print('OK: exact Room 0A/0B assets + lower-house route wiring')


if __name__ == '__main__':
    main()
