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
    for y in range(20):
        row = bat[y*SCREEN_W:(y+1)*SCREEN_W]
        assert row[0] == row[1] == row[2]
        assert row[-1] == row[-2] == row[-3]

    for code in sorted(set(cells) - {0}):
        if code >= 9:
            continue
        expected_pal = PAL_BY_C64[ROOM02_COLOURS[code-1] & 0x0f]
        samples = [w for w in bat if (w & 0x0fff) == CHR_GAME + code]
        assert samples
        assert all((w >> 12) == expected_pal for w in samples)

    main_asm = (ROOT/'src/main.asm').read_text()
    tail = (ROOT/'src/room02_assets_tail.asm').read_text()
    physics = (ROOT/'src/monty_physics.asm').read_text()
    banking = (ROOT/'src/collision_banking.asm').read_text()
    loader = (ROOT/'src/room_loader.asm').read_text()
    world = (ROOT/'src/world.asm').read_text()

    assert 'include "room02_assets_tail.asm"' in main_asm
    assert main_asm.index('include "room02_assets_tail.asm"') > main_asm.index('include "monty_sprite.asm"')
    assert 'room02_collision_map:' in tail
    assert 'room02_screen_bat:' in tail
    assert 'room02_tile_properties:' in tail

    assert 'lda     room02_tile_properties,x' in physics
    assert '#<room02_collision_map' in physics and '#>room02_collision_map' in physics
    assert 'BANK(room02_collision_map)' in banking
    assert 'call    room02_upload_patterns' in loader
    assert 'call    room02_draw_native' in loader
    assert 'sta     <monty_room' in loader
    assert 'cmp     #3' in world

    # The supported horizontal chain is now Room 02 <-> 01 <-> 00.
    assert 'cmp     #2' in main_asm
    assert 'Room $02 left would enter Room $03' in main_asm

    print('OK: exact Room 02 assets + collision + loader + 02<->01 world wiring')


if __name__ == '__main__':
    main()
