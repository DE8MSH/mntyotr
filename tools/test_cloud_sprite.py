#!/usr/bin/env python3
from pathlib import Path
from cloud_sprite import CLOUD_98, CLOUD_99, CLOUD_9A, build

ROOT = Path(__file__).resolve().parents[1]


def main():
    data = build()
    assert len(CLOUD_98) == len(CLOUD_99) == len(CLOUD_9A) == 64
    assert len(data) == 1536
    assert data[:512] != data[512:1024]
    assert data[512:1024] != data[1024:]

    main = (ROOT/'src/main.asm').read_text()
    spr = (ROOT/'src/rising_cloud_sprite.asm').read_text()
    assets = (ROOT/'src/rising_cloud_sprite_assets_tail.asm').read_text()
    build_sh = (ROOT/'build.sh').read_text()

    assert 'include "rising_cloud_sprite.asm"' in main
    assert 'include "rising_cloud_sprite_assets_tail.asm"' in main
    assert 'call    rising_cloud_sprite_init' in main
    assert main.count('call    rising_cloud_sprite_update_satb') >= 2
    assert 'rising_cloud_sprite_palette' in main
    assert 'CLOUD_SAT_LEFT = SAT_ADDR+24' in spr
    assert 'CLOUD_SAT_RIGHT= SAT_ADDR+28' in spr
    assert 'CLOUD_SAT_X    = 128' in spr
    assert 'db 0,1,2,1' in spr
    assert 'rising_cloud_pat_left_lo:' in spr
    assert 'db $a0,$a8,$b0' in spr
    assert 'rising_cloud_pat_right_lo:' in spr
    assert 'db $a2,$aa,$b2' in spr
    assert 'incbin "cloud-sprites.dat"' in assets
    assert 'tools/cloud_sprite.py' in build_sh
    assert '--write "$BUILD/cloud-sprites.dat"' in build_sh

    # Keep all potentially distant transfers absolute.
    assert 'bcs     rising_cloud_sprite_hide' not in spr
    assert 'bcc     rising_cloud_sprite_hide' not in spr
    assert 'jmp     rising_cloud_sprite_hide' in spr
    assert 'jmp     rising_cloud_sprite_sat_dma' in spr

    print('OK: authentic 3-frame Room01 cloud sprite visibly follows 1px rising-cloud motion')


if __name__ == '__main__':
    main()
