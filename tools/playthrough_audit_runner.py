#!/usr/bin/env python3
"""CLI wrapper with strict mechanism detection for playthrough_audit.

Kept small on purpose: playthrough_audit.py owns the general auditor; this layer
replaces only the mechanism probe so decimal immediates (e.g. CMP #1) are accepted
and scripted room transitions cannot be satisfied by unrelated constants far apart.
"""
from __future__ import annotations

import re
from collections import Counter

import playthrough_audit as core


def has_room_cmp(text: str, room: int) -> bool:
    text = text.lower()
    return bool(re.search(rf"\bcmp\s+#(?:\${room:02x}|{room})(?![0-9a-f])", text))


def has_scripted_pending_room_transition(text: str, src: int, dst: int) -> bool:
    """Require src check and dst write to world_pending_room in one local block."""
    text = text.lower()
    src_lit = rf"(?:\${src:02x}|{src})"
    dst_lit = rf"(?:\${dst:02x}|{dst})"
    return bool(re.search(
        rf"cmp\s+#{src_lit}(?![0-9a-f]).{{0,500}}?"
        rf"lda\s+#{dst_lit}(?![0-9a-f])\s*\n\s*sta\s+<world_pending_room\b",
        text,
        re.S,
    ))


def mechanism_audit(a: core.Audit) -> None:
    pile = a.read("standard_piledriver_static.asm").lower()
    lift = a.read("moving_lift.asm").lower()
    cloud = a.read("rising_cloud.asm").lower()
    bollard = a.read("rising_bollard.asm").lower()

    expected_pile_counts = Counter(r for r, *_ in core.PILEDRIVERS)
    active_pile_rooms = {
        room for room in range(0x34) if has_room_cmp(pile, room)
    }
    for room, count in expected_pile_counts.items():
        if room not in active_pile_rooms:
            a.add("MISSING", "mechanisms", f"{count} source piledriver(s) not active", room)
        else:
            a.set_ok_note(room, "mechanisms", f"piledriver room enabled ({count} source config(s))")

    tele_runtime = any(
        "teleporter_room" in text.lower() or "teleporter_update" in text.lower()
        for text in a.src_files.values()
    )
    for src, dst, x, y in core.TELEPORTS:
        if not tele_runtime:
            a.add(
                "MISSING", "mechanisms",
                f"teleporter R{src:02X}->R{dst:02X} missing; destination ${x:02X},${y:02X}",
                src,
            )

    for room, typ, x, y, speed in core.LIFTS:
        if not has_room_cmp(lift, room):
            a.add("MISSING", "mechanisms", f"moving lift type {typ} missing", room)
        elif f"#${x:02x}" not in lift or f"#${y:02x}" not in lift:
            a.add("FAIL", "mechanisms", f"lift position should be ${x:02X},${y:02X}", room)
        else:
            a.set_ok_note(room, "mechanisms", "moving lift present")

    for room in core.RISING_CLOUD_ROOMS:
        if not has_room_cmp(cloud, room):
            a.add("MISSING", "mechanisms", "rising cloud missing", room)
        else:
            a.set_ok_note(room, "mechanisms", "rising cloud present")

    for room in core.RISING_BOLLARD_ROOMS:
        if not has_room_cmp(bollard, room):
            a.add("MISSING", "mechanisms", "rising bollard missing", room)
        else:
            a.set_ok_note(room, "mechanisms", "rising bollard present")

    runtime = "\n".join(
        text for name, text in a.src_files.items()
        if "assets" not in name and name != "room20_33_assets_tail.asm"
    )
    src, dst = core.COMPLETION_TRANSITION
    if not has_scripted_pending_room_transition(runtime, src, dst):
        a.add("MISSING", "mechanisms", "completion transition R2F->R30 not wired", src)

    src, dst = core.C5_RETURN_TRANSITION
    if not has_scripted_pending_room_transition(runtime, src, dst):
        a.add("MISSING", "mechanisms", "C5 return R33->R26 not wired", src)


core.mechanism_audit = mechanism_audit

if __name__ == "__main__":
    raise SystemExit(core.main())
