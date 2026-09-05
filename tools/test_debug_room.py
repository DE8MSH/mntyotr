#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT/'src/main.asm').read_text()
    debug = (ROOT/'src/debug_room.asm').read_text()
    platform = (ROOT/'src/platform.inc').read_text()
    build = (ROOT/'build.sh').read_text()

    assert 'include "debug_room.asm"' in main_asm
    assert 'call    debug_room_init' in main_asm
    assert 'call    debug_room_draw' in main_asm

    assert 'DEBUG_COMMIT_BAT = 0' in debug
    assert 'DEBUG_ROOM_BAT   = 38' in debug
    assert 'DEBUG_FOOTER_BAT = 27*BAT_LINE' in debug
    assert 'DEBUG_HEX_CHR    = CHR_FONT' in debug
    assert 'build_commit_nibbles:' in debug
    assert 'incbin  "build-commit.dat"' in debug
    assert 'cpx     #7' in debug
    assert 'and     #$0f' in debug
    assert 'cpx     #18' in debug
    assert 'db $0a,$10,$11,$12,$0e,$10,$13,$14,$0a,$10,$15,$0c,$0e,$10,$16,$17,$13,$11' in debug
    assert '32 glyphs * 32 bytes = 1024 bytes' in debug
    assert 'ldx     #4' in debug
    assert 'lda     #$70' in debug

    # build.sh converts the current short Git SHA to seven 0..15 nibble bytes.
    assert 'git -C "$ROOT" rev-parse --short=7 HEAD' in build
    assert '"$BUILD/build-commit.dat"' in build
    assert "data = bytes(int(ch, 16) for ch in text)" in build
    assert "assert len(data) == 7" in build

    # The project deliberately reserves diagnostic font VRAM below game chars.
    assert 'CHR_FONT' in platform and 'CHR_GAME        = CHR_FONT + 112' in platform

    print('OK: commit top-left + room top-right + A thE rZA PCE port footer overlay')


if __name__ == '__main__':
    main()
