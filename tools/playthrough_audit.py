#!/usr/bin/env python3
"""Headless whole-game content/playthrough audit for the PCE Monty port.

This does not emulate the HuC6280. Instead it checks the things that normally
force a human to visit every room: source geometry/loaders, room topology,
collectible placement, exact enemy spawn data and wiring, sprite assets,
special-item spawns, and room mechanisms. The canonical data lives in
playthrough_truth.py and is independent from the PCE runtime tables.

Default mode fails only on contradictions/regressions (FAIL). Features that are
known from the original but not ported yet are reported as MISSING while keeping
the development build usable. --strict also fails on MISSING.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict, deque
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable

from playthrough_truth import (
    AMBIENT_ENEMY_TYPES,
    C5_RETURN_TRANSITION,
    COMPLETION_TRANSITION,
    ENEMIES,
    GEMS,
    LIFTS,
    PILEDRIVERS,
    RISING_BOLLARD_ROOMS,
    RISING_CLOUD_ROOMS,
    SPECIAL_ITEMS,
    TELEPORTS,
    WORLD_GRID,
)

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
TOOLS = ROOT / "tools"
ROOMS = tuple(range(0x34))
SEVERITY = {"OK": 0, "WARN": 1, "MISSING": 2, "FAIL": 3}


@dataclass
class Finding:
    status: str
    area: str
    message: str
    room: int | None = None

    def label(self) -> str:
        return "GLOBAL" if self.room is None else f"R{self.room:02X}"


class Audit:
    def __init__(self, build_dir: Path | None = None) -> None:
        self.build_dir = build_dir
        self.findings: list[Finding] = []
        self.cells: dict[int, dict[str, str]] = {
            r: {"geometry": "OK", "world": "OK", "gems": "OK", "enemies": "OK", "specials": "OK", "mechanisms": "OK"}
            for r in ROOMS
        }
        self.notes: dict[int, dict[str, list[str]]] = {
            r: defaultdict(list) for r in ROOMS
        }
        self.src_files = {p.name: p.read_text(errors="replace") for p in SRC.glob("*.asm")}
        self.all_src = "\n".join(self.src_files.values())

    def add(self, status: str, area: str, message: str, room: int | None = None) -> None:
        assert status in SEVERITY
        self.findings.append(Finding(status, area, message, room))
        if room is not None and room in self.cells:
            if SEVERITY[status] > SEVERITY[self.cells[room][area]]:
                self.cells[room][area] = status
            self.notes[room][area].append(message)

    def set_ok_note(self, room: int, area: str, message: str) -> None:
        self.notes[room][area].append(message)

    def read(self, name: str) -> str:
        return self.src_files.get(name, "")


def hexes(text: str) -> list[int]:
    return [int(x, 16) for x in re.findall(r"\$([0-9a-fA-F]{2})", text)]


def asm_number(token: str) -> int:
    token = token.strip().lower()
    if token.startswith("#$"):
        return int(token[2:], 16)
    if token.startswith("#"):
        return int(token[1:], 10)
    if token.startswith("$"):
        return int(token[1:], 16)
    return int(token, 10)


def normalize_record(rec: Iterable[int]) -> str:
    return ",".join(f"${v:02x}" for v in rec)


def extract_world_grid(text: str) -> tuple[tuple[int, ...], ...]:
    if "world_room_grid:" not in text:
        return ()
    block = text.split("world_room_grid:", 1)[1]
    rows = []
    for line in block.splitlines():
        if not line.strip().startswith("db "):
            if rows:
                break
            continue
        vals = hexes(line)
        if len(vals) == 23:
            rows.append(tuple(vals))
        if len(rows) == 6:
            break
    return tuple(rows)


def extract_gem_records(text: str) -> list[tuple[int, int, int, int, int]]:
    if "gem_records:" not in text or "gem_tile_pattern:" not in text:
        return []
    block = text.split("gem_records:", 1)[1].split("gem_tile_pattern:", 1)[0]
    out = []
    for line in block.splitlines():
        if re.search(r"\bdb\b", line, re.I):
            vals = hexes(line)
            if len(vals) == 5:
                out.append(tuple(vals))
    return out


def gem_convert(rec: tuple[int, int, int]) -> tuple[int, int, int, int, int]:
    room, col, row = rec
    x = 0x15 + 4 * col
    y = 0x4C + 8 * row
    bat = (row + 3) * 64 + (col + 4)
    return room, x & 0xFF, y & 0xFF, bat & 0xFF, (bat >> 8) & 0xFF


def extract_raw_enemy_records(texts: Iterable[str]) -> dict[int, tuple[tuple[int, ...], ...]]:
    out: dict[int, tuple[tuple[int, ...], ...]] = {}
    pat = re.compile(r"(?mi)^(?:enemy_room|\.room)([0-9a-f]{2})_records:\s*$")
    for text in texts:
        matches = list(pat.finditer(text))
        for i, m in enumerate(matches):
            room = int(m.group(1), 16)
            end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
            block = text[m.end():end]
            records = []
            for line in block.splitlines():
                s = line.strip().lower()
                if not s.startswith("db "):
                    if records and re.match(r"^[a-z_.]", s):
                        break
                    continue
                vals = hexes(line)
                if vals == [0xFF]:
                    break
                if len(vals) == 7:
                    records.append(tuple(vals))
            if records:
                out[room] = tuple(records)
    return out


def source_comment_contains_records(text: str, records: tuple[tuple[int, ...], ...]) -> bool:
    compact = re.sub(r"\s+", "", text.lower())
    return all(normalize_record(r) in compact for r in records)


def extract_special_room_block(text: str, room: int) -> str | None:
    m = re.search(rf"(?mi)^\.room{room:02x}:\s*$", text)
    if not m:
        return None
    tail = text[m.end():]
    end = re.search(r"(?mi)^\.(?:room[0-9a-f]{2}|activate|none):\s*$", tail)
    return tail[:end.start()] if end else tail


def block_assignment(block: str, symbol: str) -> int | None:
    # Accept either LDA #value / STA symbol, or STZ symbol for zero.
    if re.search(rf"(?mi)^\s*stz\s+<?{re.escape(symbol)}\s*$", block):
        return 0
    m = re.search(
        rf"(?mis)lda\s+(#[\$0-9a-f]+)\s*\n\s*sta\s+<?{re.escape(symbol)}\b",
        block,
    )
    return asm_number(m.group(1)) if m else None


def geometry_audit(a: Audit) -> None:
    world = a.read("world.asm").lower()
    loader = a.read("room050c_loader.asm").lower()
    if "cmp     #$34" not in world:
        a.add("FAIL", "world", "world_room_supported is not $00-$33")

    expected_ext = {0x05,0x06,0x07,0x08,0x09,0x0c,0x0f} | set(range(0x10, 0x34))
    if "room_ext_ids:" not in loader or "room_ext_patterns_lo:" not in loader:
        actual_ext: set[int] = set()
    else:
        block = loader.split("room_ext_ids:", 1)[1].split("room_ext_patterns_lo:", 1)[0]
        actual_ext = set(hexes(block))
    for room in expected_ext:
        if room not in actual_ext:
            a.add("FAIL", "geometry", "room missing from extended loader", room)

    # All non-extended rooms are dedicated/core rooms. Require a room-specific
    # source token so an accidental deletion cannot silently leave a supported ID.
    for room in set(ROOMS) - expected_ext:
        token = f"room{room:02x}"
        if token not in a.all_src.lower():
            a.add("FAIL", "geometry", "dedicated/core room source token missing", room)

    # Generated binary size checks are the closest headless equivalent to loading
    # each room. build.sh invokes the audit after all room generators.
    if a.build_dir and a.build_dir.exists():
        for room in ROOMS:
            checks = [
                (f"room{room:02x}-map.dat", 640),
                (f"room{room:02x}-screen-bat.dat", 36 * 20 * 2),
            ]
            if room != 0:
                checks.append((f"room{room:02x}-patterns.dat", 9 * 32))
            for filename, size in checks:
                path = a.build_dir / filename
                if not path.exists():
                    a.add("FAIL", "geometry", f"generated asset missing: {filename}", room)
                elif path.stat().st_size != size:
                    a.add("FAIL", "geometry", f"{filename} has {path.stat().st_size} bytes, expected {size}", room)


def world_audit(a: Audit) -> None:
    actual = extract_world_grid(a.read("world.asm"))
    if actual != WORLD_GRID:
        a.add("FAIL", "world", "world_room_grid differs from canonical 6x23 table")
        return

    seen = [v for row in actual for v in row if v != 0xFF]
    expected = set(ROOMS) - {0x30}
    if set(seen) != expected or len(seen) != len(expected):
        a.add("FAIL", "world", "grid must contain every normal room exactly once; R30 is off-grid")
    for room in expected:
        if seen.count(room) != 1:
            a.add("FAIL", "world", f"room occurs {seen.count(room)} times in world grid", room)

    # Topology walk: edge neighbours plus canonical scripted transitions.
    pos = {v: (x, y) for y, row in enumerate(actual) for x, v in enumerate(row) if v != 0xFF}
    graph: dict[int, set[int]] = defaultdict(set)
    for room, (x, y) in pos.items():
        for dx, dy in ((-1,0),(1,0),(0,-1),(0,1)):
            nx, ny = x + dx, y + dy
            if 0 <= ny < len(actual) and 0 <= nx < len(actual[0]):
                dest = actual[ny][nx]
                if dest != 0xFF:
                    graph[room].add(dest)
    for src, dst, *_ in TELEPORTS:
        graph[src].add(dst)
    graph[COMPLETION_TRANSITION[0]].add(COMPLETION_TRANSITION[1])
    graph[C5_RETURN_TRANSITION[0]].add(C5_RETURN_TRANSITION[1])

    q = deque([0x00]); reached = {0x00}
    while q:
        src = q.popleft()
        for dst in graph[src]:
            if dst not in reached:
                reached.add(dst); q.append(dst)
    for room in ROOMS:
        if room not in reached:
            a.add("WARN", "world", "not reachable in topology-level source walk from R00", room)


def gem_audit(a: Audit) -> None:
    actual = extract_gem_records(a.read("gem_assets_tail.asm"))
    expected = [gem_convert(r) for r in GEMS]
    by_actual: dict[int, list[tuple[int, ...]]] = defaultdict(list)
    by_expected: dict[int, list[tuple[int, ...]]] = defaultdict(list)
    for rec in actual: by_actual[rec[0]].append(rec)
    for rec in expected: by_expected[rec[0]].append(rec)

    if len(expected) != 64:
        a.add("FAIL", "gems", f"truth manifest has {len(expected)} gems, expected 64")
    if "GEM_RECORD_COUNT = 64" not in a.read("gem_runtime.asm"):
        a.add("FAIL", "gems", "runtime GEM_RECORD_COUNT is not 64")

    for room in ROOMS:
        exp = by_expected[room]; got = by_actual[room]
        if got != exp:
            if len(got) != len(exp):
                a.add("FAIL", "gems", f"gem count {len(got)} != source {len(exp)}", room)
            else:
                for i, (g, e) in enumerate(zip(got, exp)):
                    if g != e:
                        a.add("FAIL", "gems", f"gem #{i} placement {g} != source conversion {e}", room)
        else:
            a.set_ok_note(room, "gems", f"{len(exp)}/{len(exp)} exact")


def enemy_wiring(a: Audit, room: int) -> tuple[bool, str]:
    life = a.read("game_life.asm").lower()
    special = a.read("special_item_runtime.asm").lower()
    main = a.read("main.asm").lower()
    if 0x00 <= room <= 0x05:
        return "call    enemy_smiley_room_sync" in main, "generic R00-R05 runtime"
    if room in (0x06,0x08,0x0f):
        ok = "include \"enemy_room0608_runtime.asm\"" in life and "call    enemy_room0608_room_sync" in life
        return ok, "R06/R08/R0F seed shim"
    if room == 0x07:
        ok = "include \"enemy_room07_runtime.asm\"" in life and "call    enemy_room07_room_sync" in life
        return ok, "R07 seed shim"
    if room == 0x0b:
        ok = "call enemy_room0b_seed" in special and "call    special_item_room_sync" in main
        return ok, "R0B room-special seed"
    if 0x10 <= room <= 0x1f:
        ok = "include \"enemy_room10_1f_runtime.asm\"" in life and "call    enemy_room10_1f_room_sync" in life
        return ok, "R10-R1F table runtime"
    if 0x20 <= room <= 0x33:
        ok = "include \"enemy_room20_33_runtime.asm\"" in life and "call    enemy_room20_33_room_sync" in life
        return ok, "R20-R33 table runtime"
    return False, "no room enemy runtime"


def enemy_audit(a: Audit) -> None:
    enemy_files = [
        a.read("enemy_smiley_runtime.asm"), a.read("enemy_room0608_runtime.asm"),
        a.read("enemy_room07_runtime.asm"), a.read("enemy_room0b_runtime.asm"),
        a.read("enemy_room10_1f_runtime.asm"), a.read("enemy_room20_33_runtime.asm"),
    ]
    raw = extract_raw_enemy_records(enemy_files)
    dedicated = {
        0x06: a.read("enemy_room0608_runtime.asm"), 0x08: a.read("enemy_room0608_runtime.asm"),
        0x0f: a.read("enemy_room0608_runtime.asm"), 0x07: a.read("enemy_room07_runtime.asm"),
        0x0b: a.read("enemy_room0b_runtime.asm"),
    }

    assets = a.read("enemy_room00_assets_tail.asm").lower()
    asset_types = {int(x, 16) for x in re.findall(r"enemy_type([0-9a-f]{2})_patterns:", assets)}

    collision_text = (a.read("enemy_room00_collision.asm") + "\n" + (TOOLS / "patch_enemy_collision_0608.py").read_text(errors="replace")).lower()
    collision_types = {int(x, 16) for x in re.findall(r"enemy_type([0-9a-f]{2})_patterns", collision_text)}

    wired_rooms: set[int] = set()
    for room in ROOMS:
        exp = ENEMIES[room]
        data_ok = False
        if room in raw:
            if raw[room] == exp:
                data_ok = True
            else:
                a.add("FAIL", "enemies", f"spawn table differs from source: got {raw[room]} expected {exp}", room)
        elif room in dedicated and source_comment_contains_records(dedicated[room], exp):
            data_ok = True
        else:
            a.add("MISSING", "enemies", f"no exact port spawn data for {len(exp)} source enemies", room)

        wired, wiring_name = enemy_wiring(a, room)
        if wired:
            wired_rooms.add(room)
        elif data_ok:
            a.add("MISSING", "enemies", f"spawn data is exact but {wiring_name} is not wired", room)
        elif exp:
            # data finding above already explains the main problem
            pass

        missing_assets = sorted({rec[4] for rec in exp} - asset_types)
        if missing_assets:
            a.add("MISSING", "enemies", "missing sprite asset type(s): " + ", ".join(f"${x:02X}" for x in missing_assets), room)

        if data_ok and wired:
            harmful = {rec[4] for rec in exp if rec[4] not in AMBIENT_ENEMY_TYPES}
            missing_collision = sorted(harmful - collision_types)
            if missing_collision:
                a.add("MISSING", "enemies", "collision selector lacks type(s): " + ", ".join(f"${x:02X}" for x in missing_collision), room)
            else:
                a.set_ok_note(room, "enemies", f"{len(exp)}/{len(exp)} exact + wired")

    # Ambient banners must never enter Monty's damage path when R23 becomes live.
    ambient_guard = any(token in collision_text for token in ("ambient", "#$20", "#\$20"))
    if not ambient_guard:
        a.add("MISSING", "enemies", "R23 flying banners $20-$22 need an explicit non-damaging collision guard", 0x23)

    # If build assets are available, verify every enemy incbin named by the tail.
    if a.build_dir and a.build_dir.exists():
        for filename in re.findall(r'incbin\s+"(enemy-[^"]+\.dat)"', assets, re.I):
            if not (a.build_dir / filename).exists():
                a.add("FAIL", "enemies", f"generated enemy asset missing: {filename}")


def special_audit(a: Audit) -> None:
    text = a.read("special_item_runtime.asm")
    for idx, room, x, y, frame, name, cheat in SPECIAL_ITEMS:
        block = extract_special_room_block(text, room)
        if cheat:
            if block is None:
                a.add("WARN", "specials", f"cheat-only special #{idx} {name} not implemented", room)
            continue
        if block is None:
            a.add("MISSING", "specials", f"special #{idx} {name} spawn missing (source ${x:02X},${y:02X})", room)
            continue
        got_idx = block_assignment(block, "special_item_index")
        got_x = block_assignment(block, "special_item_x")
        got_y = block_assignment(block, "special_item_y")
        if (got_idx, got_x, got_y) != (idx, x, y):
            a.add("FAIL", "specials", f"{name} spawn/index {(got_idx,got_x,got_y)} != source {(idx,x,y)}", room)
        else:
            a.set_ok_note(room, "specials", f"{name} exact")


def mechanism_audit(a: Audit) -> None:
    pile = a.read("standard_piledriver_static.asm").lower()
    lift = a.read("moving_lift.asm").lower()
    cloud = a.read("rising_cloud.asm").lower()
    bollard = a.read("rising_bollard.asm").lower()

    expected_pile_counts = Counter(r for r, *_ in PILEDRIVERS)
    active_pile_rooms = {int(v, 16) for v in re.findall(r"cmp\s+#\$([0-9a-f]{2})", pile)}
    for room, count in expected_pile_counts.items():
        if room not in active_pile_rooms:
            a.add("MISSING", "mechanisms", f"{count} source piledriver(s) not active", room)
        else:
            a.set_ok_note(room, "mechanisms", f"piledriver room enabled ({count} source config(s))")

    # Teleporters are a discrete mechanism; a port must contain an actual runtime,
    # not merely room art or comments mentioning the word.
    tele_runtime = any("teleporter_room" in t.lower() or "teleporter_update" in t.lower() for t in a.src_files.values())
    for src, dst, x, y in TELEPORTS:
        if not tele_runtime:
            a.add("MISSING", "mechanisms", f"teleporter R{src:02X}->R{dst:02X} missing; destination ${x:02X},${y:02X}", src)

    for room, typ, x, y, speed in LIFTS:
        room_token = f"cmp     #${room:02x}"
        if room_token not in lift:
            a.add("MISSING", "mechanisms", f"moving lift type {typ} missing", room)
        elif f"#${x:02x}" not in lift or f"#${y:02x}" not in lift:
            a.add("FAIL", "mechanisms", f"lift position should be ${x:02X},${y:02X}", room)
        else:
            a.set_ok_note(room, "mechanisms", "moving lift present")

    for room in RISING_CLOUD_ROOMS:
        if f"#${room:02x}" not in cloud:
            a.add("MISSING", "mechanisms", "rising cloud missing", room)
        else:
            a.set_ok_note(room, "mechanisms", "rising cloud present")
    for room in RISING_BOLLARD_ROOMS:
        if f"#${room:02x}" not in bollard:
            a.add("MISSING", "mechanisms", "rising bollard missing", room)
        else:
            a.set_ok_note(room, "mechanisms", "rising bollard present")

    # Scripted non-grid transitions. Require executable-looking compare/load pairs
    # in runtime code, not asset/generator text.
    runtime = "\n".join(v for k, v in a.src_files.items() if "assets" not in k and "room20_33" not in k)
    def has_scripted(src: int, dst: int) -> bool:
        return bool(re.search(rf"cmp\s+#\${src:02x}.*?(?:lda|cmp)\s+#\${dst:02x}", runtime.lower(), re.S))
    if not has_scripted(*COMPLETION_TRANSITION):
        a.add("MISSING", "mechanisms", "completion transition R2F->R30 not wired", COMPLETION_TRANSITION[0])
    if not has_scripted(*C5_RETURN_TRANSITION):
        a.add("MISSING", "mechanisms", "C5 return R33->R26 not wired", C5_RETURN_TRANSITION[0])


def summarize(a: Audit) -> dict:
    expected_gems = Counter(r for r, _, _ in GEMS)
    expected_specials = Counter(r for _, r, *_rest in SPECIAL_ITEMS if not _rest[-1])
    expected_mechs = Counter()
    for r, *_ in PILEDRIVERS: expected_mechs[r] += 1
    for r, *_ in TELEPORTS: expected_mechs[r] += 1
    for r, *_ in LIFTS: expected_mechs[r] += 1
    for r in RISING_CLOUD_ROOMS: expected_mechs[r] += 1
    for r in RISING_BOLLARD_ROOMS: expected_mechs[r] += 1
    expected_mechs[COMPLETION_TRANSITION[0]] += 1
    expected_mechs[C5_RETURN_TRANSITION[0]] += 1

    rooms = []
    for room in ROOMS:
        cells = a.cells[room]
        overall = max(cells.values(), key=lambda s: SEVERITY[s])
        rooms.append({
            "room": room,
            "hex": f"{room:02X}",
            "overall": overall,
            "areas": dict(cells),
            "expected": {
                "gems": expected_gems[room],
                "enemies": len(ENEMIES[room]),
                "specials": expected_specials[room],
                "mechanisms": expected_mechs[room],
            },
            "notes": {k: list(v) for k, v in a.notes[room].items()},
        })
    counts = Counter(f.status for f in a.findings)
    return {
        "source_truth": {
            "rooms": 52,
            "gems": len(GEMS),
            "enemies": sum(len(v) for v in ENEMIES.values()),
            "special_items_normal": sum(1 for x in SPECIAL_ITEMS if not x[-1]),
            "special_items_cheat": sum(1 for x in SPECIAL_ITEMS if x[-1]),
            "piledrivers": len(PILEDRIVERS),
            "teleporters": len(TELEPORTS),
        },
        "finding_counts": dict(counts),
        "rooms": rooms,
        "findings": [asdict(f) | {"room_hex": None if f.room is None else f"{f.room:02X}"} for f in a.findings],
    }


def text_report(result: dict) -> str:
    truth = result["source_truth"]
    counts = result["finding_counts"]
    out = [
        "Monty on the Run - headless playthrough/content audit",
        "=" * 58,
        f"Truth: {truth['rooms']} rooms, {truth['gems']} gems, {truth['enemies']} enemy spawns, "
        f"{truth['special_items_normal']} normal specials + {truth['special_items_cheat']} cheat special, "
        f"{truth['piledrivers']} piledrivers, {truth['teleporters']} teleporters",
        f"Findings: FAIL={counts.get('FAIL',0)}  MISSING={counts.get('MISSING',0)}  WARN={counts.get('WARN',0)}",
        "",
        "ROOM  OVERALL  GEO WORLD GEMS ENEMY SPEC MECH   EXPECTED(g/e/s/m)",
        "----  -------  ---- ----- ---- ----- ---- ----   -----------------",
    ]
    for r in result["rooms"]:
        a = r["areas"]; e = r["expected"]
        short = lambda s: {"OK":"OK","WARN":"WRN","MISSING":"MISS","FAIL":"FAIL"}[s]
        out.append(
            f"R{r['hex']}   {short(r['overall']):<7}  {short(a['geometry']):<4} {short(a['world']):<5} "
            f"{short(a['gems']):<4} {short(a['enemies']):<5} {short(a['specials']):<4} {short(a['mechanisms']):<4}   "
            f"{e['gems']}/{e['enemies']}/{e['specials']}/{e['mechanisms']}"
        )
    out += ["", "Findings", "--------"]
    if not result["findings"]:
        out.append("OK: no findings")
    else:
        for f in sorted(result["findings"], key=lambda x: (-SEVERITY[x["status"]], 999 if x["room"] is None else x["room"], x["area"])):
            label = "GLOBAL" if f["room"] is None else f"R{f['room_hex']}"
            out.append(f"[{f['status']:<7}] {label} {f['area']}: {f['message']}")
    out += [
        "",
        "Interpretation:",
        "  FAIL    = port contradicts source truth / generated data is broken (build should stop)",
        "  MISSING = source feature is known but not yet ported/wired (default build continues)",
        "  WARN    = optional/cheat or topology-level uncertainty",
        "  --strict makes MISSING fatal for completion-gate CI.",
    ]
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--build-dir", type=Path, help="check generated room/enemy .dat files too")
    ap.add_argument("--json", type=Path, dest="json_path", help="write machine-readable report")
    ap.add_argument("--text", type=Path, dest="text_path", help="write text report")
    ap.add_argument("--strict", action="store_true", help="also fail on MISSING")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    audit = Audit(args.build_dir)
    geometry_audit(audit)
    world_audit(audit)
    gem_audit(audit)
    enemy_audit(audit)
    special_audit(audit)
    mechanism_audit(audit)
    result = summarize(audit)
    report = text_report(result)

    if args.json_path:
        args.json_path.parent.mkdir(parents=True, exist_ok=True)
        args.json_path.write_text(json.dumps(result, indent=2) + "\n")
    if args.text_path:
        args.text_path.parent.mkdir(parents=True, exist_ok=True)
        args.text_path.write_text(report)
    if not args.quiet:
        print(report, end="")

    counts = result["finding_counts"]
    if counts.get("FAIL", 0):
        return 1
    if args.strict and counts.get("MISSING", 0):
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
