#!/usr/bin/env python3
"""Compatibility view of canonical late-room enemy truth.

The whole-game truth lives in playthrough_truth.py.  Keep this tiny adapter so
older/newer audit layers can request the R10-R33 subset without duplicating any
spawn records or silently drifting from the canonical source manifest.
"""
from playthrough_truth import ENEMIES

ENEMIES_10_33 = {
    room: records
    for room, records in ENEMIES.items()
    if 0x10 <= room <= 0x33
}

assert set(ENEMIES_10_33) == set(range(0x10, 0x34))
