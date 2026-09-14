#!/usr/bin/env python3
"""Static/data guards for the exact C64 Room $10-$1F block."""
import re
from pathlib import Path
from rooms10_1f import RLE_HEX, ROOM_DEFS, room_data

ROOT = Path(__file__).resolve().parents[1]


def main():
    assert set(RLE_HEX) == set(range(0x10, 0x20))
    assert set(ROOM_DEFS) == set(range(0x10, 0x20))
    for room in range(0x10, 0x20):
        cells, bat, patterns, props = room_data(room)
        assert len(cells) == 640, f'R{room:02X} cells'
        assert len(bat) == 36 * 20 * 2, f'R{room:02X} BAT'
        assert len(patterns) == 9 * 32, f'R{room:02X} patterns'
        assert len(props) == 8, f'R{room:02X} props'

    # Pin a few original room definitions across the block.
    assert ROOM_DEFS[0x10][0] == (0x25,0x76,0x53,0x1e,0x00,0x68,0x3b,0x47)
    assert ROOM_DEFS[0x17][0] == (0x00,0x1e,0x6b,0x6c,0x4f,0x00,0x00,0x00)
    assert ROOM_DEFS[0x1f][0] == (0x01,0x1f,0x05,0x00,0x00,0x00,0x00,0x00)

    world = (ROOT / 'src/world.asm').read_text().lower()
    loader = (ROOT / 'src/room050c_loader.asm').read_text().lower()
    tail = (ROOT / 'src/room0f_assets_tail.asm').read_text().lower()

    # R10-R1F are still exact, but no longer the end of the supported world.
    m = re.search(r'world_room_supported:\s*\n\s*cmp\s+#\$([0-9a-f]+)', world)
    assert m and int(m.group(1), 16) == 0x34
    assert 'room_ext_count = 43' in loader
    assert 'include "room10_1f_assets_tail.asm"' in tail
    for room in range(0x10, 0x20):
        p = f'room{room:02x}'
        assert f'{p}_patterns' in loader
        assert f'{p}_screen_bat' in loader
        assert f'{p}_collision_map_rom' in loader

    print('OK: exact Room10-1F geometry/patterns/collision retained inside whole-game loader')


if __name__ == '__main__':
    main()
