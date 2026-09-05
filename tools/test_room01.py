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


def classify(tile):
    if 0x47 <= tile < 0x4e:
        return 1
    if tile < 0x27:
        return 1
    if tile < 0x47:
        return 2
    if tile < 0x56:
        return 4
    if tile < 0x77:
        return 3
    return 0


def main():
    cells = decode_room(ROOM01_RLE)
    assert len(cells) == ROOM_CELLS == 640
    assert ROOM01_TILE_IDS == (0x02,0x63,0x01,0x0a,0x40,0x05,0x55,0x64)
    assert ROOM01_COLOURS == (0x04,0x03,0x03,0x05,0x01,0x0a,0x06,0x05)
    assert ROOM01_PROPERTIES == (1,3,1,1,2,1,4,3)
    assert ROOM01_PROPERTIES == tuple(classify(tile) for tile in ROOM01_TILE_IDS)

    assert classify(0x63) == classify(0x64) == 3
    assert 8 in cells

    used_codes = set(cells)
    assert used_codes == {0,1,3,4,5,6,7,8}

    patterns = build_patterns()
    assert len(patterns) == 9*32
    assert patterns[:32] == bytes(32)

    bat = words(make_screen_bat(cells))
    assert len(bat) == SCREEN_W*20
    for y in range(20):
        row = bat[y*SCREEN_W:(y+1)*SCREEN_W]
        assert row[0] == row[1] == row[2]
        assert row[-1] == row[-2] == row[-3]

    for code in sorted(used_codes - {0}):
        expected_pal = PAL_BY_C64[ROOM01_COLOURS[code-1] & 0x0f]
        samples = [w for w in bat if (w & 0x0fff) == CHR_GAME + code]
        assert samples, f'room01 used code {code} missing from BAT'
        assert all((w >> 12) == expected_pal for w in samples)

    assert not [w for w in bat if (w & 0x0fff) == CHR_GAME + 2]

    main_asm = (ROOT/'src/main.asm').read_text()
    ext = (ROOT/'src/room050c_loader.asm').read_text()
    physics = (ROOT/'src/monty_physics.asm').read_text()
    assets = (ROOT/'src/room01_assets.asm').read_text()
    assert 'call    room_load_pending_extended' in main_asm
    assert '.proc room_load_pending_extended' in ext
    assert 'call    room_load_pending' in ext and 'leave' in ext
    assert 'room01_collision_map' in physics and 'room01_tile_properties' in physics
    assert 'db $01,$03,$01,$01,$02,$01,$04,$03' in assets

    print('OK: exact room 01 RLE/tiles/colours + corrected C64 climb properties')


if __name__ == '__main__':
    main()
