#!/usr/bin/env python3
"""Whole-game audit with complete late-room/runtime detection.

This layer sits on top of playthrough_audit_runner so the cheat reporting stays
separate, but it teaches the auditor about the completed legacy enemy gap,
late special-item runtime, all piledriver configs, the full collision selector,
and the scripted transition helpers.  The goal is that MISS means a real missing
source feature rather than an auditor that has not learned a new module yet.
"""
from __future__ import annotations

import re
from collections import Counter, defaultdict

import playthrough_audit as core
import playthrough_audit_runner  # installs cheat-aware summarize/text report


def enemy_wiring(a: core.Audit, room: int) -> tuple[bool, str]:
    life = a.read("game_life.asm").lower()
    special = a.read("special_item_runtime.asm").lower()
    main = a.read("main.asm").lower()
    if 0x00 <= room <= 0x05:
        return "call    enemy_smiley_room_sync" in main, "generic R00-R05 runtime"
    if room in (0x06, 0x08, 0x0F):
        ok = 'include "enemy_room0608_runtime.asm"' in life and "call    enemy_room0608_room_sync" in life
        return ok, "R06/R08/R0F seed shim"
    if room == 0x07:
        ok = 'include "enemy_room07_runtime.asm"' in life and "call    enemy_room07_room_sync" in life
        return ok, "R07 seed shim"
    if room in (0x09, 0x0A, 0x0C, 0x0D, 0x0E):
        ok = 'include "enemy_room09_0e_runtime.asm"' in life and "call    enemy_room09_0e_room_sync" in life
        return ok, "R09/R0A/R0C/R0D/R0E table runtime"
    if room == 0x0B:
        ok = "call enemy_room0b_seed" in special and "call    special_item_room_sync" in main
        return ok, "R0B room-special seed"
    if 0x10 <= room <= 0x1F:
        ok = 'include "enemy_room10_1f_runtime.asm"' in life and "call    enemy_room10_1f_room_sync" in life
        return ok, "R10-R1F table runtime"
    if 0x20 <= room <= 0x33:
        ok = 'include "enemy_room20_33_runtime.asm"' in life and "call    enemy_room20_33_room_sync" in life
        return ok, "R20-R33 table runtime"
    return False, "no room enemy runtime"


def enemy_audit(a: core.Audit) -> None:
    enemy_files = [
        a.read("enemy_smiley_runtime.asm"),
        a.read("enemy_room0608_runtime.asm"),
        a.read("enemy_room07_runtime.asm"),
        a.read("enemy_room0b_runtime.asm"),
        a.read("enemy_room09_0e_runtime.asm"),
        a.read("enemy_room10_1f_runtime.asm"),
        a.read("enemy_room20_33_runtime.asm"),
    ]
    raw = core.extract_raw_enemy_records(enemy_files)
    dedicated = {
        0x06: a.read("enemy_room0608_runtime.asm"),
        0x08: a.read("enemy_room0608_runtime.asm"),
        0x0F: a.read("enemy_room0608_runtime.asm"),
        0x07: a.read("enemy_room07_runtime.asm"),
        0x0B: a.read("enemy_room0b_runtime.asm"),
    }

    assets = a.read("enemy_room00_assets_tail.asm").lower()
    asset_types = {int(x, 16) for x in re.findall(r"enemy_type([0-9a-f]{2})_patterns:", assets)}

    patch = (core.TOOLS / "patch_enemy_collision_0608.py").read_text(errors="replace").lower()
    base_collision = a.read("enemy_room00_collision.asm").lower()
    collision_types = {int(x, 16) for x in re.findall(r"enemy_type([0-9a-f]{2})_patterns", base_collision + "\n" + patch)}
    # The current selector generator is intentionally table/range driven, so
    # literal label regexes cannot see the generated type names.  Recognise its
    # explicit hostile range only when the exact range declaration is present.
    if "hostile_types = tuple(range(0x08, 0x20))" in patch:
        collision_types.update(range(0x08, 0x20))

    for room in core.ROOMS:
        exp = core.ENEMIES[room]
        data_ok = False
        if room in raw:
            if raw[room] == exp:
                data_ok = True
            else:
                a.add("FAIL", "enemies", f"spawn table differs from source: got {raw[room]} expected {exp}", room)
        elif room in dedicated and core.source_comment_contains_records(dedicated[room], exp):
            data_ok = True
        else:
            a.add("MISSING", "enemies", f"no exact port spawn data for {len(exp)} source enemies", room)

        wired, wiring_name = enemy_wiring(a, room)
        if not wired and data_ok:
            a.add("MISSING", "enemies", f"spawn data is exact but {wiring_name} is not wired", room)

        missing_assets = sorted({rec[4] for rec in exp} - asset_types)
        if missing_assets:
            a.add("MISSING", "enemies", "missing sprite asset type(s): " + ", ".join(f"${x:02X}" for x in missing_assets), room)

        if data_ok and wired:
            harmful = {rec[4] for rec in exp if rec[4] not in core.AMBIENT_ENEMY_TYPES}
            missing_collision = sorted(harmful - collision_types)
            if missing_collision:
                a.add("MISSING", "enemies", "collision selector lacks type(s): " + ", ".join(f"${x:02X}" for x in missing_collision), room)
            else:
                a.set_ok_note(room, "enemies", f"{len(exp)}/{len(exp)} exact + wired")

    ambient_guard = (
        "ambient_types = (0x20, 0x21, 0x22)" in patch
        and "cmp     #$20" in patch
        and "cmp     #$23" in patch
    )
    if not ambient_guard:
        a.add("MISSING", "enemies", "R23 flying banners $20-$22 need an explicit non-damaging collision guard", 0x23)

    if a.build_dir and a.build_dir.exists():
        for filename in re.findall(r'incbin\s+"(enemy-[^"]+\.dat)"', assets, re.I):
            if not (a.build_dir / filename).exists():
                a.add("FAIL", "enemies", f"generated enemy asset missing: {filename}")


def room_block(text: str, room: int) -> str | None:
    """Accept both legacy .roomXX and compact late-runtime .rXX labels."""
    m = re.search(rf"(?mi)^\.(?:room|r){room:02x}:\s*$", text)
    if not m:
        return None
    tail = text[m.end():]
    end = re.search(r"(?mi)^\.(?:room[0-9a-f]{2}|r[0-9a-f]{2}|activate|none):\s*$", tail)
    return tail[:end.start()] if end else tail


def special_audit(a: core.Audit) -> None:
    early = a.read("special_item_runtime.asm")
    late = a.read("special_item_late_runtime.asm")
    for idx, room, x, y, frame, name, cheat in core.SPECIAL_ITEMS:
        if cheat:
            a.set_ok_note(room, "specials", f"{name} is CHEAT-ONLY and excluded from normal-play status")
            continue
        block = room_block(early, room) or room_block(late, room)
        if block is None:
            a.add("MISSING", "specials", f"special #{idx} {name} spawn missing (source ${x:02X},${y:02X})", room)
            continue
        got_idx = core.block_assignment(block, "special_item_index")
        got_x = core.block_assignment(block, "special_item_x")
        got_y = core.block_assignment(block, "special_item_y")
        if (got_idx, got_x, got_y) != (idx, x, y):
            a.add("FAIL", "specials", f"{name} spawn/index {(got_idx,got_x,got_y)} != source {(idx,x,y)}", room)
        else:
            a.set_ok_note(room, "specials", f"{name} exact")


def pile_room_present(a: core.Audit, room: int, count: int) -> bool:
    early = a.read("standard_piledriver_static.asm").lower()
    late = a.read("piledriver_late_runtime.asm").lower()
    if room == 0x01:
        return ".room01:" in early and "#$07" in early and "#$1f" in early and "#2" in early
    if room == 0x02:
        return ".room02:" in early and "#$15" in early
    if room == 0x0B:
        return ".room0b:" in early and "#$13" in early and "#$11" in early
    label = f".r{room:02x}:"
    if label not in late:
        return False
    expected_cols = {
        0x06: (0x0D,), 0x13: (0x18,), 0x19: (0x1A,),
        0x1B: (0x0F, 0x15), 0x28: (0x15,),
    }.get(room, ())
    return all(f"#${col:02x}" in late[late.index(label):] for col in expected_cols)


def mechanism_audit(a: core.Audit) -> None:
    lift = a.read("moving_lift.asm").lower()
    cloud = a.read("rising_cloud.asm").lower()
    bollard = a.read("rising_bollard.asm").lower()

    expected_pile_counts = Counter(r for r, *_ in core.PILEDRIVERS)
    for room, count in expected_pile_counts.items():
        if not pile_room_present(a, room, count):
            a.add("MISSING", "mechanisms", f"{count} source piledriver(s) not active", room)
        else:
            a.set_ok_note(room, "mechanisms", f"piledriver room enabled ({count} source config(s))")

    tele = a.read("teleporter_runtime.asm").lower()
    tele_dest = "db $06,$13,$1b,$29" in tele and "db $34,$60,$28,$17" in tele and "db $72,$a2,$6a,$a2" in tele
    for src, dst, x, y in core.TELEPORTS:
        src_ok = re.search(rf"cmp\s+#\${src:02x}", tele) is not None
        if not (src_ok and tele_dest and f"${dst:02x}" in tele):
            a.add("MISSING", "mechanisms", f"teleporter R{src:02X}->R{dst:02X} missing; destination ${x:02X},${y:02X}", src)
        else:
            a.set_ok_note(src, "mechanisms", f"teleporter R{src:02X}->R{dst:02X} present")

    for room, typ, x, y, speed in core.LIFTS:
        if not playthrough_audit_runner.has_room_cmp(lift, room):
            a.add("MISSING", "mechanisms", f"moving lift type {typ} missing", room)
        elif f"#${x:02x}" not in lift or f"#${y:02x}" not in lift:
            a.add("FAIL", "mechanisms", f"lift position should be ${x:02X},${y:02X}", room)
        else:
            a.set_ok_note(room, "mechanisms", "moving lift present")

    for room in core.RISING_CLOUD_ROOMS:
        if not playthrough_audit_runner.has_room_cmp(cloud, room):
            a.add("MISSING", "mechanisms", "rising cloud missing", room)
        else:
            a.set_ok_note(room, "mechanisms", "rising cloud present")
    for room in core.RISING_BOLLARD_ROOMS:
        if not playthrough_audit_runner.has_room_cmp(bollard, room):
            a.add("MISSING", "mechanisms", "rising bollard missing", room)
        else:
            a.set_ok_note(room, "mechanisms", "rising bollard present")

    scripted = a.read("scripted_transition_runtime.asm").lower()
    if not ("cmp #$2f" in scripted and "lda #$30" in scripted and "sta <world_pending_room" in scripted):
        a.add("MISSING", "mechanisms", "completion transition R2F->R30 not wired", 0x2F)
    else:
        a.set_ok_note(0x2F, "mechanisms", "completion transition R2F->R30 present")
    if not ("cmp #$33" in scripted and "lda #$26" in scripted and "sta <world_pending_room" in scripted):
        a.add("MISSING", "mechanisms", "C5 return R33->R26 not wired", 0x33)
    else:
        a.set_ok_note(0x33, "mechanisms", "C5 return R33->R26 present")


core.enemy_audit = enemy_audit
core.special_audit = special_audit
core.mechanism_audit = mechanism_audit

if __name__ == "__main__":
    raise SystemExit(core.main())
