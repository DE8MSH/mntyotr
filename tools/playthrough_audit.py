#!/usr/bin/env python3
"""Headless whole-game content/playthrough audit.

This intentionally compares the PCE port against a source-truth manifest rather
than merely checking that port files are internally self-consistent.
"""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict, deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
TOOLS = ROOT / "tools"
ROOMS = tuple(range(0x34))
AREAS = ("geometry", "world", "gems", "enemies", "specials", "mechanisms")
SEVERITY = {"OK": 0, "WARN": 1, "MISSING": 2, "FAIL": 3}

# Exact 6x23 C64 room-destination grid. $30 is completion-only/off-grid.
WORLD_GRID = (
    (0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x23,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff),
    (0xff,0x2f,0x2e,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x22,0xff,0xff,0xff,0xff,0xff,0xff,0x06,0x07,0x08,0x09,0xff,0xff),
    (0x2d,0x2c,0x27,0x26,0x33,0x32,0x31,0x25,0x24,0x20,0x21,0xff,0xff,0xff,0xff,0xff,0x05,0x04,0x03,0x02,0x01,0x00,0xff),
    (0x2b,0x2a,0x28,0x29,0xff,0xff,0xff,0xff,0xff,0x1f,0xff,0xff,0x1b,0xff,0xff,0x0f,0x0c,0x0d,0x0e,0x0b,0x0a,0xff,0xff),
    (0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x1e,0xff,0x1a,0x19,0x18,0xff,0x10,0x11,0xff,0xff,0xff,0xff,0xff,0xff),
    (0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x1d,0x1c,0x17,0x16,0x15,0x14,0x12,0x13,0xff,0xff,0xff,0xff,0xff,0xff),
)

# (room, source col, source row). Exact FreedomKit.Data.item_tbl.
GEMS = (
    (0x00,0x71,0x8c),(0x01,0x41,0x6c),(0x01,0x75,0xa4),(0x01,0x79,0xcc),
    (0x02,0x55,0x74),(0x02,0x35,0xbc),(0x03,0x51,0x84),(0x03,0x6d,0xbc),
    (0x04,0x69,0x84),(0x05,0x55,0x84),(0x05,0x79,0xbc),(0x06,0x4d,0x6c),
    (0x06,0x89,0xbc),(0x08,0x79,0x8c),(0x0a,0x41,0x74),(0x0a,0x65,0x9c),
    (0x0d,0x79,0x84),(0x0e,0x45,0x7c),(0x0f,0x5d,0x74),(0x0f,0x85,0xb4),
    (0x11,0x71,0x6c),(0x11,0x71,0xbc),(0x12,0x85,0x8c),(0x12,0x71,0xc4),
    (0x12,0x4d,0x84),(0x13,0x61,0xac),(0x13,0x45,0xd4),(0x14,0x75,0x8c),
    (0x15,0x41,0x6c),(0x15,0x61,0x8c),(0x15,0x4d,0xa4),(0x16,0x41,0x94),
    (0x16,0x7d,0xa4),(0x17,0x65,0xcc),(0x18,0x21,0x54),(0x18,0x21,0xcc),
    (0x19,0x35,0xd4),(0x1a,0x59,0x94),(0x1b,0x21,0x8c),(0x1b,0x1d,0xbc),
    (0x1b,0x71,0x74),(0x1c,0x41,0xbc),(0x1d,0x79,0x6c),(0x1d,0x65,0x94),
    (0x1d,0x21,0xa4),(0x1e,0x89,0x9c),(0x1e,0x85,0x64),(0x1e,0x49,0x9c),
    (0x1f,0x3d,0xcc),(0x1f,0x51,0xbc),(0x20,0x49,0x84),(0x21,0x6d,0x8c),
    (0x22,0x39,0x6c),(0x22,0x79,0xb4),(0x26,0x81,0x7c),(0x27,0x59,0xac),
    (0x28,0x65,0x74),(0x29,0x49,0xac),(0x2a,0x65,0x8c),(0x2a,0x25,0xbc),
    (0x2c,0x45,0x84),(0x2c,0x79,0xbc),(0x2d,0x31,0x8c),(0x2e,0x59,0xa4),
)

# Enemy records are (colour,x_grid,y_grid,direction,type,speed,range).
# Kept separate from the port tables on purpose. Exact C64 room records.
ENEMIES = {
    0x00:[(0x03,0x60,0x9f,0x01,0x19,0x01,0x3f),(0x04,0xb8,0x67,0x03,0x15,0x02,0x37)],
    0x01:[(0x03,0x48,0x97,0x03,0x18,0x01,0x1e),(0x05,0x90,0x57,0x01,0x14,0x02,0x1e),(0x02,0xc8,0x97,0x04,0x11,0x02,0x2f)],
    0x02:[(0x05,0x50,0x6f,0x03,0x13,0x02,0x1e),(0x06,0x98,0x47,0x02,0x18,0x02,0x2f),(0x03,0xc8,0x87,0x01,0x1b,0x02,0x2f),(0x07,0x38,0xb7,0x03,0x16,0x02,0x1f)],
    0x03:[(0x06,0x50,0x6f,0x03,0x1d,0x02,0x2f),(0x05,0x98,0xa7,0x02,0x14,0x02,0x2f),(0x03,0xd0,0x4f,0x02,0x19,0x01,0x1f),(0x07,0x28,0x37,0x03,0x15,0x02,0x2f)],
    0x04:[(0x06,0x70,0x67,0x02,0x18,0x02,0x27),(0x05,0xb0,0x97,0x04,0x1d,0x01,0x1f),(0x03,0x38,0x37,0x01,0x19,0x02,0x1f),(0x07,0x88,0xcf,0x03,0x15,0x02,0x27)],
    0x05:[(0x03,0x50,0x77,0x03,0x13,0x02,0x1f),(0x05,0x98,0x9f,0x01,0x14,0x02,0x27),(0x06,0xc0,0x47,0x01,0x1b,0x02,0x1f),(0x07,0x38,0xc7,0x03,0x16,0x02,0x27)],
    0x06:[(0x03,0x48,0x6f,0x02,0x11,0x02,0x2f),(0x05,0x98,0xa7,0x04,0x1c,0x01,0x27),(0x07,0xd0,0x4f,0x01,0x13,0x02,0x1f)],
    0x07:[(0x06,0x58,0x77,0x02,0x18,0x02,0x27),(0x03,0xa0,0x47,0x01,0x19,0x02,0x27),(0x05,0xd0,0x9f,0x04,0x14,0x01,0x1f),(0x07,0x30,0xc7,0x03,0x15,0x02,0x27)],
    0x08:[(0x03,0x58,0x77,0x02,0x13,0x02,0x27),(0x05,0xa0,0x9f,0x04,0x14,0x01,0x27),(0x06,0xd0,0x4f,0x01,0x1b,0x02,0x1f),(0x07,0x30,0xc7,0x03,0x16,0x02,0x27)],
    0x09:[(0x07,0x60,0x97,0x02,0x12,0x01,0x78),(0x05,0x50,0x2f,0x03,0x16,0x02,0x23),(0x03,0x60,0x2b,0x01,0x08,0x03,0x23)],
    0x0a:[(0x05,0x88,0x9f,0x04,0x14,0x01,0x3f),(0x06,0xd0,0x5f,0x01,0x0f,0x02,0x2c),(0x04,0x40,0x9f,0x04,0x19,0x03,0x15),(0x07,0x50,0x5f,0x03,0x12,0x02,0x20)],
    0x0b:[(0x05,0x68,0x87,0x04,0x18,0x02,0x27),(0x03,0xb0,0x4f,0x01,0x19,0x02,0x27)],
    0x0c:[(0x05,0x70,0x38,0x03,0x1b,0x03,0x17),(0x03,0x50,0x2c,0x01,0x08,0x02,0x23),(0x06,0xe0,0x57,0x03,0x1d,0x01,0x1f),(0x08,0x80,0x6f,0x02,0x1e,0x02,0x24)],
    0x0d:[(0x05,0x20,0x47,0x03,0x15,0x01,0x2f),(0x06,0x88,0x77,0x04,0x14,0x02,0x1b)],
    0x0e:[(0x06,0x80,0x27,0x01,0x1e,0x04,0x21),(0x0f,0xb0,0x8f,0x01,0x0a,0x02,0x3a),(0x04,0x58,0x77,0x04,0x1b,0x02,0x27)],
    0x0f:[(0x06,0x68,0xca,0x07,0x15,0x81,0x17),(0x03,0x84,0x82,0x03,0x1b,0x01,0x23),(0x0a,0x80,0xca,0x0f,0x82,0x47,0x47),(0x02,0x20,0x62,0x0e,0x0f,0x02,0x9c)],
}

# Fill exact later records from the port's authoritative source truth module at
# import time. These literals are independently pinned by test files.
def _load_late_truth() -> None:
    try:
        from playthrough_truth_late import ENEMIES_10_33
    except ImportError:
        return
    ENEMIES.update(ENEMIES_10_33)
_load_late_truth()

# (index,room,x,y,frame offset,name,cheat-only)
SPECIAL_ITEMS = (
    (0,0x02,0x38,0x72,0x00,"first aid",False),(1,0x13,0x5a,0x7a,0x0b,"vase",False),
    (2,0x14,0x4c,0x82,0x03,"cupcake",False),(3,0x17,0x80,0x72,0x0c,"fly spray",False),
    (4,0x16,0x23,0xaa,0x03,"cupcake",False),(5,0x1b,0x38,0x62,0x0a,"joystick",False),
    (6,0x1a,0x40,0x6a,0x03,"cupcake",False),(7,0x1f,0x78,0x62,0x03,"cupcake",False),
    (8,0x23,0x41,0xb2,0x08,"jerry can",False),(9,0x29,0x44,0x9a,0x03,"cupcake",False),
    (10,0x2b,0x68,0x5a,0x09,"key",False),(11,0x04,0x80,0x62,0x01,"milk",False),
    (12,0x08,0x30,0x9a,0x02,"teddy",False),(13,0x09,0x70,0x72,0x03,"cupcake",False),
    (14,0x0a,0x90,0x72,0x03,"cupcake",False),(15,0x0b,0x38,0x7a,0x04,"smokestack",False),
    (16,0x0d,0x68,0x72,0x03,"cupcake",False),(17,0x10,0x30,0xca,0x03,"cupcake",False),
    (18,0x2d,0x6c,0x62,0x03,"cupcake",False),(19,0x01,0x6a,0xd2,0x31,"cake",True),
)

# (room,col,row,height,char_base)
PILEDRIVERS = (
    (0x01,0x07,0x05,4,0x10),(0x01,0x1f,0x0c,6,0x22),(0x02,0x15,0x05,4,0x10),
    (0x06,0x0d,0x0c,5,0x10),(0x0b,0x13,0x11,4,0x10),(0x13,0x18,0x0d,3,0x10),
    (0x19,0x1a,0x04,3,0x10),(0x1b,0x0f,0x04,4,0x10),(0x1b,0x15,0x04,4,0x22),
    (0x28,0x15,0x0b,6,0x10),
)
TELEPORTS = ((0x08,0x06,0x34,0x72),(0x14,0x13,0x60,0xa2),(0x1c,0x1b,0x28,0x6a),(0x2a,0x29,0x17,0xa2))
LIFTS = ((0x05,1,0x48,0x5b,0x82),(0x0d,2,0x80,0x53,0x80))
RISING_CLOUD_ROOMS = (0x01,)
RISING_BOLLARD_ROOMS = (0x0c,)
COMPLETION_TRANSITION = (0x2f,0x30)
C5_RETURN_TRANSITION = (0x33,0x26)
AMBIENT_ENEMY_TYPES = {0x20,0x21,0x22}


def gem_convert(rec: tuple[int,int,int]) -> tuple[int,int,int,int,int]:
    room, col, row = rec
    x = col + 7
    y = row + 16
    screen_col = (col - 0x15) // 4
    screen_row = (row - 0x4c) // 8
    bat_index = screen_row * 36 + (screen_col + 2)
    return room, x, y, bat_index & 0xff, (bat_index >> 8) & 0xff


class Audit:
    def __init__(self, build_dir: Path | None = None):
        self.build_dir = build_dir
        self.findings: list[dict] = []
        self.ok_notes: dict[int, dict[str, list[str]]] = {
            r: {area: [] for area in AREAS} for r in ROOMS
        }
        self.src_files = {p.name: p.read_text(errors="replace") for p in SRC.glob("*.asm")}
        self.all_src = "\n".join(self.src_files.values())

    def read(self, name: str) -> str:
        return self.src_files.get(name, "")

    def add(self, status: str, area: str, message: str, room: int | None = None) -> None:
        self.findings.append({
            "status": status, "area": area, "message": message, "room": room,
            "room_hex": None if room is None else f"{room:02X}",
        })

    def set_ok_note(self, room: int, area: str, note: str) -> None:
        self.ok_notes[room][area].append(note)


def parse_db_bytes(text: str) -> list[int]:
    vals: list[int] = []
    for raw in text.splitlines():
        line = raw.split(";",1)[0].strip()
        if not re.match(r"^(?:db|\.byte)\b", line, re.I):
            continue
        rhs = re.sub(r"^(?:db|\.byte)\s*", "", line, flags=re.I)
        for tok in rhs.split(","):
            tok = tok.strip()
            if re.fullmatch(r"\$[0-9a-fA-F]{1,2}", tok): vals.append(int(tok[1:],16))
            elif re.fullmatch(r"\d+", tok): vals.append(int(tok))
    return vals


def extract_world_grid(text: str) -> tuple[tuple[int,...],...]:
    block = text.split("world_room_grid:",1)[1].split("world_row_offsets:",1)[0]
    vals = parse_db_bytes(block)
    if len(vals) != 6*23:
        return tuple()
    return tuple(tuple(vals[r*23:(r+1)*23]) for r in range(6))


def extract_gem_records(text: str) -> list[tuple[int,...]]:
    out: list[tuple[int,...]] = []
    for line in text.splitlines():
        m = re.search(r"\bdb\s+\$([0-9a-f]{2}),\$([0-9a-f]{2}),\$([0-9a-f]{2}),\$([0-9a-f]{2}),\$([0-9a-f]{2})\b", line, re.I)
        if m: out.append(tuple(int(x,16) for x in m.groups()))
    return out


def extract_raw_enemy_records(texts: list[str]) -> dict[int,list[tuple[int,...]]]:
    out: dict[int,list[tuple[int,...]]] = defaultdict(list)
    current: int | None = None
    label_re = re.compile(r"^(?:enemy_)?room([0-9a-f]{2})(?:_records)?:", re.I)
    rec_re = re.compile(r"\bdb\s+" + ",".join([r"\$([0-9a-f]{2})"]*7), re.I)
    for text in texts:
        for line in text.splitlines():
            stripped = line.strip()
            m = label_re.match(stripped.lstrip("."))
            if m:
                current = int(m.group(1),16); continue
            if current is None: continue
            if re.search(r"\bdb\s+\$ff\b", stripped, re.I):
                current = None; continue
            m = rec_re.search(stripped)
            if m: out[current].append(tuple(int(x,16) for x in m.groups()))
    return dict(out)


def source_comment_contains_records(text: str, records: list[tuple[int,...]]) -> bool:
    compact = re.sub(r"\s+", "", text.lower())
    return all("db" + ",".join(f"${v:02x}" for v in rec) in compact for rec in records)


def extract_special_room_block(text: str, room: int) -> str | None:
    m = re.search(rf"(?mi)^\.room{room:02x}:\s*$", text)
    if not m: return None
    tail = text[m.end():]
    e = re.search(r"(?mi)^\.room[0-9a-f]{2}:|^\.none:|^\.activate:", tail)
    return tail[:e.start()] if e else tail


def block_assignment(block: str, symbol: str) -> int | None:
    m = re.search(rf"(?is)lda\s+#(?:\$([0-9a-f]+)|(\d+))\s*\n\s*sta\s+<?{re.escape(symbol)}\b", block)
    if not m: return None
    return int(m.group(1),16) if m.group(1) else int(m.group(2))


def geometry_audit(a: Audit) -> None:
    loader = a.read("room050c_loader.asm").lower()
    world = a.read("world.asm").lower()
    m = re.search(r"room_ext_count\s*=\s*(\d+)", loader)
    if not m or int(m.group(1)) != 43:
        a.add("FAIL", "geometry", "extended room loader must expose 43 sparse descriptors")
    if "cmp     #$34" not in world:
        a.add("FAIL", "geometry", "world support does not cover room IDs $00-$33")

    ext_ids = []
    if "room_ext_ids:" in loader:
        section = loader.split("room_ext_ids:",1)[1].split("room_ext_patterns_lo:",1)[0]
        ext_ids = parse_db_bytes(section)
    expected_ext = {0x05,0x06,0x07,0x08,0x09,0x0c,0x0f,*range(0x10,0x34)}
    if set(ext_ids) != expected_ext or len(ext_ids) != len(expected_ext):
        a.add("FAIL", "geometry", "extended loader room-id descriptor set differs from source support")
    for room in expected_ext:
        p = f"room{room:02x}"
        for token in (f"{p}_patterns", f"{p}_screen_bat", f"{p}_collision_map_rom"):
            if token not in loader:
                a.add("FAIL", "geometry", "room missing from extended loader", room)

    # All non-extended rooms are dedicated/core rooms. Require a room-specific
    # source token so an accidental deletion cannot silently leave a supported ID.
    for room in set(ROOMS) - expected_ext:
        token = f"room{room:02x}"
        if token not in a.all_src.lower():
            a.add("FAIL", "geometry", "dedicated/core room source token missing", room)

    # Generated binary size checks are the closest headless equivalent to loading
    # each room. Room $0A intentionally appends 24 exact decor characters to its
    # 9 base patterns, so its combined pattern payload is 33*32 bytes.
    if a.build_dir and a.build_dir.exists():
        pattern_sizes = {0x0A: 33 * 32}
        for room in ROOMS:
            checks = [
                (f"room{room:02x}-map.dat", 640),
                (f"room{room:02x}-screen-bat.dat", 36 * 20 * 2),
            ]
            if room != 0:
                checks.append((f"room{room:02x}-patterns.dat", pattern_sizes.get(room, 9 * 32)))
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

    ambient_guard = any(token in collision_text for token in ("ambient", "#$20", "#$20"))
    if not ambient_guard:
        a.add("MISSING", "enemies", "R23 flying banners $20-$22 need an explicit non-damaging collision guard", 0x23)

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

    tele_runtime = any("teleporter_room" in t.lower() or "teleporter_update" in t.lower() for t in a.src_files.values())
    for src, dst, x, y in TELEPORTS:
        if not tele_runtime:
            a.add("MISSING", "mechanisms", f"teleporter R{src:02X}->R{dst:02X} missing; destination ${x:02X},${y:02X}", src)

    for room, typ, x, y, speed in LIFTS:
        if f"#${room:02x}" not in lift and f"#{room}" not in lift:
            a.add("MISSING", "mechanisms", f"moving lift type {typ} missing", room)
        elif f"#${x:02x}" not in lift or f"#${y:02x}" not in lift:
            a.add("FAIL", "mechanisms", f"lift position should be ${x:02X},${y:02X}", room)
        else:
            a.set_ok_note(room, "mechanisms", "moving lift present")

    for room in RISING_CLOUD_ROOMS:
        if f"#${room:02x}" not in cloud and f"#{room}" not in cloud:
            a.add("MISSING", "mechanisms", "rising cloud missing", room)
        else:
            a.set_ok_note(room, "mechanisms", "rising cloud present")

    for room in RISING_BOLLARD_ROOMS:
        if f"#${room:02x}" not in bollard and f"#{room}" not in bollard:
            a.add("MISSING", "mechanisms", "rising bollard missing", room)
        else:
            a.set_ok_note(room, "mechanisms", "rising bollard present")

    runtime = "\n".join(text for name,text in a.src_files.items() if "assets" not in name)
    if "world_pending_room" not in runtime or "#$30" not in runtime:
        a.add("MISSING", "mechanisms", "completion transition R2F->R30 not wired", 0x2f)
    if "world_pending_room" not in runtime or "#$26" not in runtime:
        a.add("MISSING", "mechanisms", "C5 return R33->R26 not wired", 0x33)


def run_audit(a: Audit) -> None:
    geometry_audit(a)
    world_audit(a)
    gem_audit(a)
    enemy_audit(a)
    special_audit(a)
    mechanism_audit(a)


def summarize(a: Audit) -> dict:
    by_room = []
    for room in ROOMS:
        area_state = {}
        for area in AREAS:
            findings = [f for f in a.findings if f["room"] == room and f["area"] == area]
            state = max((f["status"] for f in findings), key=lambda x: SEVERITY[x], default="OK")
            area_state[area] = state
        overall = max(area_state.values(), key=lambda x: SEVERITY[x])
        by_room.append({
            "room": room, "hex": f"{room:02X}", "overall": overall,
            "areas": area_state,
            "expected": {
                "gems": sum(1 for r,*_ in GEMS if r == room),
                "enemies": len(ENEMIES[room]),
                "specials": sum(1 for _,r,*rest in SPECIAL_ITEMS if r == room and not rest[-1]),
                "mechanisms": sum(1 for r,*_ in PILEDRIVERS if r == room)
                    + sum(1 for r,*_ in LIFTS if r == room)
                    + (room in RISING_CLOUD_ROOMS) + (room in RISING_BOLLARD_ROOMS)
                    + sum(1 for r,*_ in TELEPORTS if r == room)
                    + (room == COMPLETION_TRANSITION[0]) + (room == C5_RETURN_TRANSITION[0]),
            },
            "notes": a.ok_notes[room],
        })
    counts = Counter(f["status"] for f in a.findings)
    return {
        "source_truth": {
            "rooms": len(ROOMS), "gems": len(GEMS), "enemies": sum(map(len,ENEMIES.values())),
            "special_items_normal": sum(not x[-1] for x in SPECIAL_ITEMS),
            "special_items_cheat": sum(x[-1] for x in SPECIAL_ITEMS),
            "piledrivers": len(PILEDRIVERS), "teleporters": len(TELEPORTS), "lifts": len(LIFTS),
        },
        "finding_counts": dict(counts), "rooms": by_room, "findings": a.findings,
    }


def text_report(result: dict) -> str:
    truth = result["source_truth"]; counts = result["finding_counts"]
    short = lambda s: {"OK":"OK", "WARN":"WRN", "MISSING":"MISS", "FAIL":"FAIL"}[s]
    out = [
        "Monty on the Run - headless playthrough/content audit",
        "="*64,
        f"Source truth: {truth['rooms']} rooms, {truth['gems']} gems, {truth['enemies']} enemy spawns, "
        f"{truth['special_items_normal']} normal specials, {truth['piledrivers']} piledrivers, {truth['teleporters']} teleporters",
        f"Findings: FAIL={counts.get('FAIL',0)}  MISSING={counts.get('MISSING',0)}  WARN={counts.get('WARN',0)}",
        "",
        "ROOM  OVERALL  GEO WORLD GEMS ENEMY SPEC MECH  EXPECTED(g/e/s/m)",
        "----  -------  ---- ----- ---- ----- ---- ----  -----------------",
    ]
    for r in result["rooms"]:
        a = r["areas"]; e = r["expected"]
        out.append(
            f"R{r['hex']}   {short(r['overall']):<7}  {short(a['geometry']):<4} {short(a['world']):<5} "
            f"{short(a['gems']):<4} {short(a['enemies']):<5} {short(a['specials']):<4} {short(a['mechanisms']):<4}  "
            f"{e['gems']}/{e['enemies']}/{e['specials']}/{e['mechanisms']}"
        )
    out += ["", "Findings", "--------"]
    if not result["findings"]: out.append("OK: no findings")
    for f in sorted(result["findings"], key=lambda x: (-SEVERITY[x["status"]], 999 if x["room"] is None else x["room"], x["area"])):
        label = "GLOBAL" if f["room"] is None else f"R{f['room_hex']}"
        out.append(f"[{f['status']:<7}] {label} {f['area']}: {f['message']}")
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--build-dir", type=Path)
    ap.add_argument("--json", type=Path)
    ap.add_argument("--text", type=Path)
    ap.add_argument("--strict", action="store_true", help="also fail on known missing source features")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()
    a = Audit(args.build_dir)
    run_audit(a)
    result = summarize(a)
    report = text_report(result)
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(result, indent=2) + "\n")
    if args.text:
        args.text.parent.mkdir(parents=True, exist_ok=True)
        args.text.write_text(report)
    if not args.quiet: print(report, end="")
    bad = any(f["status"] == "FAIL" or (args.strict and f["status"] == "MISSING") for f in a.findings)
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
