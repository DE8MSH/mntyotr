#!/usr/bin/env python3
"""Extract all Monty C64 room data into normalized JSON for bulk PCE porting."""
from __future__ import annotations
import argparse, json, re
from pathlib import Path

ROOM_COUNT = 0x34
ROOM_CELLS = 640


def byte_values(block: str) -> list[int]:
    vals=[]
    for line in block.splitlines():
        code=line.split('//',1)[0]
        vals.extend(int(x,16) for x in re.findall(r'\$([0-9a-fA-F]{2})', code))
    return vals


def named_streams(text: str, ns: str) -> dict[int,list[int]]:
    sec=text.split(f'.namespace {ns} {{',1)[1].split(f'}}  // .namespace {ns}',1)[0]
    out={}
    pat=r'(?m)^rm_([0-9a-f]{2}):[^\n]*\n((?:\s*\.byte[^\n]*\n)+)'
    for m in re.finditer(pat, sec):
        out[int(m.group(1),16)]=byte_values(m.group(2))
    return out


def trim_tilemap(vals: list[int]) -> list[int]:
    for i in range(len(vals)-1):
        if vals[i]==0xff and vals[i+1]==0xff:
            return vals[:i+2]
    raise ValueError('tilemap missing FF FF terminator')


def decode_tilemap(vals: list[int]) -> list[int]:
    out=[]; i=0
    while i < len(vals):
        if i+1 < len(vals) and vals[i]==0xff and vals[i+1]==0xff:
            break
        b=vals[i]; i+=1
        out.extend([b & 0x0f] * ((b >> 4) + 1))
    return out


def parse_enemy_streams(text: str) -> dict[int,list[list[int]]]:
    sec=text.split('.namespace enemy_spawn {',1)[1].split('}  // .namespace enemy_spawn',1)[0]
    out={}
    pat=r'(?m)^rm_([0-9a-f]{2}):[^\n]*\n((?:\s*\.byte[^\n]*\n)+)'
    for m in re.finditer(pat, sec):
        records=[]
        for line in m.group(2).splitlines():
            vals=byte_values(line)
            if vals == [0xff]: break
            if len(vals)!=7: raise ValueError(f'room {m.group(1)} bad enemy record')
            records.append(vals)
        out[int(m.group(1),16)]=records
    return out


def parse_room_defs(text: str) -> dict[int,dict]:
    sec=text.split('room_defs:',1)[1]
    rows=[]
    for line in sec.splitlines():
        if '.byte' not in line: continue
        vals=byte_values(line)
        if len(vals)==16: rows.append(vals)
        if len(rows)==ROOM_COUNT: break
    if len(rows)!=ROOM_COUNT: raise ValueError(f'expected {ROOM_COUNT} room defs, got {len(rows)}')
    return {i:{'tile_ids':r[:8], 'colours':r[8:]} for i,r in enumerate(rows)}


def parse_tile_library(text: str) -> list[list[int]]:
    sec=text.split('tile_library:',1)[1]
    tiles=[]
    for line in sec.splitlines():
        if '.byte' not in line: continue
        vals=byte_values(line)
        if len(vals)==8: tiles.append(vals)
        if len(tiles)==121: break
    if len(tiles)!=121: raise ValueError(f'expected 121 tiles, got {len(tiles)}')
    return tiles


def tile_property(code: int) -> int:
    if 0x47 <= code < 0x4e: return 1
    if code < 0x27: return 1
    if code < 0x47: return 2
    if code < 0x56: return 4
    if code < 0x77: return 3
    return 0


def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument('--room-data', type=Path, required=True)
    ap.add_argument('--tiles', type=Path, required=True)
    ap.add_argument('--out', type=Path, required=True)
    a=ap.parse_args()
    rd=a.room_data.read_text(); tt=a.tiles.read_text()
    tm=named_streams(rd,'tilemap'); en=parse_enemy_streams(rd); defs=parse_room_defs(rd); lib=parse_tile_library(tt)
    if set(tm)!=set(range(ROOM_COUNT)) or set(en)!=set(range(ROOM_COUNT)):
        raise ValueError('room id coverage is not exactly 00-33')
    rooms={}
    enemy_types=set()
    for rid in range(ROOM_COUNT):
        stream=trim_tilemap(tm[rid]); cells=decode_tilemap(stream)
        if len(cells)!=ROOM_CELLS: raise ValueError(f'room {rid:02x}: {len(cells)} cells')
        if len(en[rid])>4: raise ValueError(f'room {rid:02x}: >4 enemies')
        ids=defs[rid]['tile_ids']
        room_tiles=[lib[x] for x in ids]
        props=[tile_property(x) for x in ids]
        for rec in en[rid]: enemy_types.add(rec[4])
        rooms[f'{rid:02x}']={
            'rle':stream, 'decoded_cells':len(cells), 'tile_ids':ids,
            'colours':defs[rid]['colours'], 'properties':props,
            'tile_bitmaps':room_tiles, 'enemies':en[rid],
        }
    payload={'room_count':ROOM_COUNT,'enemy_type_ids':[f'{x:02x}' for x in sorted(enemy_types)],'rooms':rooms}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(payload,indent=2)+'\n')
    print(f'OK: {ROOM_COUNT} rooms, all {ROOM_CELLS} cells; {len(enemy_types)} enemy/entity types')

if __name__=='__main__': main()
