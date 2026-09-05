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

    compact = ''.join(world.lower().split())
    # Exact C64 lower-house row: ... $0F,$0C,$0D,$0E,$0B,$0A beneath
    # the main row containing ... $05,$04,$03,$02,$01,$00.
    assert 'db$2b,$2a,$28,$29,$ff,$ff,$ff,$ff,$ff,$1f,$ff,$ff,$1b,$ff,$ff,$0f,$0c,$0d,$0e,$0b,$0a,$ff,$ff' in compact
    for room in ('$0a','$0b','$0c','$0d','$0e'):
        assert f'cmp#{room}' in compact
    assert 'cmp#6' in compact
    assert 'world_room_supported:' in world

    # Confirmed lower chain plus Phase-46 continuation:
    # $01 down->$0A left->$0B left->$0E left->$0D up->$04 left->$05 down->$0C.
    assert '$01->$0a' in main_asm.lower()
    assert '$02->$0b' in main_asm.lower()
    assert '$05->$0c' in main_asm.lower()

    print('OK: downward edge + supported lower route through $04->$05->$0C')


if __name__ == '__main__':
    main()
