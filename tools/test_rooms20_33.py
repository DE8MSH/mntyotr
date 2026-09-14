#!/usr/bin/env python3
"""Static/data guards for exact C64 Rooms $20-$33."""
from pathlib import Path
from rooms20_33 import RLE_HEX, ROOM_DEFS, decode_exact, room_data

ROOT = Path(__file__).resolve().parents[1]


def raw_count(room: int) -> int:
    stream = bytes.fromhex(RLE_HEX[room])
    out = 0
    i = 0
    while i < len(stream):
        if i + 1 < len(stream) and stream[i] == 0xff and stream[i+1] == 0xff:
            break
        b = stream[i]
        i += 1
        out += (b >> 4) + 1
    return out


def main() -> None:
    rooms = set(range(0x20, 0x34))
    assert set(RLE_HEX) == rooms
    assert set(ROOM_DEFS) == rooms
    for room in sorted(rooms):
        cells, bat, patterns, props = room_data(room)
        assert len(cells) == 640, f'R{room:02X} cells'
        assert len(bat) == 36 * 20 * 2, f'R{room:02X} BAT'
        assert len(patterns) == 9 * 32, f'R{room:02X} patterns'
        assert len(props) == 8, f'R{room:02X} props'

    # Original completion room is deliberately short and padded only for PCE RAM.
    assert raw_count(0x30) == 624
    assert len(decode_exact(0x30)) == 640
    assert decode_exact(0x30)[624:] == [0] * 16

    # Pin definitions across Tree Stump, DAS BOAT and C5 transit areas.
    assert ROOM_DEFS[0x20][0] == (0x05,0x33,0x2a,0,0,0,0,0)
    assert ROOM_DEFS[0x2a][0] == (0x03,0x6b,0x6c,0x3b,0x73,0x71,0x4f,0)
    assert ROOM_DEFS[0x33][0] == (0x5b,0x56,0,0,0,0,0,0)

    world = (ROOT / 'src/world.asm').read_text().lower()
    loader = (ROOT / 'src/room050c_loader.asm').read_text().lower()
    tail10 = (ROOT / 'src/room10_1f_assets_tail.asm').read_text().lower()
    tail = (ROOT / 'src/room20_33_assets_tail.asm').read_text().lower()
    assert 'cmp     #$34' in world
    assert 'room_ext_count = 43' in loader
    assert 'include "room20_33_assets_tail.asm"' in tail10
    for room in range(0x20, 0x34):
        p = f'room{room:02x}'
        assert f'{p}_patterns' in loader
        assert f'{p}_screen_bat' in loader
        assert f'{p}_collision_map_rom' in loader
        assert f'{p}_patterns:' in tail
        assert f'{p}_tile_properties_rom:' in tail

    print('OK: exact Room20-33 geometry, patterns, collision and banked loader wiring')


if __name__ == '__main__':
    main()
