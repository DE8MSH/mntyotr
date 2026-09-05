#!/usr/bin/env python3
"""Extend the shared C64 enemy collision selector for Rooms $06/$08.

The runtime collision code predates the three sprite classes first encountered in
these rooms.  Patch the build-copy only, keeping the stable source routine intact
until the enemy selector is converted to a table-driven implementation.
"""
from pathlib import Path
import sys


def patch_collision(text: str) -> str:
    anchor_a = """.enemy_not0f:\n        cmp     #$14\n        bne     .enemy_not14\n"""
    repl_a = """.enemy_not0f:\n        cmp     #$11\n        bne     .enemy_not11\n        lda     #<enemy_type11_patterns\n        sta     <_bp\n        lda     #>enemy_type11_patterns\n        jsr     .add_frame_high\n        ldy     #BANK(enemy_type11_patterns)\n        rts\n.enemy_not11:\n        cmp     #$13\n        bne     .enemy_not13\n        lda     #<enemy_type13_patterns\n        sta     <_bp\n        lda     #>enemy_type13_patterns\n        jsr     .add_frame_high\n        ldy     #BANK(enemy_type13_patterns)\n        rts\n.enemy_not13:\n        cmp     #$14\n        bne     .enemy_not14\n"""

    anchor_b = """.enemy_not19:\n        cmp     #$1b\n        bne     .enemy_type1d\n        lda     #<enemy_type1b_patterns\n        sta     <_bp\n        lda     #>enemy_type1b_patterns\n        jsr     .add_frame_high\n        ldy     #BANK(enemy_type1b_patterns)\n        rts\n.enemy_type1d:\n"""
    repl_b = """.enemy_not19:\n        cmp     #$1b\n        bne     .enemy_not1b\n        lda     #<enemy_type1b_patterns\n        sta     <_bp\n        lda     #>enemy_type1b_patterns\n        jsr     .add_frame_high\n        ldy     #BANK(enemy_type1b_patterns)\n        rts\n.enemy_not1b:\n        cmp     #$1c\n        bne     .enemy_type1d\n        lda     #<enemy_type1c_patterns\n        sta     <_bp\n        lda     #>enemy_type1c_patterns\n        jsr     .add_frame_high\n        ldy     #BANK(enemy_type1c_patterns)\n        rts\n.enemy_type1d:\n"""

    if anchor_a not in text:
        if "enemy_type11_patterns" not in text or "enemy_type13_patterns" not in text:
            raise ValueError("collision selector anchor $0F->$14 not found")
    else:
        text = text.replace(anchor_a, repl_a, 1)

    if anchor_b not in text:
        if "enemy_type1c_patterns" not in text:
            raise ValueError("collision selector anchor $19->$1B->$1D not found")
    else:
        text = text.replace(anchor_b, repl_b, 1)

    return text


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch_enemy_collision_0608.py <enemy_collision.asm>")
    path = Path(sys.argv[1])
    original = path.read_text()
    patched = patch_collision(original)
    path.write_text(patched)
    print("Enemy collision selector: exact $11 Rubik, $13 Pi/Pie, $1C Tank enabled")


if __name__ == "__main__":
    main()
