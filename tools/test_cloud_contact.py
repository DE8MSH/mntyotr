#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    main = (ROOT/'src/main.asm').read_text()
    contact = (ROOT/'src/rising_cloud_contact.asm').read_text()
    cloud = (ROOT/'src/rising_cloud.asm').read_text()

    assert 'include "rising_cloud_contact.asm"' in main
    c = main.index('call    rising_cloud_contact_update')
    u = main.index('call    rising_cloud_update')
    assert c < u

    # Landing event only: snap to cloud_y-$10 during fall/descent and arm rider.
    assert 'sbc     #$10' in contact
    assert 'sta     <rising_cloud_contact_y' in contact
    assert 'cmp     #1' in contact
    assert 'cmp     #2' in contact
    assert 'lda     <monty_falling' in contact
    assert 'cmp     #4' in contact
    assert 'cmp     #$fe' in contact
    assert 'sta     <rising_cloud_riding' in contact

    # Carry is explicit, exact and releasable. It must not depend on tile_state.
    assert 'rising_cloud_riding:    ds 1' in cloud
    assert 'lda     <rising_cloud_riding' in cloud
    assert 'lda     <monty_jump_phase' in cloud
    assert 'lda     <monty_falling' in cloud
    assert 'cmp     #$36' in cloud and 'cmp     #$49' in cloud
    assert 'sbc     #$10' in cloud
    assert 'cmp     <monty_y' in cloud
    assert 'stz     <rising_cloud_riding' in cloud
    detect = cloud[cloud.index('rising_cloud_detect_carry:'):cloud.index('rising_cloud_refresh_row:')]
    assert 'monty_tile_state' not in detect

    assert 'dec     <rising_cloud_y' in cloud
    assert 'dec     <monty_y' in cloud

    print('OK: Room01 cloud rider attaches only on landing and releases on jump/fall/edge')


if __name__ == '__main__':
    main()
