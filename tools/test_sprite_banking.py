#!/usr/bin/env python3
"""Static guards for bank-safe Monty sprite uploads."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / 'src' / 'monty_sprite.asm').read_text()

# All sprite frame families can move across 8 KiB HuCard banks as room/decor
# data grows. Never regress to direct TIA from any Monty frame label.
assert 'tia monty_sault_' not in text
assert 'tia monty_walk_' not in text
assert 'tia monty_climb_' not in text
assert 'monty_upload_far_512:' in text
assert 'call map_bp_to_mpr34' in text
assert 'lda [_bp],y' in text
assert text.count('BANK(monty_sault_l_') == 12
assert text.count('BANK(monty_sault_r_') == 12
assert text.count('BANK(monty_walk_l_') == 4
assert text.count('BANK(monty_walk_r_') == 4
assert text.count('BANK(monty_climb_') == 4

# Phase 28c PCE 16x32 addressing must stay intact.
assert '(MONTY_SPR_VRAM+64)>>5' in text
assert '(MONTY_SPR_VRAM+256)>>5' not in text

# Original C64 Monty sprite colour is $0F light grey. The shared C64->PCE
# quantization maps that colour to raw PCE CRAM word $16D, not white $1FF.
assert 'dw $000,$16d,$000' in text.lower()
assert 'dw $000,$1ff,$000' not in text.lower()

print('OK: bank-safe Monty sprites + authentic light-grey palette; 16x32 SAT pattern layout')
