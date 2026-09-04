#!/usr/bin/env python3
import struct
from room_rle import ROOM00_RLE, decode_room, make_screen_bat, CHR_GAME, SCREEN_W
from room00_decor import build_patterns, overlay_screen_bat, CHR_DECOR


def words(blob):
    return list(struct.unpack('<' + 'H'*(len(blob)//2), blob))


def main():
    base = make_screen_bat(decode_room(ROOM00_RLE))
    decorated = overlay_screen_bat(base)
    patterns, first = build_patterns()

    assert CHR_DECOR == CHR_GAME + 9
    assert len(patterns) == 20 * 32
    assert first == {0: CHR_DECOR, 1: CHR_DECOR+2, 3: CHR_DECOR+6, 4: CHR_DECOR+15}

    bat = words(decorated)
    # C64 room-list coordinates are converted from screen cols 2..37 / rows 3..22.
    # type 4 MPL ST sign at ($03,$08), width 5, white palette 11.
    for dx in range(5):
        w = bat[(0x08-3)*SCREEN_W + (0x03-2) + dx]
        assert (w >> 12) == 11
        assert (w & 0x0fff) == first[4] + dx

    # type 3 window at ($17,$08), 3x3, light-grey palette 10.
    for dy in range(3):
        for dx in range(3):
            w = bat[(0x08-3+dy)*SCREEN_W + (0x17-2+dx)]
            assert (w >> 12) == 10
            assert (w & 0x0fff) == first[3] + dy*3 + dx

    # Reused type 1 pole records share the same four allocated chars.
    top_a = bat[(0x0c-3)*SCREEN_W + (0x24-2)]
    top_b = bat[(0x08-3)*SCREEN_W + (0x24-2)]
    assert top_a == top_b == ((9 << 12) | first[1])

    print('OK: room 00 solid decor records/pattern allocation/BAT overlay')


if __name__ == '__main__':
    main()
