#!/usr/bin/env python3
import struct
from pathlib import Path
from room_rle import decode_room, ROOM_CELLS, CHR_GAME, SCREEN_W
from room01 import (
    ROOM01_RLE, ROOM01_TILE_IDS, ROOM01_COLOURS, ROOM01_PROPERTIES,
    build_patterns, make_screen_bat, PAL_BY_C64,
)

ROOT = Path(__file__).resolve().parents[1]


def words(blob):
    return list(struct.unpack('<' + 'H'*(len(blob)//2), blob))


def main():
    cells = decode_room(ROOM01_RLE)
    assert len(cells) == ROOM_CELLS == 640
    assert ROOM01_TILE_IDS == (0x02,0x63,0x01,0x0a,0x40,0x05,0x55,0x64)
    assert ROOM01_COLOURS == (0x04,0x03,0x03,0x05,0x01,0x0a,0x06,0x05)
    assert ROOM01_PROPERTIES == (1,0,1,1,2,1,4,0)

    patterns = build_patterns()
    assert len(patterns) == 9*32
    assert patterns[:32] == bytes(32)  # screen code 0 remains blank

    bat = words(make_screen_bat(cells))
    assert len(bat) == SCREEN_W*20
    for y in range(20):
        row = bat[y*SCREEN_W:(y+1)*SCREEN_W]
        assert row[0] == row[1] == row[2]
        assert row[-1] == row[-2] == row[-3]
    # Every custom screen code uses the low-nibble C64 colour from room_defs.
    for code in range(1,9):
        expected_pal = PAL_BY_C64[ROOM01_COLOURS[code-1] & 0x0f]
        samples = [w for w in bat if (w & 0x0fff) == CHR_GAME + code]
        assert samples, f'room01 code {code} never appears'
        assert all((w >> 12) == expected_pal for w in samples)

    main_asm = (ROOT/'src/main.asm').read_text()
    physics = (ROOT/'src/monty_physics.asm').read_text()
    world = (ROOT/'src/world.asm').read_text()
    assert 'call    room_load_pending' in main_asm
    assert 'room01_collision_map' in physics and 'room01_tile_properties' in physics
    assert 'cmp     #2' in world  # unsupported rooms are gated until loaded

    print('OK: exact room 01 RLE/tiles/colours/properties + 00<->01 loader wiring')


if __name__ == '__main__':
    main()
