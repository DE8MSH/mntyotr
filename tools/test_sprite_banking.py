#!/usr/bin/env python3
"""Static guards for bank-safe sprite uploads and 16x32 SAT layout."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / 'src' / 'monty_sprite.asm').read_text()
life = (ROOT / 'src' / 'game_life.asm').read_text()
special = (ROOT / 'src' / 'special_item_sprite.asm').read_text()

# All sprite frame families can move across 8 KiB HuCard banks as room/decor
# data grows. Never regress to direct TIA from any Monty frame label.
assert 'tia monty_sault_' not in text
assert 'tia monty_walk_' not in text
assert 'tia monty_climb_' not in text
assert '.proc monty_upload_far_512' in text
assert 'call map_bp_to_mpr34' in text
assert 'lda [_bp],y' in text
assert text.count('BANK(monty_sault_l_') == 12
assert text.count('BANK(monty_sault_r_') == 12
assert text.count('BANK(monty_walk_l_') == 4
assert text.count('BANK(monty_walk_r_') == 4
assert text.count('BANK(monty_climb_') == 4

# The whole sprite runtime must stay relocatable. The complete game already
# fills fixed HOME heavily; --newproc should place these bodies in ordinary
# ROM banks and leave only far-call thunks in Bank 0.
for proc in (
    'monty_sprite_init',
    'monty_upload_walk_frame',
    'monty_upload_climb_frame',
    'monty_upload_jump_frame',
    'monty_upload_far_512',
    'monty_sprite_animate',
    'monty_sprite_update_satb',
):
    assert f'.proc {proc}' in text

# A life reload must restart the animation sequencer. In particular, a fatal
# frame must not leave monty_anim_timer at a wrapped/stale value that makes the
# next walking animation appear frozen after repeated deaths.
reload_block = life.split('.proc game_life_reload', 1)[1].split('.endp', 1)[0]
assert 'stz     <monty_anim_frame' in reload_block
assert 'lda     #4' in reload_block and 'sta     <monty_anim_timer' in reload_block
assert 'sta     <monty_sprite_last_facing' in reload_block
assert 'sta     <monty_sprite_last_mode' in reload_block
assert 'sta     <monty_sprite_dirty' in reload_block
assert 'call    monty_upload_walk_frame' in reload_block
restore_block = life.split('.restore:', 1)[1].split('.proc game_life_reload', 1)[0]
assert 'stz     <monty_is_moving' in restore_block

# PCE 16x32 addressing: converted 24x21 frames are TL,TR,BL,BR in one aligned
# 32x32 group. One SAT entry per LEFT/RIGHT half lets VDC fetch top+bottom.
assert '(MONTY_SPR_VRAM+64)>>5' in text
assert '(MONTY_SPR_VRAM+256)>>5' not in text

# Special items use the exact same frame layout. The former four-SAT renderer
# explicitly placed TL/TR and BL/BR while every entry was itself 16x32; that
# produced two vertically stacked copies (e.g. the R0A cupcake). Keep only two
# SAT entries at one Y coordinate and select the right half with +$40.
assert 'SPECIAL_ITEM_SAT_LEFT  = SAT_ADDR+64' in special
assert 'SPECIAL_ITEM_SAT_RIGHT = SAT_ADDR+68' in special
assert 'SPECIAL_ITEM_SAT_BL' not in special
assert 'SPECIAL_ITEM_SAT_BR' not in special
assert '((SPECIAL_ITEM_VRAM+$40)>>5)' in special
assert 'SPECIAL_ITEM_VRAM+$80' not in special
assert 'SPECIAL_ITEM_VRAM+$c0' not in special
assert 'ldx #2' in special
assert 'adc #30' not in special

# Original C64 Monty sprite colour is $0F light grey. The shared C64->PCE
# quantization maps that colour to raw PCE CRAM word $16D, not white $1FF.
assert 'dw $000,$16d,$000' in text.lower()
assert 'dw $000,$1ff,$000' not in text.lower()

print('OK: banked sprite runtime + death-safe Monty animation + two-half special items')