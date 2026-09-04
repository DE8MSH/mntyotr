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

    # The exact room-$01 RLE does not use every custom slot. In particular
    # screen code 2 is absent even though SetupTileGraphics still installs all
    # eight room-custom characters from room_defs. Keep that distinction exact.
    used_codes = set(cells)
    assert used_codes == {0,1,3,4,5,6,7,8}

    patterns = build_patterns()
    assert len(patterns) == 9*32
    assert patterns[:32] == bytes(32)  # screen code 0 remains blank

    bat = words(make_screen_bat(cells))
    assert len(bat) == SCREEN_W*20
    for y in range(20):
        row = bat[y*SCREEN_W:(y+1)*SCREEN_W]
        assert row[0] == row[1] == row[2]
        assert row[-1] == row[-2] == row[-3]

    # Verify palette selection for every custom code that actually occurs in
    # this room. Do not require unused SetupTileGraphics slots to appear in BAT.
    for code in sorted(used_codes - {0}):
        expected_pal = PAL_BY_C64[ROOM01_COLOURS[code-1] & 0x0f]
        samples = [w for w in bat if (w & 0x0fff) == CHR_GAME + code]
        assert samples, f'room01 used code {code} missing from BAT'
        assert all((w >> 12) == expected_pal for w in samples)

    # Code 2 is intentionally unused by the exact rm_01 tilemap.
    assert not [w for w in bat if (w & 0x0fff) == CHR_GAME + 2]

    main_asm = (ROOT/'src/main.asm').read_text()
    physics = (ROOT/'src/monty_physics.asm').read_text()
    world = (ROOT/'src/world.asm').read_text()
    assert 'call    room_load_pending' in main_asm
    assert 'room01_collision_map' in physics and 'room01_tile_properties' in physics
    assert 'cmp     #2' in world  # unsupported rooms are gated until loaded

    print('OK: exact room 01 RLE/tiles/colours/properties + 00<->01 loader wiring')


if __name__ == '__main__':
    main()
