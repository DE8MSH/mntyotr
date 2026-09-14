#!/usr/bin/env python3
"""Canonical cheat/Easter-egg truth for the Monty headless audit.

These entries are deliberately separate from normal-play truth. Missing cheat
content must never make an otherwise correct normal room WARN/MISSING/FAIL.

Original C64 behaviour (Dave-Agent refactor):
- Hi-score trigger 22, "I WANT TO CHEAT", sets cheat_mode=$01 for the next game.
- While cheat_mode != 0, the otherwise hidden cake (#19) spawns in Room $01 at
  sprite X=$6A, Y=$D2 (frame base $31 / sprite pointer $BF).
- Collecting that cake ORs $81 into cheat_mode. With bit 7 set, ordinary death
  events are suppressed (completion/special event dispatch still runs).
- Piledriver SeedGlyphs selects the alternate +$18 glyph set while bit 7 is set.
- C5DriveMovement skips its normal lethal tile guard while bit 7 is set.
"""
from __future__ import annotations

CHEAT_ACTIVATION_PHRASE = "I WANT TO CHEAT"
CHEAT_SPECIAL = (19, 0x01, 0x6A, 0xD2, 0x31, "cake / invincibility")

# Unique rooms containing the game's 10 piledriver instances.  Cheat mode does
# not add extra piledrivers; it changes their glyph set after the cake is taken.
CHEAT_PILEDRIVER_ROOMS = (0x01, 0x02, 0x06, 0x0B, 0x13, 0x19, 0x1B, 0x28)
CHEAT_PILEDRIVER_INSTANCE_COUNT = 10

# The C5 movement subsystem is active in these two transit rooms.  With
# cheat_mode bit 7 set its normal type-2 lethal tile check is bypassed.
CHEAT_C5_ROOMS = (0x24, 0x33)

# Human-readable feature catalogue.  ``rooms`` empty means global game state.
CHEAT_FEATURES = (
    {
        "id": "hiscore-cheat-trigger",
        "rooms": (),
        "stage": "activation",
        "description": 'Hi-score name "I WANT TO CHEAT" enables cheat mode for the next game',
    },
    {
        "id": "room01-secret-cake",
        "rooms": (0x01,),
        "stage": "activation",
        "description": "R01 secret cake #19 appears only while cheat mode is enabled",
    },
    {
        "id": "cake-invincibility",
        "rooms": (),
        "stage": "after-cake",
        "description": "collecting the secret cake sets cheat bit 7 and suppresses ordinary deaths",
    },
    {
        "id": "alternate-piledriver-glyphs",
        "rooms": CHEAT_PILEDRIVER_ROOMS,
        "stage": "after-cake",
        "description": "all 10 piledrivers use their alternate Easter-egg glyph frame",
    },
    {
        "id": "c5-lethal-tile-bypass",
        "rooms": CHEAT_C5_ROOMS,
        "stage": "after-cake",
        "description": "C5 movement bypasses the normal lethal type-2 tile guard",
    },
)
