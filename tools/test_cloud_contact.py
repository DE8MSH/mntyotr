#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main = (ROOT/'src/main.asm').read_text()
    physics = (ROOT/'src/monty_physics.asm').read_text()
    contact = (ROOT/'src/rising_cloud_contact.asm').read_text()
    cloud = (ROOT/'src/rising_cloud.asm').read_text()

    assert 'include "rising_cloud_contact.asm"' in main
    c = main.index('call    rising_cloud_contact_update')
    u = main.index('call    rising_cloud_update')
    assert c < u

    # Landing remains event-only: fall/descent snaps to cloud_y-$10.
    assert 'sbc     #$10' in contact
    assert 'sta     <rising_cloud_contact_y' in contact
    assert 'cmp     #1' in contact
    assert 'cmp     #2' in contact
    assert 'lda     <monty_falling' in contact
    assert 'cmp     #4' in contact
    assert 'cmp     #$fe' in contact
    assert 'rising_cloud_riding' not in contact

    # Critical anti-stick rule: after the generic 2x3 property scan, exact cloud
    # support is separated from monty_tile_state. It suppresses only auto-fall;
    # normal fire/jump and horizontal input continue through .after_fall.
    assert 'rising_cloud_support:    ds 1' in cloud
    assert 'rising_cloud_support_update:' in cloud
    assert 'stz     <monty_tile_state' in cloud
    input_code = physics[physics.index('monty_update_input:'):physics.index('monty_jump_step:')]
    assert 'call rising_cloud_support_update' in input_code
    assert 'lda <rising_cloud_support' in input_code
    assert input_code.index('lda <rising_cloud_support') < input_code.index('lda <monty_tile_state')
    assert 'call monty_jump_start' in input_code
    assert 'lda joynow\n        and #$80' in input_code
    assert 'lda joynow\n        and #$20' in input_code

    # No persistent rider state. Push is exact and input-state driven.
    assert 'rising_cloud_riding' not in cloud
    assert 'rising_cloud_detect_push:' in cloud
    assert 'lda     <monty_jump_phase' in cloud
    assert 'lda     <monty_falling' in cloud
    assert 'cmp     #$36' in cloud and 'cmp     #$49' in cloud
    assert 'cmp     <monty_y' in cloud

    # Ceiling/wall protection checks the complete prospective footprint without
    # relying on the ordinary 8px-aligned CheckTileAbove gate.
    assert 'rising_cloud_can_push_up:' in cloud
    guard = cloud[cloud.index('rising_cloud_can_push_up:'):cloud.index('rising_cloud_refresh_row:')]
    assert 'call    room00_get_property_xy' in guard
    assert 'cmp     #$01' in guard
    assert 'rising_cloud_probe_rows' in guard
    assert 'rising_cloud_probe_cols' in guard
    assert 'call    monty_check_tile_above' not in guard
    assert 'dec     <rising_cloud_y' in cloud
    assert 'dec     <monty_y' in cloud

    print('OK: Room01 cloud support no longer owns tile/climb state; jump/walk stay live; full-footprint ceiling guard')


if __name__ == '__main__':
    main()
