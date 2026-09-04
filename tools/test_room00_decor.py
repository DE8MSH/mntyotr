#!/usr/bin/env python3
import struct
from room_rle import ROOM00_RLE, decode_room, make_screen_bat, CHR_GAME, SCREEN_W
from room00_decor import build_patterns, overlay_screen_bat, CHR_DECOR, PAL_BY_C64


def words(blob):
    return list(struct.unpack('<' + 'H'*(len(blob)//2), blob))


def main():
    base = make_screen_bat(decode_room(ROOM00_RLE))
    decorated = overlay_screen_bat(base)
    patterns, first = build_patterns()

    assert CHR_DECOR == CHR_GAME + 9
    assert len(patterns) == 41 * 32
    assert first == {
        0: CHR_DECOR,
        1: CHR_DECOR+2,
        2: CHR_DECOR+6,
        3: CHR_DECOR+12,
        4: CHR_DECOR+21,
        5: CHR_DECOR+26,
        6: CHR_DECOR+29,
        0x43: CHR_DECOR+32,
    }

    bat = words(decorated)

    # type 4 MPL ST sign at ($03,$08), width 5, C64 white.
    for dx in range(5):
        w = bat[(0x08-3)*SCREEN_W + (0x03-2) + dx]
        assert (w >> 12) == PAL_BY_C64[0x01]
        assert (w & 0x0fff) == first[4] + dx

    # type 3 window at ($17,$08), 3x3, C64 light grey.
    for dy in range(3):
        for dx in range(3):
            w = bat[(0x08-3+dy)*SCREEN_W + (0x17-2+dx)]
            assert (w >> 12) == PAL_BY_C64[0x0f]
            assert (w & 0x0fff) == first[3] + dy*3 + dx

    # Reused type 1 pole records share the same four allocated chars.
    top_a = bat[(0x0c-3)*SCREEN_W + (0x24-2)]
    top_b = bat[(0x08-3)*SCREEN_W + (0x24-2)]
    assert top_a == top_b == ((PAL_BY_C64[0x0c] << 12) | first[1])

    # type 2 street-lamp head has exact row-major C64 colour stream:
    # 0c 0c 0c / 07 07 0c.
    lamp_expected = [0x0c,0x0c,0x0c,0x07,0x07,0x0c]
    for i,c64col in enumerate(lamp_expected):
        dy,dx = divmod(i,3)
        w = bat[(0x06-3+dy)*SCREEN_W + (0x22-2+dx)]
        assert (w >> 12) == PAL_BY_C64[c64col]
        assert (w & 0x0fff) == first[2] + i

    # type 5 yellow flower and type 6 brown flower reuse the same bitmap but
    # allocate distinct C64 char runs and have different exact colour streams.
    for type_id,x,y,stream in (
        (5,0x0e,0x0a,[0x07,0x0d,0x0a]),
        (6,0x0c,0x0c,[0x08,0x05,0x0a]),
    ):
        for i,c64col in enumerate(stream):
            w = bat[(y-3+i)*SCREEN_W + (x-2)]
            assert (w >> 12) == PAL_BY_C64[c64col]
            assert (w & 0x0fff) == first[type_id] + i

    # Final room-$00 record: type $43 sad_flowers at ($21,$0f), exact 3x3
    # colour stream 05 05 05 / 05 05 05 / 07 0a 08.
    sad_expected = [0x05,0x05,0x05,0x05,0x05,0x05,0x07,0x0a,0x08]
    for i,c64col in enumerate(sad_expected):
        dy,dx = divmod(i,3)
        w = bat[(0x0f-3+dy)*SCREEN_W + (0x21-2+dx)]
        assert (w >> 12) == PAL_BY_C64[c64col]
        assert (w & 0x0fff) == first[0x43] + i

    print('OK: complete room 00 decor records/colour streams/BAT overlay')


if __name__ == '__main__':
    main()
