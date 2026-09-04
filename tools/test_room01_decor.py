#!/usr/bin/env python3
import struct
from pathlib import Path
from room01 import ROOM01_RLE, make_screen_bat
from room_rle import decode_room, SCREEN_W
from room01_decor import (
    build_patterns, overlay_screen_bat, CHR_DECOR, PAL_BY_C64,
    BUNCH_COLOURS, PURPLE_COLOURS,
)

ROOT = Path(__file__).resolve().parents[1]


def words(blob):
    return list(struct.unpack('<' + 'H'*(len(blob)//2), blob))


def main():
    base = make_screen_bat(decode_room(ROOM01_RLE))
    decorated = overlay_screen_bat(base)
    patterns, first = build_patterns()

    assert len(patterns) == 25*32
    assert first == {0x42: CHR_DECOR, 0x41: CHR_DECOR+16}

    bat = words(decorated)

    # Source room_list: $01,$03,$11,$42 (purple_flowers, 4x4).
    for i,c64col in enumerate(PURPLE_COLOURS):
        dy,dx = divmod(i,4)
        w = bat[(0x11-3+dy)*SCREEN_W + (0x03-2+dx)]
        assert (w >> 12) == PAL_BY_C64[c64col]
        assert (w & 0x0fff) == first[0x42] + i

    # Source room_list: $01,$1d,$07,$41 (bunch_flower, 3x3).
    for i,c64col in enumerate(BUNCH_COLOURS):
        dy,dx = divmod(i,3)
        w = bat[(0x07-3+dy)*SCREEN_W + (0x1d-2+dx)]
        assert (w >> 12) == PAL_BY_C64[c64col]
        assert (w & 0x0fff) == first[0x41] + i

    assets = (ROOT/'src/room01_assets.asm').read_text()
    decor_assets = (ROOT/'src/room01_decor_assets.asm').read_text()
    loader = (ROOT/'src/room_loader.asm').read_text()
    decor_loader = (ROOT/'src/room01_decor_loader.asm').read_text()
    main_asm = (ROOT/'src/main.asm').read_text()
    room00_assets = (ROOT/'src/room00_assets.asm').read_text()

    # The 800-byte decor block must remain at the ROM tail. Putting it back in
    # room01_assets shifts the already-confirmed physics/collision layout.
    assert 'room01_decor_patterns:' not in assets
    assert 'incbin "room01-decor-patterns.dat"' not in assets
    assert 'room01_decor_patterns:' in decor_assets
    assert 'incbin "room01-decor-patterns.dat"' in decor_assets
    assert 'include "room01_decor_assets.asm"' in main_asm
    assert main_asm.index('include "room01_decor_assets.asm"') > main_asm.index('include "monty_sprite.asm"')

    assert 'call    room01_upload_decor' in loader
    assert 'bsr     room01_upload_decor' not in loader
    assert 'include "room01_decor_loader.asm"' in main_asm
    assert 'BANK(room01_decor_patterns)' in decor_loader
    assert 'call    map_bp_to_mpr34' in decor_loader
    # Returning to Room $00 must restore its larger shared decor VRAM area.
    assert 'call    upload_room00_patterns' in loader
    assert 'tia room00_decor_patterns,VDC_DL,1312' in room00_assets

    print('OK: exact Room 01 decor + bank-safe upload + tail asset placement + Room 00 restore')


if __name__ == '__main__':
    main()
