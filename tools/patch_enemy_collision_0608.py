#!/usr/bin/env python3
"""Make the shared enemy collision selector cover every original entity type.

The base collision routine was written while only a subset of rooms was active.
This build-copy patch keeps the stable opaque-pixel collision engine and replaces
only its sprite-source selector. Types $20-$22 are the Room-$23 sky banners:
they are rendered/moved through the normal entity pipeline but must never damage
Monty, exactly like the original C64 entity system.
"""
from pathlib import Path
import re
import sys

HOSTILE_TYPES = tuple(range(0x08, 0x20))
AMBIENT_TYPES = (0x20, 0x21, 0x22)
ALL_TYPES = HOSTILE_TYPES + AMBIENT_TYPES


def selector_body() -> str:
    out = [".select_enemy_source:\n",
           "        ldx     enemy_col_state\n",
           "        lda     enemy_state_tbl+4,x\n",
           "        and     #$80\n",
           "        bne     .enemy_reverse_group\n",
           "        lda     #4\n",
           "        bra     .enemy_group_ready\n",
           ".enemy_reverse_group:\n",
           "        cla\n",
           ".enemy_group_ready:\n",
           "        sta     enemy_col_frame\n",
           "        ldy     enemy_col_slot\n",
           "        lda     enemy_anim_timer_tbl,y\n",
           "        and     #$06\n",
           "        lsr     a\n",
           "        clc\n",
           "        adc     enemy_col_frame\n",
           "        sta     enemy_col_frame\n\n",
           "        ldx     enemy_col_state\n",
           "        lda     enemy_state_tbl+3,x\n"]
    for i, typ in enumerate(ALL_TYPES):
        next_label = f".enemy_not{typ:02x}"
        out += [
            f"        cmp     #${typ:02x}\n",
            f"        bne     {next_label}\n",
            f"        lda     #<enemy_type{typ:02x}_patterns\n",
            "        sta     <_bp\n",
            f"        lda     #>enemy_type{typ:02x}_patterns\n",
            "        jsr     .add_frame_high\n",
            f"        ldy     #BANK(enemy_type{typ:02x}_patterns)\n",
            "        rts\n",
            f"{next_label}:\n",
        ]
    # Defensive fallback: no source entity outside $08-$22 should ever arrive.
    out += [
        "        lda     #<enemy_type09_patterns\n",
        "        sta     <_bp\n",
        "        lda     #>enemy_type09_patterns\n",
        "        jsr     .add_frame_high\n",
        "        ldy     #BANK(enemy_type09_patterns)\n",
        "        rts\n\n",
    ]
    return "".join(out)


def patch_collision(text: str) -> str:
    start = text.find(".select_enemy_source:")
    end = text.find(".add_frame_high:", start)
    if start < 0 or end < 0:
        raise ValueError("enemy collision selector bounds not found")
    text = text[:start] + selector_body() + text[end:]

    old = """        jsr     .opaque_overlap\n        bcc     .precise_next\n\n        lda     #1\n        sta     enemy_col_hit\n"""
    new = """        jsr     .opaque_overlap\n        bcc     .precise_next\n\n        ; C64 room $23 flying banners (types $20-$22) are ambient entities.\n        ; They share sprite motion/rendering but never participate in damage.\n        ldx     enemy_col_state\n        lda     enemy_state_tbl+3,x\n        cmp     #$20\n        bcc     .hostile_hit\n        cmp     #$23\n        bcc     .precise_next\n.hostile_hit:\n        lda     #1\n        sta     enemy_col_hit\n"""
    if old not in text:
        if "ambient entities" not in text:
            raise ValueError("precise collision hit anchor not found")
    else:
        text = text.replace(old, new, 1)
    return text


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch_enemy_collision_0608.py <enemy_collision.asm>")
    path = Path(sys.argv[1])
    patched = patch_collision(path.read_text())
    path.write_text(patched)
    print("Enemy collision selector: exact types $08-$22; ambient $20-$22 non-damaging")


if __name__ == "__main__":
    main()
