#!/usr/bin/env python3
from pathlib import Path
from lift_sprite import LIFT_SPR, build

ROOT = Path(__file__).resolve().parents[1]


def main():
    assert len(LIFT_SPR) == 128
    data = build()
    assert len(data) == 1024
    assert any(data[:512]) and any(data[512:])

    main = (ROOT/'src/main.asm').read_text()
    lift = (ROOT/'src/moving_lift.asm').read_text()
    assets = (ROOT/'src/moving_lift_assets_tail.asm').read_text()
    build_sh = (ROOT/'build.sh').read_text()

    assert 'include "moving_lift.asm"' in main
    assert 'include "moving_lift_assets_tail.asm"' in main
    assert 'call    moving_lift_init' in main
    assert 'call    moving_lift_room_sync' in main
    assert 'call    moving_lift_update' in main
    assert 'call    moving_lift_update_satb' in main
    assert 'moving_lift_palette' in main

    # Exact C64 lift configs currently relevant to the port.
    assert 'lda     #$48' in lift and 'lda     #$5b' in lift
    assert 'lda     #$80' in lift and 'lda     #$53' in lift
    assert 'lda     #$82' in lift               # two-pixel descending state
    assert 'lda     #$02' in lift               # two-pixel ascent after boarding type1
    assert 'lda     #$88' in lift               # type1 fast descent after reaching top
    assert 'adc     #$17' in lift               # Monty ride Y = lift Y + $17
    assert 'cmp     #$b0' in lift               # bottom threshold
    assert 'cmp     #$62' in lift               # top threshold

    # Lift has its own SAT entries after Monty's two sprites and own VRAM block.
    assert 'LIFT_SAT_TL   = SAT_ADDR+8' in lift
    assert 'LIFT_SAT_BR   = SAT_ADDR+20' in lift
    assert 'LIFT_SPR_VRAM = $3200' in lift
    assert 'incbin "lift-sprites.dat"' in assets

    # The build must actually generate the file consumed by the tail asset.
    assert 'tools/lift_sprite.py' in build_sh
    assert '--write "$BUILD/lift-sprites.dat"' in build_sh

    print('OK: authentic Room05/0D moving lifts + 2-sprite C64 lift art build wiring')


if __name__ == '__main__':
    main()
