#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main_asm = (ROOT/'src/main.asm').read_text()
    loader = (ROOT/'src/room_loader.asm').read_text()
    decor_loader = (ROOT/'src/room01_decor_loader.asm').read_text()
    physics = (ROOT/'src/monty_physics.asm').read_text()
    assets = (ROOT/'src/room01_assets.asm').read_text()

    # Phase 34 must keep decor code isolated from the known-good Phase-32b
    # physics/collision path. The failed RAM collision experiment must stay out.
    assert 'room_collision_map_ram' not in physics
    assert '#<room00_collision_map' in physics
    assert '#<room01_collision_map' in physics

    assert 'include "room01_decor_loader.asm"' in main_asm
    assert 'call    room01_upload_decor' in loader
    assert 'call    room01_upload_patterns' in loader
    assert 'call    room01_draw_native' in loader
    assert 'bsr     room01_' not in loader

    assert 'room01_decor_patterns:' in assets
    assert 'incbin "room01-decor-patterns.dat"' in assets
    assert 'BANK(room01_decor_patterns)' in decor_loader
    assert 'call    map_bp_to_mpr34' in decor_loader
    assert 'room_collision' not in decor_loader

    print('OK: room01 decor isolated; Phase-32b physics/collision path preserved')


if __name__ == '__main__':
    main()
