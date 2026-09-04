#!/usr/bin/env python3
import struct
from room01 import ROOM01_RLE, make_screen_bat
from room_rle import decode_room, SCREEN_W
from room01_decor import (
    build_patterns, overlay_screen_bat, CHR_DECOR, PAL_BY_C64,
    BUNCH_COLOURS, PURPLE_COLOURS,
)


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

    print('OK: exact room 01 purple_flowers + bunch_flower decor overlay')


if __name__ == '__main__':
    main()
