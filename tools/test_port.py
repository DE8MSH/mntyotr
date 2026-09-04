#!/usr/bin/env python3
"""Fast deterministic checks for the C64->PCE port data path."""
import struct
from pathlib import Path
from room_rle import ROOM00_RLE, ROOM_CELLS, decode_room, make_bat, make_screen_bat, CHR_GAME
from monty_sprite import WALK_L, WALK_R, CLIMB, FRAME_BYTES, build, c64_frame_pixels

JUMP_UP=[0,3,2,2,1,2,1,1,0,1,1,1,0,1,1,1,0,1,0,1,0,0]
JUMP_DOWN=[1,0,0,0,1,0,1,0,1,0,2,1,2,1,2,2,0]
ROOM00_PROPS=[1,1,1,2,1,1,1,1]
ROOT=Path(__file__).resolve().parents[1]

def pal_ticks(vblanks):
 phase=ticks=0
 for _ in range(vblanks):
  phase+=5
  if phase>=6: phase-=6; ticks+=1
 return ticks

def words(blob):
 return list(struct.unpack('<'+'H'*(len(blob)//2),blob))

def c64_screen_xy(monty_x,monty_y):
 return 2*(monty_x-0x0c), (monty_y+1)-0x32

def pce_sat_xy(monty_x,monty_y):
 x,y=c64_screen_xy(monty_x,monty_y)
 return x+32,y+64

def sat_x_bytes(monty_x,offset):
 value=2*monty_x+offset
 return value&0xff,(value>>8)&0x03

def screen_to_room(col,row):
 if not 3 <= row < 23: return None
 if col in (2,3): return 0,row-3
 if 4 <= col < 36: return col-4,row-3
 if col in (36,37): return 31,row-3
 return None

def room00_property(cells,col,row):
 pos=screen_to_room(col,row)
 if pos is None: return 0
 x,y=pos
 code=cells[y*32+x]
 if code==0 or code>=9: return 0
 return ROOM00_PROPS[code-1]

def left_blocked(cells,monty_x,monty_y):
 dx=(monty_x-0x0c)&0xff
 if dx&3: return False
 col=(dx>>2)-1
 row=((monty_y-0x32)&0xff)>>3
 samples=2 if (((monty_y-0x32)&0xff)&7)==0 else 3
 return any(room00_property(cells,col,row+i)==1 for i in range(samples))

def below_blocked(cells,monty_x,monty_y):
 dy=(monty_y-0x32)&0xff
 if dy&7: return False
 row=(dy>>3)+2
 dx=(monty_x-0x0c)&0xff
 col=dx>>2
 samples=2 if (dx&3)==0 else 3
 return any(room00_property(cells,col+i,row) in (1,2,3) for i in range(samples))

def parse_world_grid():
 text=(ROOT/'src/world.asm').read_text()
 block=text.split('world_room_grid:',1)[1]
 rows=[]
 for line in block.splitlines():
  line=line.strip()
  if not line.startswith('db '):
   if rows: break
   continue
  vals=[]
  for tok in line[3:].split(','):
   tok=tok.strip()
   if tok.startswith('$'):
    vals.append(int(tok[1:],16))
  rows.append(vals)
 return rows

def main():
 cells=decode_room(ROOM00_RLE)
 assert len(cells)==ROOM_CELLS==640 and all(0<=x<=15 for x in cells)
 assert len(JUMP_UP)==22 and sum(JUMP_UP)==20
 assert len(JUMP_DOWN)==17 and sum(JUMP_DOWN)==14
 assert pal_ticks(6)==5 and pal_ticks(60)==50 and pal_ticks(600)==500

 world=parse_world_grid()
 assert len(world)==6, f'world grid rows: expected 6, got {len(world)}'
 assert all(len(row)==23 for row in world), f'world row lengths: {[len(row) for row in world]}'
 assert world[2][0x15]==0 and world[2][0x14]==1 and world[2][0x16]==0xff
 assert world[2][0x04]==0x33 and all(0x30 not in row for row in world)

 bat=words(make_bat(cells))
 assert len(bat)==640
 assert (bat[0]&0x0fff)==CHR_GAME+cells[0]
 assert (bat[0]>>12)==cells[0]
 screen=words(make_screen_bat(cells))
 assert len(screen)==36*20
 for y in range(20):
  src=cells[y*32:(y+1)*32]
  row=screen[y*36:(y+1)*36]
  assert row[0]==row[1]==row[2]
  assert row[33]==row[34]==row[35]
  assert [w&0x0fff for w in row[2:34]] == [CHR_GAME+t for t in src]

 # Original start before gravity settle.
 assert c64_screen_xy(0x86,0xb0)==(244,127)
 assert pce_sat_xy(0x86,0xb0)==(276,191)
 assert sat_x_bytes(0x86,8)==(0x14,0x01)
 assert sat_x_bytes(0x86,24)==(0x24,0x01)
 assert screen_to_room(4,3)==(0,0)
 assert screen_to_room(35,22)==(31,19)
 assert screen_to_room(2,3)==(0,0)
 assert screen_to_room(37,22)==(31,19)
 assert screen_to_room(0,3) is None and screen_to_room(4,2) is None

 # Room-$00 doorway: C64 starts Y=$b0 but CheckTileBelow is clear until Y=$b2.
 # At doorway X=$78, Y=$b0 samples the solid wall tile above the opening;
 # post-settle Y=$b2 samples only the opening and must permit left movement.
 assert not below_blocked(cells,0x86,0xb0)
 assert not below_blocked(cells,0x86,0xb1)
 assert below_blocked(cells,0x86,0xb2)
 assert left_blocked(cells,0x78,0xb0)
 assert not left_blocked(cells,0x78,0xb2)

 expected_starts={
  'WALK_L': bytes.fromhex('02 00 00'),
  'WALK_R': bytes.fromhex('00 40 00'),
  'CLIMB':  bytes.fromhex('07 80 00'),
 }
 for name,frames in (("WALK_L",WALK_L),("WALK_R",WALK_R),("CLIMB",CLIMB)):
  assert len(frames) % FRAME_BYTES == 0
  assert len(frames)//FRAME_BYTES == 4
  for i in range(4):
   frame=frames[i*FRAME_BYTES:(i+1)*FRAME_BYTES]
   assert frame[:3] == expected_starts[name], f'{name} frame {i} starts {frame[:3].hex()}'
   pixels=c64_frame_pixels(frame)
   assert len(pixels)==21 and all(len(row)==24 for row in pixels)
  spr=build(frames)
  assert len(spr)==2048 and any(spr)
 print('OK: room/world; doorway settle/collision; corrected SAT XY; 12 Monty frames')

if __name__=='__main__': main()
