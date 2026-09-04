#!/usr/bin/env python3
"""Static guards for bank-safe Monty somersault uploads."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
text = (ROOT / 'src' / 'monty_sprite.asm').read_text()

# Somersault graphics are large enough to cross 8 KiB PCE ROM banks. Never
# regress to direct TIA from those labels; use far-pointer bank tables instead.
assert 'tia monty_sault_' not in text
assert 'monty_upload_far_512:' in text
assert 'call map_bp_to_mpr34' in text
assert 'lda [_bp],y' in text
assert text.count('BANK(monty_sault_l_') == 12
assert text.count('BANK(monty_sault_r_') == 12

# Phase 28c PCE 16x32 addressing must stay intact.
assert '(MONTY_SPR_VRAM+64)>>5' in text
assert '(MONTY_SPR_VRAM+256)>>5' not in text

print('OK: bank-safe 24-frame somersault upload; 16x32 SAT pattern layout')
