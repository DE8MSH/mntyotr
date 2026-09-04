#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT/'src/main.asm').read_text()
    world = (ROOT/'src/world.asm').read_text()
    edge = (ROOT/'src/vertical_world_edges.asm').read_text()

    assert 'include "vertical_world_edges.asm"' in main_asm
    assert 'call    monty_check_down_room_edge' in main_asm
    assert 'cmp     #$da' in edge
    assert 'lda     #4' in edge and 'sta     <monty_room_exit' in edge
    assert 'lda     #$4c' in edge and 'sta     <monty_y' in edge

    # Exact world-grid route around the wall in room $03:
    # row2 col18=$03; down row3 col18=$0E; left col17=$0D; up row2 col17=$04.
    compact = ''.join(world.lower().split())
    assert 'db$2b,$2a,$28,$29,$ff,$ff,$ff,$ff,$ff,$1f,$ff,$ff,$1b,$ff,$ff,$0f,$0c,$0d,$0e,$0b,$0a,$ff,$ff' in compact
    assert 'cmp#$0d' in compact and 'cmp#$0e' in compact
    assert 'world_room_supported:' in world

    print('OK: downward edge + supported $03->$0E->$0D->$04 world route')


if __name__ == '__main__':
    main()
