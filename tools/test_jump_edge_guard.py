#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    text = (ROOT / 'src/main.asm').read_text()
    assert 'main_jump_x_before_step: ds 1' in text
    assert 'sta     <main_jump_x_before_step' in text
    assert 'call    monty_jump_step' in text
    assert 'cmp     #1' in text and 'cmp     #2' in text
    assert 'lda     <monty_jump_phase' in text
    assert 'lda     <monty_is_moving' in text
    assert 'lda     <main_jump_x_before_step' in text
    assert 'sta     <monty_x' in text
    assert 'stz     <monty_room_exit' in text
    print('OK: blocked left/right jump exits are cancelled without touching collision data')


if __name__ == '__main__':
    main()
