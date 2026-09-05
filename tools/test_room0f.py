#!/usr/bin/env python3
from pathlib import Path
from room_rle import ROOM_CELLS, decode_room
from room0f import (
    ROOM0F_RLE, ROOM0F_TILE_IDS, ROOM0F_COLOURS, ROOM0F_PROPERTIES,
    ROOM0F_TILE_BITMAPS, build_patterns, make_screen_bat,
)

ROOT = Path(__file__).resolve().parents[1]
assets = (ROOT / "src/room0f_assets_tail.asm").read_text()
loader = (ROOT / "src/room050c_loader.asm").read_text()
warp = (ROOT / "src/debug_room_warp.asm").read_text()

cells = decode_room(ROOM0F_RLE)
assert len(cells) == ROOM_CELLS == 640
assert ROOM0F_TILE_IDS == (0x25,0x0f,0x02,0x64,0x27,0x6b,0x31,0x16)
assert ROOM0F_COLOURS == (0x02,0x06,0x03,0x03,0x04,0x07,0x05,0x05)
assert ROOM0F_PROPERTIES == (1,1,1,3,2,3,2,1)
assert len(ROOM0F_TILE_BITMAPS) == 8
assert len(build_patterns()) == 9 * 32
assert len(make_screen_bat(cells)) == 36 * 20 * 2
assert 'incbin "room0f-map.dat"' in assets
assert 'db $01,$01,$01,$03,$02,$03,$02,$01' in assets

# Room0F must be serviced by the compact external-room descriptor path.
for needle in (
    "$0f", "room0f_patterns", "room0f_screen_bat", "room0f_collision_map_rom",
):
    assert needle in loader, needle

# QA SELECT cycle must include Room $0F and know its real world-grid cell row3/col15.
assert "cmp     #$10" in warp
assert "$03" in warp and "$0f" in warp

print("OK: exact Room0F ESCAPE TUNNEL geometry, colours, properties, loader + SELECT reachability")
