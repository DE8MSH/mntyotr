#!/usr/bin/env python3
"""CLI wrapper with strict mechanism and cheat-only reporting.

Normal-play parity and cheat/Easter-egg parity are intentionally separate:
missing cheat content is visible in the report but never turns an otherwise
correct normal room into WARN/MISSING/FAIL.
"""
from __future__ import annotations

import re
from collections import Counter

import playthrough_audit as core
from playthrough_cheat_truth import (
    CHEAT_ACTIVATION_PHRASE,
    CHEAT_C5_ROOMS,
    CHEAT_FEATURES,
    CHEAT_PILEDRIVER_INSTANCE_COUNT,
    CHEAT_PILEDRIVER_ROOMS,
    CHEAT_SPECIAL,
)


# Keep references to the base implementations before monkey-patching them.
_base_summarize = core.summarize


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


def special_audit_normal_only(a: core.Audit) -> None:
    """Audit normal-play specials; cheat-only records are tracked separately."""
    text = a.read("special_item_runtime.asm")
    for idx, room, x, y, frame, name, cheat in core.SPECIAL_ITEMS:
        if cheat:
            a.set_ok_note(room, "specials", f"{name} is CHEAT-ONLY and excluded from normal-play status")
            continue
        block = core.extract_special_room_block(text, room)
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


def asm_code(text: str) -> str:
    """Remove ';' comments so comments cannot satisfy implementation probes."""
    return "\n".join(line.split(";", 1)[0] for line in text.splitlines()).lower()


def cheat_snapshot(a: core.Audit) -> dict:
    """Report cheat-only C64 behaviour without affecting normal completion."""
    all_code = "\n".join(asm_code(text) for text in a.src_files.values())
    all_text = "\n".join(a.src_files.values()).lower()
    special = a.read("special_item_runtime.asm")
    pile_code = asm_code(a.read("standard_piledriver_static.asm"))

    idx, room, x, y, frame, name = CHEAT_SPECIAL
    block = core.extract_special_room_block(special, room)
    cake_exact = False
    if block is not None:
        cake_exact = (
            core.block_assignment(block, "special_item_index") == idx
            and core.block_assignment(block, "special_item_x") == x
            and core.block_assignment(block, "special_item_y") == y
        )
    # Exact spawn alone is not enough: R01 must actually be gated by cheat state.
    cake_gated = cake_exact and "cheat_mode" in asm_code(block or "")

    activation_ok = (
        "cheat_mode" in all_code
        and CHEAT_ACTIVATION_PHRASE.lower() in all_text
    )

    # After collecting the cake the original has bit 7 set.  Ordinary death
    # dispatch is skipped while negative; action 1 / completion still dispatch.
    invincibility_ok = bool(re.search(
        r"cheat_mode.{0,180}\b(?:bmi|bit)\b|\b(?:bmi|bit)\b.{0,180}cheat_mode",
        all_code,
        re.S,
    )) and cake_gated

    # Original alternate piledriver seed rows from Mechanisms.Data +$18 frame.
    cheat_seed_rows = (
        "db $00,$00,$1f,$20,$fb,$71,$20,$00",
        "db $3c,$c3,$ff,$99,$e7,$c3,$81,$00",
        "db $00,$00,$f8,$04,$df,$8e,$04,$00",
    )
    pile_alt_ok = "cheat_mode" in pile_code and all(row in pile_code for row in cheat_seed_rows)

    c5_files = [
        (name, asm_code(text)) for name, text in a.src_files.items()
        if "c5" in name.lower() or "freedom" in name.lower()
    ]
    c5_cheat_ok = any("cheat_mode" in text and "c5" in text for _name, text in c5_files)

    implemented = {
        "hiscore-cheat-trigger": activation_ok,
        "room01-secret-cake": cake_gated,
        "cake-invincibility": invincibility_ok,
        "alternate-piledriver-glyphs": pile_alt_ok,
        "c5-lethal-tile-bypass": c5_cheat_ok,
    }

    findings = []
    room_features = {room: [] for room in range(0x34)}
    for feature in CHEAT_FEATURES:
        ok = implemented[feature["id"]]
        rec = {
            "id": feature["id"],
            "status": "OK" if ok else "MISSING",
            "stage": feature["stage"],
            "description": feature["description"],
            "rooms": [f"{r:02X}" for r in feature["rooms"]],
        }
        findings.append(rec)
        for r in feature["rooms"]:
            room_features[r].append(rec)

    by_room = {}
    for room, feats in room_features.items():
        if not feats:
            by_room[room] = {"status": "N/A", "expected": 0, "notes": []}
            continue
        status = "MISSING" if any(f["status"] == "MISSING" for f in feats) else "OK"
        by_room[room] = {
            "status": status,
            "expected": len(feats),
            "notes": [f"{f['status']}: {f['description']}" for f in feats],
        }

    return {
        "activation_phrase": CHEAT_ACTIVATION_PHRASE,
        "normal_play_impact": "none; cheat-only MISSING never changes normal OVERALL",
        "piledriver_instances": CHEAT_PILEDRIVER_INSTANCE_COUNT,
        "piledriver_rooms": [f"{r:02X}" for r in CHEAT_PILEDRIVER_ROOMS],
        "c5_rooms": [f"{r:02X}" for r in CHEAT_C5_ROOMS],
        "counts": Counter(f["status"] for f in findings),
        "findings": findings,
        "rooms": by_room,
    }


def summarize_with_cheats(a: core.Audit) -> dict:
    result = _base_summarize(a)
    cheat = cheat_snapshot(a)
    result["cheat_only"] = cheat
    result["source_truth"]["cheat_feature_classes"] = len(CHEAT_FEATURES)
    for room in result["rooms"]:
        c = cheat["rooms"][room["room"]]
        room["cheat"] = c
        room["expected"]["cheat"] = c["expected"]
    return result


def text_report_with_cheats(result: dict) -> str:
    truth = result["source_truth"]
    counts = result["finding_counts"]
    cheat = result["cheat_only"]
    cheat_counts = cheat["counts"]
    short = lambda s: {
        "OK": "OK", "WARN": "WRN", "MISSING": "MISS", "FAIL": "FAIL", "N/A": "-"
    }[s]

    out = [
        "Monty on the Run - headless playthrough/content audit",
        "=" * 64,
        f"Normal truth: {truth['rooms']} rooms, {truth['gems']} gems, {truth['enemies']} enemy spawns, "
        f"{truth['special_items_normal']} normal specials, {truth['piledrivers']} piledrivers, "
        f"{truth['teleporters']} teleporters",
        f"Cheat truth: {truth['cheat_feature_classes']} cheat-only feature classes; activation phrase: "
        f"\"{cheat['activation_phrase']}\"",
        f"Normal findings: FAIL={counts.get('FAIL',0)}  MISSING={counts.get('MISSING',0)}  WARN={counts.get('WARN',0)}",
        f"Cheat-only findings: OK={cheat_counts.get('OK',0)}  MISSING={cheat_counts.get('MISSING',0)} "
        "(do NOT affect normal OVERALL)",
        "",
        "ROOM  OVERALL  GEO WORLD GEMS ENEMY SPEC MECH CHEAT  EXPECTED(g/e/s/m/c)",
        "----  -------  ---- ----- ---- ----- ---- ---- -----  -------------------",
    ]
    for r in result["rooms"]:
        a = r["areas"]; e = r["expected"]; c = r["cheat"]
        out.append(
            f"R{r['hex']}   {short(r['overall']):<7}  {short(a['geometry']):<4} {short(a['world']):<5} "
            f"{short(a['gems']):<4} {short(a['enemies']):<5} {short(a['specials']):<4} "
            f"{short(a['mechanisms']):<4} {short(c['status']):<5}  "
            f"{e['gems']}/{e['enemies']}/{e['specials']}/{e['mechanisms']}/{e['cheat']}"
        )

    out += ["", "Normal-play findings", "--------------------"]
    if not result["findings"]:
        out.append("OK: no normal-play findings")
    else:
        for f in sorted(
            result["findings"],
            key=lambda x: (-core.SEVERITY[x["status"]], 999 if x["room"] is None else x["room"], x["area"]),
        ):
            label = "GLOBAL" if f["room"] is None else f"R{f['room_hex']}"
            out.append(f"[{f['status']:<7}] {label} {f['area']}: {f['message']}")

    out += [
        "",
        "CHEAT-ONLY / Easter-egg content (separate from normal play)",
        "-----------------------------------------------------------",
    ]
    for f in cheat["findings"]:
        label = "GLOBAL" if not f["rooms"] else "/".join(f"R{x}" for x in f["rooms"])
        out.append(f"[CHEAT-{f['status']:<7}] {label}: {f['description']}  (stage: {f['stage']})")

    out += [
        "",
        "Cheat-mode semantics from the original:",
        f"  1. Enter \"{cheat['activation_phrase']}\" as the hi-score name -> cheat_mode=$01 for next game.",
        "  2. R01 then spawns secret cake #19 at X=$6A Y=$D2; this item does NOT exist in normal play.",
        "  3. Collecting the cake sets bit 7 (effectively $81): ordinary deaths are suppressed.",
        f"  4. The {cheat['piledriver_instances']} piledrivers switch to alternate Easter-egg glyphs.",
        "  5. C5 movement skips its normal lethal type-2 tile guard while cheat bit 7 is set.",
        "",
        "Interpretation:",
        "  FAIL       = normal port contradicts source truth / generated data is broken",
        "  MISSING    = normal source feature is known but not yet ported/wired",
        "  WARN       = normal-play topology uncertainty; not used for cheat-only omissions",
        "  CHEAT-MISS = original cheat/Easter-egg behaviour missing; normal room can still be OK",
        "  --strict makes normal MISSING fatal; cheat-only omissions remain informational.",
    ]
    return "\n".join(out) + "\n"


core.mechanism_audit = mechanism_audit
core.special_audit = special_audit_normal_only
core.summarize = summarize_with_cheats
core.text_report = text_report_with_cheats

if __name__ == "__main__":
    raise SystemExit(core.main())
