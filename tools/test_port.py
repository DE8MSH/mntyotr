#!/usr/bin/env python3
"""Fast deterministic checks for the C64->PCE port data path."""
import struct
from room_rle import ROOM00_RLE, ROOM_CELLS, decode_room, make_bat, make_screen_bat, CHR_GAME
from monty_sprite import WALK_L, WALK_R, CLIMB, FRAME_BYTES, build, c64_frame_pixels

JUMP_UP=[0,3,2,2,1,2,1,1,0,1,1,1,0,1,1,1,0,1,0,1,0,0]
JUMP_DOWN=[1,0,0,0,1,0,1,0,1,0,2,1,2,1,2,2,0]
WORLD=[
[0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x23,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff],
[0xff,0x2f,0x2e,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x22,0xff,0xff,0xff,0xff,0xff,0xff,0x06,0x07,0x08,0x09,0xff,0xff],
[0x2d,0x2c,0x27,0x26,0x33,0x32,0x31,0x25,0x24,0x20,0x21,0xff,0xff,0xff,0xff,0xff,0x05,0x04,0x03,0x02,0x01,0x00,0xff],
[0x2b,0x2a,0x28,0x29,0xff,0xff,0xff,0xff,0xff,0x1f,0xff,0xff,0x1b,0xff,0xff,0x0f,0x0c,0x0d,0x0e,0x0b,0x0a,0xff,0xff],
[0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x1e,0xff,0x1a,0x19,0x18,0xff,0x10,0x11,0xff,0xff,0xff,0xff,0xff,0xff],
[0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x1d,0x1c,0x17,0x16,0x15,0x14,0x12,0x13,0xff,0xff,0xff,0xff,0xff,0xff]]
ROOM00_PROPERTIES=[1,1,1,2,1,1,1,1]

def pal_ticks(vblanks):
 phase=ticks=0
 for _ in range(vblanks):
  phase+=5
  if phase>=6: phase-=6; ticks+=1
 return ticks

def words(blob):
 return list(struct.unpack('<'+'H'*(len(blob)//2),blob))

def c64_screen_xy(monty_x,monty_y):
 return 2*(monty_x-0x0c), monty_y-0x32

def pce_sat_xy(monty_x,monty_y):
 x,y=c64_screen_xy(monty_x,monty_y)
 return x+32,y+64

def screen_to_room(col,row):
 if not 3 <= row < 23: return None
 if col in (2,3): return 0,row-3
 if 4 <= col < 36: return col-4,row-3
 if col in (36,37): return 31,row-3
 return None

def tile_property(screen_code):
 if screen_code==0 or screen_code>=9: return 0
 return ROOM00_PROPERTIES[screen_code-1]

def main():
 cells=decode_room(ROOM00_RLE)
 assert len(cells)==ROOM_CELLS==640 and all(0<=x<=15 for x in cells)
 assert len(JUMP_UP)==22 and sum(JUMP_UP)==20
 assert len(JUMP_DOWN)==17 and sum(JUMP_DOWN)==14
 assert pal_ticks(6)==5 and pal_ticks(60)==50 and pal_ticks(600)==500
 assert len(WORLD)==6 and all(len(row)==23 for row in WORLD)
 assert WORLD[2][0x15]==0 and WORLD[2][0x14]==1 and WORLD[2][0x16]==0xff
 assert WORLD[2][0x04]==0x33 and all(0x30 not in row for row in WORLD)

 # DrawRoomPlayfield RLE nibble is already the C64 screen code. Code 0 must
 # remain blank; SetupTileGraphics separately installs custom chars 1..8.
 bat=words(make_bat(cells))
 assert len(bat)==640
 assert (bat[0]&0x0fff)==CHR_GAME+cells[0]
 assert (bat[0]>>12)==cells[0]
 zero_i=cells.index(0)
 assert (bat[zero_i]&0x0fff)==CHR_GAME and (bat[zero_i]>>12)==0
 screen=words(make_screen_bat(cells))
 assert len(screen)==36*20
 for y in range(20):
  src=cells[y*32:(y+1)*32]
  row=screen[y*36:(y+1)*36]
  assert row[0]==row[1]==row[2]
  assert row[33]==row[34]==row[35]
  assert [w&0x0fff for w in row[2:34]] == [CHR_GAME+t for t in src]

 # Exact GetTileFlag convention: blank/special chars are non-solid; 1..8 map
 # to room property slot code-1. This is crucial for movement through black air.
 assert tile_property(0)==0
 assert tile_property(1)==1
 assert tile_property(4)==2
 assert tile_property(5)==1
 assert tile_property(9)==0

 assert c64_screen_xy(0x86,0xb0)==(244,126)
 assert pce_sat_xy(0x86,0xb0)==(276,190)
 assert screen_to_room(4,3)==(0,0)
 assert screen_to_room(35,22)==(31,19)
 assert screen_to_room(2,3)==(0,0)
 assert screen_to_room(37,22)==(31,19)
 assert screen_to_room(0,3) is None and screen_to_room(4,2) is None

 for name,frames in (("WALK_L",WALK_L),("WALK_R",WALK_R),("CLIMB",CLIMB)):
  assert len(frames) % FRAME_BYTES == 0, f'{name}: {len(frames)} bytes is not a multiple of FRAME_BYTES={FRAME_BYTES}'
  assert len(frames)//FRAME_BYTES == 4, f'{name}: expected 4 frames, got {len(frames)//FRAME_BYTES}'
  for i in range(4):
   frame=frames[i*FRAME_BYTES:(i+1)*FRAME_BYTES]
   pixels=c64_frame_pixels(frame)
   assert len(pixels)==21 and all(len(row)==24 for row in pixels)
  spr=build(frames)
  assert len(spr)==2048 and any(spr)
 print('OK: direct C64 screen codes + GetTileFlag; screen/collision/XY; jump/clock/world; 12 sprite frames')

if __name__=='__main__': main()
