#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT/'src/main.asm').read_text()
    world = (ROOT/'src/world.asm').read_text()
    edge = (ROOT/'src/vertical_world_edges.asm').read_text()

    assert 'include "vertical_world_edges.asm"' in main_asm
    assert 'main_y_before_step:        ds 1' in main_asm
    assert 'sta     <main_y_before_step' in main_asm
    assert 'cmp     <main_y_before_step' in main_asm
    assert 'bcc     .after_down_room_edge' in main_asm
    assert 'beq     .after_down_room_edge' in main_asm
    assert 'call    monty_check_down_room_edge' in main_asm
    assert 'cmp     #$da' in edge
    assert 'lda     #4' in edge and 'sta     <monty_room_exit' in edge
    assert 'lda     #$4c' in edge and 'sta     <monty_y' in edge

    compact = ''.join(world.lower().split())
    # Exact C64 rows retain all route topology independently of comments.
    assert 'db$ff,$2f,$2e,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$22,$ff,$ff,$ff,$ff,$ff,$ff,$06,$07,$08,$09,$ff,$ff' in compact
    assert 'db$2d,$2c,$27,$26,$33,$32,$31,$25,$24,$20,$21,$ff,$ff,$ff,$ff,$ff,$05,$04,$03,$02,$01,$00,$ff' in compact
    assert 'db$2b,$2a,$28,$29,$ff,$ff,$ff,$ff,$ff,$1f,$ff,$ff,$1b,$ff,$ff,$0f,$0c,$0d,$0e,$0b,$0a,$ff,$ff' in compact
    for room in ('$09','$0a','$0b','$0c','$0d','$0e'):
        assert f'cmp#{room}' in compact
    assert 'cmp#6' in compact
    assert 'world_room_supported:' in world

    print('OK: vertical exits require actual downward motion + exact supported $01<->$09 and lower routes')


if __name__ == '__main__':
    main()
