#!/usr/bin/env python3
import struct
from pathlib import Path
from room_rle import decode_room, ROOM_CELLS, SCREEN_W, CHR_GAME
from room0d import ROOM0D_RLE, ROOM0D_TILE_IDS, ROOM0D_COLOURS, ROOM0D_PROPERTIES, ROOM0D_TILE_BITMAPS, build_patterns as build0d, make_screen_bat as bat0d
from room0e import ROOM0E_RLE, ROOM0E_TILE_IDS, ROOM0E_COLOURS, ROOM0E_PROPERTIES, ROOM0E_TILE_BITMAPS, build_patterns as build0e, make_screen_bat as bat0e

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


def main():
    check_room(ROOM0D_RLE, ROOM0D_TILE_IDS, ROOM0D_COLOURS, ROOM0D_PROPERTIES, ROOM0D_TILE_BITMAPS, build0d, bat0d)
    check_room(ROOM0E_RLE, ROOM0E_TILE_IDS, ROOM0E_COLOURS, ROOM0E_PROPERTIES, ROOM0E_TILE_BITMAPS, build0e, bat0e)

    # Primary room_data.asm has five consecutive $f0 runs here. Dropping one
    # shortens Room $0D by exactly 16 cells (624 instead of 640), so pin it.
    assert ROOM0D_RLE[32:38] == bytes.fromhex('f0 f0 f0 f0 f0 22')
    assert len(ROOM0D_RLE) == 66

    assert ROOM0D_TILE_IDS == (0x05,0x0f,0x4f,0x19,0x00,0x00,0x00,0x00)
    assert ROOM0D_COLOURS == (0x0d,0x05,0x02,0x00,0x00,0x00,0x00,0x00)
    assert ROOM0D_PROPERTIES == (1,1,4,1,1,1,1,1)
    assert ROOM0E_TILE_IDS == (0x05,0x0f,0x6a,0x36,0x60,0x3a,0x26,0x4f)
    assert ROOM0E_COLOURS == (0x0d,0x05,0x01,0x03,0x07,0x04,0x07,0x02)
    assert ROOM0E_PROPERTIES == (1,1,3,2,3,2,1,4)
    assert ROOM0E_TILE_BITMAPS[2] == bytes.fromhex('08 08 18 10 30 20 30 10')
    assert ROOM0E_TILE_BITMAPS[4] == bytes.fromhex('38 20 70 20 70 10 38 08')

    main_asm = (ROOT/'src/main.asm').read_text()
    loader = (ROOT/'src/room_loader.asm').read_text()
    for name in ('room0d_assets_tail.asm','room0e_assets_tail.asm'):
        assert f'include "{name}"' in main_asm
        assert main_asm.index(f'include "{name}"') > main_asm.index('include "monty_sprite.asm"')
    for room in ('0d','0e'):
        assert f'call    room{room}_upload_patterns' in loader
        assert f'call    room{room}_draw_native' in loader
        assert f'call    room{room}_cache_collision' in loader
        assert f'BANK(room{room}_collision_map_rom)' in loader

    print('OK: exact Room 0D/0E assets + tail-cache loader wiring')


if __name__ == '__main__':
    main()
