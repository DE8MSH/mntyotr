#!/usr/bin/env python3
"""Canonical Monty on the Run room truth used by the headless playthrough audit.

This is deliberately independent of the PCE runtime tables. Values are copied from
Dave-Agent/monty-on-the-run refactored source:
  Room.Data.enemy_spawn, FreedomKit.Data.item_tbl,
  SpecialItems.Data.si_spawn_tbl and Mechanisms.Data.

Keeping the truth separate from the generated PCE tables lets the audit detect a
bad conversion instead of merely checking a table against itself.
"""
from __future__ import annotations

FF = 0xFF

WORLD_GRID = (
    (FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,0x23,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF,FF),
    (FF,0x2F,0x2E,FF,FF,FF,FF,FF,FF,FF,0x22,FF,FF,FF,FF,FF,FF,0x06,0x07,0x08,0x09,FF,FF),
    (0x2D,0x2C,0x27,0x26,0x33,0x32,0x31,0x25,0x24,0x20,0x21,FF,FF,FF,FF,FF,0x05,0x04,0x03,0x02,0x01,0x00,FF),
    (0x2B,0x2A,0x28,0x29,FF,FF,FF,FF,FF,0x1F,FF,FF,0x1B,FF,FF,0x0F,0x0C,0x0D,0x0E,0x0B,0x0A,FF,FF),
    (FF,FF,FF,FF,FF,FF,FF,FF,FF,0x1E,FF,0x1A,0x19,0x18,FF,0x10,0x11,FF,FF,FF,FF,FF,FF),
    (FF,FF,FF,FF,FF,FF,FF,FF,FF,0x1D,0x1C,0x17,0x16,0x15,0x14,0x12,0x13,FF,FF,FF,FF,FF,FF),
)

# (room, col, row) from FreedomKit.Data.item_tbl. These are the authoritative
# logical placements; the PCE audit independently applies the conversion formula.
GEMS = (
    (0x00,0x0e,0x09),(0x01,0x1d,0x06),(0x01,0x0d,0x0c),(0x01,0x06,0x12),
    (0x02,0x1c,0x05),(0x02,0x0b,0x07),(0x03,0x05,0x11),(0x03,0x05,0x07),
    (0x04,0x13,0x05),(0x05,0x12,0x03),(0x05,0x07,0x05),(0x06,0x08,0x06),
    (0x06,0x11,0x0c),(0x08,0x12,0x04),(0x0a,0x05,0x04),(0x0a,0x12,0x11),
    (0x0d,0x0b,0x0e),(0x0e,0x1a,0x0c),(0x0f,0x02,0x04),(0x0f,0x15,0x04),
    (0x11,0x17,0x04),(0x11,0x17,0x0e),(0x12,0x1c,0x08),(0x12,0x17,0x0f),
    (0x12,0x0e,0x07),(0x13,0x13,0x0c),(0x13,0x0c,0x11),(0x14,0x18,0x08),
    (0x15,0x0b,0x04),(0x15,0x13,0x08),(0x15,0x0e,0x0b),(0x16,0x0b,0x09),
    (0x16,0x1a,0x0b),(0x17,0x14,0x10),(0x18,0x03,0x01),(0x18,0x03,0x10),
    (0x19,0x08,0x11),(0x1a,0x11,0x09),(0x1b,0x03,0x08),(0x1b,0x02,0x0e),
    (0x1b,0x17,0x05),(0x1c,0x0b,0x0e),(0x1d,0x19,0x04),(0x1d,0x14,0x09),
    (0x1d,0x03,0x0b),(0x1e,0x1d,0x0a),(0x1e,0x1c,0x03),(0x1e,0x0d,0x0a),
    (0x1f,0x0a,0x10),(0x1f,0x0f,0x0e),(0x20,0x08,0x10),(0x21,0x1a,0x12),
    (0x22,0x0a,0x08),(0x22,0x0b,0x0f),(0x26,0x0a,0x0e),(0x27,0x03,0x0e),
    (0x28,0x1c,0x0c),(0x29,0x0d,0x02),(0x2a,0x09,0x08),(0x2a,0x10,0x0a),
    (0x2c,0x04,0x03),(0x2c,0x18,0x0a),(0x2d,0x1e,0x0b),(0x2e,0x08,0x0c),
)


def _records(text: str) -> tuple[tuple[int, ...], ...]:
    text = text.strip()
    if not text:
        return ()
    return tuple(tuple(int(v, 16) for v in rec.split()) for rec in text.split("|"))


# 7-byte records: colour_idx, x_grid, y_grid, dir_idx, type_id, speed, range.
# All 52 rooms are listed, including rooms with one record and the off-grid R30.
ENEMIES = {
    0x00:_records("05 b8 8f 04 19 02 25|03 78 37 03 09 03 13"),
    0x01:_records("06 28 27 02 0f 02 2c|07 28 77 04 09 04 11|05 58 57 02 18 01 2d"),
    0x02:_records("05 b0 a7 04 0e 03 27|07 68 27 03 14 02 3c|06 a8 57 02 09 01 1f|05 28 67 03 19 04 0e"),
    0x03:_records("07 70 2f 03 1b 02 1a|06 58 2f 01 0a 01 20|05 60 97 02 0e 02 48|03 30 a7 04 1d 01 20"),
    0x04:_records("05 48 47 02 18 03 20|0e 88 9f 04 0e 04 16|06 ff 5f 04 0b 02 17|04 70 77 01 15 01 30"),
    0x05:_records("05 70 67 02 18 02 24|07 40 2f 03 14 03 20|02 3e 97 01 1d 01 20|06 c8 2f 03 16 02 20"),
    0x06:_records("06 48 2f 02 1c 04 10|05 70 9f 04 19 03 26|07 e8 a7 04 11 01 27"),
    0x07:_records("02 28 2f 03 15 02 17|05 a0 9f 04 15 03 1a|03 40 9f 04 15 01 27|04 f0 a7 04 15 02 24"),
    0x08:_records("06 58 2f 02 0a 02 27|05 a8 2f 03 13 02 27|07 30 8f 04 13 03 1d|05 a8 9f 01 15 02 80"),
    0x09:_records("07 60 97 02 12 01 78|05 50 2f 03 16 02 23|03 60 2b 01 08 03 23"),
    0x0a:_records("05 88 9f 04 14 01 3f|06 d0 5f 01 0f 02 2c|04 40 9f 04 19 03 15|07 50 5f 03 12 02 20"),
    0x0b:_records("07 28 7f 03 19 01 1f|05 a0 2f 03 16 02 2b"),
    0x0c:_records("05 70 38 03 1b 03 17|03 50 2c 01 08 02 23|06 e0 57 03 1d 01 1f|08 80 6f 02 1e 02 24"),
    0x0d:_records("05 20 47 03 15 01 2f|06 88 77 04 14 02 1b"),
    0x0e:_records("06 80 27 01 1e 04 21|0f b0 8f 01 0a 02 3a|04 58 77 04 1b 02 27"),
    0x0f:_records("06 98 2f 03 15 03 17|05 d0 77 04 1b 02 23|0a c8 2f 01 0f 02 47|0e 08 97 02 0f 01 9c"),
    0x10:_records("0d d8 37 03 19 02 1e|05 48 67 01 18 01 26|06 28 2f 02 18 02 4f"),
    0x11:_records("0c 78 6f 03 15 02 1b|06 a8 8e 01 13 02 4e|07 30 37 03 1b 01 27|05 c0 2f 01 1d 01 27"),
    0x12:_records("05 f2 57 04 09 01 27|0f 60 9f 01 15 01 3f"),
    0x13:_records("06 00 67 04 1a 02 1d|03 60 2f 01 0f 02 27|07 90 7f 03 0b 01 1f"),
    0x14:_records("0a 08 97 04 0b 05 14|06 90 97 04 1d 02 33|08 80 2f 03 11 03 22"),
    0x15:_records("06 40 67 02 0a 01 1d|05 70 77 04 15 01 1f|04 58 2f 02 15 02 21|0d 30 2f 03 15 04 14"),
    0x16:_records("0e 40 2f 01 0f 02 1f|0e a0 2f 02 0f 02 1f|07 b8 87 01 10 02 1f|06 a0 5f 02 1c 02 2f"),
    0x17:_records("07 80 37 03 19 03 12|03 90 34 01 08 02 2b|05 10 8f 04 15 02 1f|0c d8 6f 04 09 04 0e"),
    0x18:_records("06 70 a7 04 12 03 2d|05 a0 a7 01 12 02 3f|07 e0 5f 01 09 03 41|03 c0 27 01 1d 02 37"),
    0x19:_records("06 88 6f 02 1c 02 24|03 70 47 03 19 02 1f|07 38 4f 03 0c 03 12|06 70 9f 00 14 01 01"),
    0x1a:_records("03 50 6f 04 1b 03 24|07 68 6c 02 08 01 27|06 c8 5f 03 19 02 1f|0d d8 9f 04 0b 03 16"),
    0x1b:_records("07 60 2f 02 18 04 1e|05 70 2f 03 15 02 27|06 98 4f 03 16 01 2f|03 08 57 02 0e 01 47"),
    0x1c:_records("05 98 a7 01 0a 06 0e|04 c0 4f 03 0c 02 1f|02 60 47 03 16 01 27"),
    0x1d:_records("02 c0 27 01 0f 02 2a|06 40 97 02 0a 02 43|05 d0 6f 04 15 02 19"),
    0x1e:_records("03 60 67 02 0e 01 1f|05 98 47 02 0c 02 1f|04 18 8f 02 0c 03 2d|06 b0 87 04 0c 02 13"),
    0x1f:_records("07 80 5f 02 17 02 31|06 50 6f 03 1b 02 35|04 28 77 03 1d 01 2e|05 a8 97 01 0c 02 22"),
    0x20:_records("06 70 3f 04 14 01 22|05 e8 57 01 0a 03 30|04 40 4f 03 0b 02 21|07 80 67 03 18 01 1f"),
    0x21:_records("03 60 5f 03 0e 02 1f|06 50 af 01 15 01 37|05 10 5f 02 15 02 2f|0c 18 8f 03 13 02 2f"),
    0x22:_records("07 50 3f 03 14 01 17|05 80 5f 02 0f 01 1f|03 90 5f 03 0e 03 2f"),
    0x23:_records("0e 00 80 02 20 01 d0|0e 10 80 02 21 01 d0|0e 20 80 02 22 01 d0|06 28 27 02 09 02 0f"),
    0x24:_records("05 40 7f 03 0d 01 20|03 90 af 04 13 02 18"),
    0x25:_records("05 50 87 03 0e 01 18|04 70 7f 03 13 02 13"),
    0x26:_records("07 88 27 03 1b 03 21|06 98 27 03 13 01 17|05 58 47 03 19 02 17|04 40 47 03 0b 01 1f"),
    0x27:_records("0e 78 8f 04 1d 04 25|07 28 47 03 13 02 0f|06 d8 87 04 19 02 1f"),
    0x28:_records("01 c0 87 04 1b 02 1b|0d 18 a7 04 0e 02 1f|08 08 97 04 16 01 2f|04 40 6f 02 12 02 1b"),
    0x29:_records("07 28 47 03 14 01 3f"),
    0x2a:_records("07 f0 a7 04 0b 02 2f|04 20 4f 03 19 02 1f"),
    0x2b:_records("07 d8 4f 03 1b 03 15|08 88 9f 02 0a 02 1f"),
    0x2c:_records("06 48 47 03 15 03 1f|07 38 5f 04 15 01 17|05 d0 47 03 1d 02 17"),
    0x2d:_records("07 e7 97 00 0c 01 01|06 98 47 03 1d 02 17|05 08 47 02 1c 02 37"),
    0x2e:_records("05 58 67 04 19 02 2f|07 88 5f 02 19 01 3f|06 00 87 02 10 01 19|02 90 77 00 1d 01 01"),
    0x2f:_records("08 70 7f 02 1c 01 27|07 a0 27 02 1c 02 17|03 90 67 04 09 02 1f|07 60 5f 00 0d 01 01"),
    0x30:_records("06 00 24 02 1f 01 ff"),
    0x31:_records("06 40 7f 03 12 01 28"),
    0x32:_records("02 00 a3 04 15 02 13"),
    0x33:_records("0e a8 af 04 1b 02 18|05 00 7f 03 14 01 30"),
}

# 20 fixed special-item records: index, room, sprite X, sprite Y, frame base,
# description, cheat-only. Index 19 is intentionally cheat-only.
SPECIAL_ITEMS = (
    (0,0x0d,0x70,0xc2,0x03,"cupcake",False),
    (1,0x13,0x5a,0x7a,0x05,"vase",False),
    (2,0x14,0x4c,0x82,0x03,"cupcake",False),
    (3,0x17,0x80,0x72,0x06,"fly spray",False),
    (4,0x16,0x23,0xaa,0x03,"cupcake",False),
    (5,0x1b,0x38,0x62,0x07,"joystick",False),
    (6,0x1a,0x40,0x6a,0x03,"cupcake",False),
    (7,0x1f,0x78,0x62,0x03,"cupcake",False),
    (8,0x23,0x41,0xb2,0x08,"jerry can",False),
    (9,0x29,0x44,0x9a,0x03,"cupcake",False),
    (10,0x2b,0x68,0x5a,0x09,"key",False),
    (11,0x02,0x88,0xa2,0x00,"first aid",False),
    (12,0x04,0x7c,0xc2,0x01,"milk",False),
    (13,0x08,0x50,0x5a,0x02,"teddy",False),
    (14,0x09,0x28,0x62,0x03,"cupcake",False),
    (15,0x0a,0x3c,0xca,0x03,"cupcake",False),
    (16,0x0b,0x38,0x7a,0x04,"smoke stack",False),
    (17,0x10,0x30,0xca,0x03,"cupcake",False),
    (18,0x2d,0x6c,0x62,0x03,"cupcake",False),
    (19,0x01,0x6a,0xd2,0x31,"cake / invincibility cheat",True),
)

# room, col, row, height, char_base
PILEDRIVERS = (
    (0x01,0x07,0x05,0x04,0x10),(0x01,0x1f,0x0c,0x06,0x22),
    (0x02,0x15,0x05,0x04,0x10),(0x06,0x0d,0x06,0x04,0x10),
    (0x0b,0x13,0x11,0x04,0x10),(0x13,0x18,0x0d,0x03,0x10),
    (0x19,0x1a,0x04,0x03,0x10),(0x1b,0x0f,0x04,0x04,0x10),
    (0x1b,0x15,0x04,0x04,0x22),(0x28,0x15,0x0b,0x06,0x10),
)

# source room, destination room, destination sprite X, destination sprite Y.
TELEPORTS = (
    (0x08,0x06,0x34,0x72),(0x14,0x13,0x60,0xa2),
    (0x1c,0x1b,0x28,0x6a),(0x2a,0x29,0x17,0xa2),
)

# room, type, x, y, initial speed/dir. These are the two original moving lifts.
LIFTS = ((0x05,1,0x48,0x5b,0x82),(0x0d,2,0x80,0x53,0x80))
RISING_CLOUD_ROOMS = (0x01,)
RISING_BOLLARD_ROOMS = (0x0c,)
AMBIENT_ENEMY_TYPES = frozenset((0x20,0x21,0x22))

# Non-grid transitions / scripted room changes.
COMPLETION_TRANSITION = (0x2f,0x30)
C5_RETURN_TRANSITION = (0x33,0x26)
