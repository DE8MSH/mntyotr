#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    text = (ROOT / 'src/main.asm').read_text()
    assert 'main_jump_x_before_step:   ds 1' in text
    assert 'main_exit_before_jump:     ds 1' in text
    assert 'sta     <main_exit_before_jump' in text
    assert 'call    monty_jump_step' in text
    assert 'lda     <main_exit_before_jump' in text
    assert 'sta     <monty_room_exit' in text
    assert '.guard_jump_generated_exit:' in text
    assert 'lda     <monty_jump_phase' in text
    assert 'lda     <collision_actual_room' in text
    assert 'cmp     #4' in text
    assert '.guard_room00_right:' in text
    assert 'lda     #$9b' in text and 'lda     #$15' in text
    assert text.count('stz     <monty_room_exit') >= 3
    assert 'lda     <monty_is_moving' in text
    assert 'lda     <main_jump_x_before_step' in text
    assert 'call    init_c64_video' in text
    assert 'bsr     init_c64_video' not in text
    print('OK: Room04 jump entry works; only unloaded outer edges stay blocked')


if __name__ == '__main__':
    main()
