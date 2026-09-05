#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT/'src/main.asm').read_text()
    debug = (ROOT/'src/debug_room.asm').read_text()
    platform = (ROOT/'src/platform.inc').read_text()

    assert 'include "debug_room.asm"' in main_asm
    assert 'call    debug_room_init' in main_asm
    assert 'call    debug_room_draw' in main_asm
    assert 'DEBUG_ROOM_BAT = 38' in debug
    assert 'DEBUG_HEX_CHR  = CHR_FONT' in debug
    assert 'and     #$0f' in debug
    assert 'lda     #$70' in debug
    assert '16 glyphs * 32 bytes = 512 bytes' in debug

    # The project deliberately reserves diagnostic font VRAM below game chars.
    assert 'CHR_FONT' in platform and 'CHR_GAME        = CHR_FONT + 112' in platform

    print('OK: persistent top-right two-digit hexadecimal room debug overlay')


if __name__ == '__main__':
    main()
