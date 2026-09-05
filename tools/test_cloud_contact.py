#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main = (ROOT/'src/main.asm').read_text()
    physics = (ROOT/'src/monty_physics.asm').read_text()
    contact = (ROOT/'src/rising_cloud_contact.asm').read_text()
    cloud = (ROOT/'src/rising_cloud.asm').read_text()

    assert 'include "rising_cloud_contact.asm"' in main
    assert 'call    rising_cloud_contact_update' in main
    assert 'call    rising_cloud_update' in main

    # PCE landing adaptation remains one-way/descent-only. It must never be an
    # upward carry path.
    assert 'sbc     #$10' in contact
    assert 'cmp     #1' in contact
    assert 'cmp     #2' in contact
    assert 'lda     <monty_falling' in contact
    assert 'dec     <monty_y' not in contact

    # Exact C64 Room01 head-block result above the cloud route: at this X range
    # CheckTileAbove sees property-1 row 0 and cannot pass Y=$52. If the generic
    # PCE edge path already synthesized UP exit 3, cancel it and restore Y=$52.
    assert 'cmp     #$36' in contact and 'cmp     #$49' in contact
    assert 'lda     <monty_room_exit' in contact
    assert 'cmp     #3' in contact
    assert 'lda     #$52' in contact
    assert 'sta     <monty_y' in contact
    assert 'stz     <monty_room_exit' in contact
    assert 'lda     #2' in contact and 'sta     <monty_jump_phase' in contact

    # Anti-stick adaptation: exact support is separated from property-3 climb
    # semantics while normal jump/left/right input remains in the common path.
    assert 'rising_cloud_support:   ds 1' in cloud
    assert 'rising_cloud_support_update:' in cloud
    assert 'stz     <monty_tile_state' in cloud
    input_code = physics[physics.index('monty_update_input:'):physics.index('monty_jump_step:')]
    assert 'call rising_cloud_support_update' in input_code
    assert 'lda <rising_cloud_support' in input_code
    assert 'call monty_jump_start' in input_code
    assert 'lda joynow\n        and #$80' in input_code
    assert 'lda joynow\n        and #$20' in input_code

    # Original C64 UpdateRisingCloud semantics: odd ticks move ONLY the cloud Y;
    # no routine in rising_cloud.asm may write Monty's Y or synthesize an UP exit.
    update = cloud[cloud.index('rising_cloud_update:'):cloud.index('rising_cloud_refresh_row:')]
    assert 'inc     <rising_cloud_tick' in update
    assert 'and     #1' in update
    assert 'dec     <rising_cloud_y' in update
    assert 'monty_y' not in update
    assert 'monty_room_exit' not in update
    assert 'rising_cloud_detect_push' not in cloud
    assert 'rising_cloud_can_push_up' not in cloud
    assert 'rising_cloud_push' not in cloud
    assert 'dec     <monty_y' not in cloud

    # Dynamic code-8/property-3 strip remains present, matching the source cloud.
    assert 'CLOUD_VIS_COL       = 12' in cloud
    assert 'CLOUD_CODE          = 8' in cloud
    assert 'ldy     #8' in cloud
    assert cloud.count('sta     [_di],y') >= 6

    print('OK: Room01 cloud matches C64 update; exact Y=$52 ceiling cancels stray UP exit')


if __name__ == '__main__':
    main()
