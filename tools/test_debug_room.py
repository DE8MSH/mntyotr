#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT/'src/main.asm').read_text()
    debug = (ROOT/'src/debug_room.asm').read_text()
    visible = (ROOT/'src/debug_footer_visible.asm').read_text()
    cloud = (ROOT/'src/rising_cloud_sprite.asm').read_text()
    platform = (ROOT/'src/platform.inc').read_text()
    build = (ROOT/'build.sh').read_text()

    assert 'include "debug_room.asm"' in main_asm
    assert 'include "debug_footer_visible.asm"' in main_asm
    assert 'call    debug_room_init' in main_asm
    assert 'call    debug_room_draw' in main_asm
    assert 'call    debug_footer_visible_draw' in main_asm

    # Static footer/commit are startup diagnostics, not a per-frame workload.
    assert main_asm.count('call    debug_footer_visible_draw') == 1
    assert 'jmp     debug_commit_bank_safe_draw' not in cloud
    assert 'rising_cloud_sprite_sat_dma:' in cloud
    assert 'st0     #$13' in cloud
    assert 'rts' in cloud.split('rising_cloud_sprite_sat_dma:',1)[1].split('.data',1)[0]

    # Live top-row HUD: lives left, room right. Build id moved under the footer.
    assert 'DEBUG_COMMIT_BAT    = 24*BAT_LINE' in debug
    assert 'DEBUG_LIVES_BAT     = 0' in debug
    assert 'DEBUG_ROOM_LABEL_BAT= 37' in debug
    assert 'DEBUG_GLYPH_R       = 19' in debug
    assert 'DEBUG_GLYPH_L       = 24' in debug
    assert 'lda     <game_lives' in debug
    assert 'lda     <monty_room' in debug
    assert 'build_commit_nibbles:' in debug
    assert 'incbin  "build-commit.dat"' in debug
    assert 'db $0a,$10,$11,$12,$0e,$10,$13,$14,$0a,$10,$15,$0c,$0e,$10,$16,$17,$13,$11' in debug

    # Footer row23, commit row24 immediately below it. Both data sources are
    # banked and must be remapped before reading.
    assert 'DEBUG_FOOTER_VISIBLE_BAT = 23*BAT_LINE' in visible
    assert 'debug_commit_bank_safe_draw:' in visible
    assert 'ldy     #BANK(build_commit_nibbles)' in visible
    assert 'call    map_bp_to_mpr34' in visible
    assert 'lda     [_bp],y' in visible
    assert 'cpy     #7' in visible
    assert 'jmp     debug_commit_bank_safe_draw' in visible
    assert 'DEBUG_FOOTER_LEGACY_BAT' not in visible

    # build.sh converts the current short Git SHA to seven 0..15 nibble bytes.
    assert 'git -C "$ROOT" rev-parse --short=7 HEAD' in build
    assert '"$BUILD/build-commit.dat"' in build
    assert "data = bytes(int(ch, 16) for ch in text)" in build
    assert "assert len(data) == 7" in build

    assert 'CHR_FONT' in platform and 'CHR_GAME        = CHR_FONT + 112' in platform

    print('OK: live Lx/rXX HUD + static footer/commit + single SAT DMA trigger')


if __name__ == '__main__':
    main()
