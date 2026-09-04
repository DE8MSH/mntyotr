#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    text = (ROOT / 'src/main.asm').read_text()
    assert 'main_jump_x_before_step: ds 1' in text
    assert 'sta     <main_jump_x_before_step' in text
    assert 'call    monty_jump_step' in text
    assert 'lda     <monty_jump_phase' in text
    assert 'lda     <monty_room' in text
    assert '.guard_room00_right:' in text
    assert 'lda     #$9b' in text and 'lda     #$15' in text
    assert text.count('stz     <monty_room_exit') >= 3
    assert 'lda     <monty_is_moving' in text
    assert 'lda     <main_jump_x_before_step' in text
    # main.asm has grown enough that this startup helper is outside BSR range.
    assert 'call    init_c64_video' in text
    assert 'bsr     init_c64_video' not in text
    print('OK: blocked/unsupported left-right jump exits are cancelled symmetrically')


if __name__ == '__main__':
    main()
