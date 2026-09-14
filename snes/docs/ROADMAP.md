# SNES parallel-port roadmap

## S0 — isolated boot scaffold

- 65816 native-mode reset path.
- 32 KiB LoROM image/header/vectors.
- Forced-blank PPU initialization and visible backdrop.
- NMI frame counter.
- PAL-first logical tick; NTSC 5/6 gate.
- branch-isolation guard.

## S1 — video proof: Room $00

- Mode 1 BG1 at 256x224.
- 32x20 room playfield mapped 1:1 to 256x160 pixels.
- SNES 4bpp/CGRAM conversion generated only under `snes/build/`.
- room-$00 tilemap and decor matching the current PCE behavioural/art reference.

## S2 — Monty proof

- Convert authentic Monty frames to SNES sprite tiles.
- OAM/DMA path.
- preserve C64 internal coordinates; SNES renderer owns only the coordinate bridge.
- controller input mapped into an SNES-local compatibility state.

## S3 — gameplay core

- movement, jump sweep, collision, room edges and world transitions.
- score/lives/checkpoint state.
- compare behaviour room-by-room with the current PCE branch.

## S4 — mechanisms/enemies/items

Port in the same functional order as PCE `main`, always after syncing upstream. Prefer data-driven SNES tables and DMA over PCE-style bank-switch structures.

## S5 — sound

SPC700/DSP backend after gameplay parity. Sound remains independent from the PCE PSG implementation.
