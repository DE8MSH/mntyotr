# SNES parallel-port roadmap

## S0 — isolated boot scaffold — DONE

- 65816 native-mode reset path.
- 32 KiB LoROM image/header/vectors.
- forced-blank PPU initialization.
- NMI frame counter.
- PAL-first logical tick; NTSC 5/6 gate.
- branch-isolation guard.

## S1 — video proof: Room $00 — DONE

- Mode 1 BG1 at 256x224.
- 32x20 room playfield mapped 1:1 to 256x160 pixels.
- build-local SNES 4bpp/CGRAM conversion.
- exact verified Room `$00` RLE base geometry.
- Room `$00` base tiles and decor converted to native SNES assets.
- side-gutter-only decor deliberately clipped to the 32-column SNES viewport.
- LoROM checksum patch and static ROM smoke test.
- Linux Mint 22 install/build scripts.

## S2 — Monty proof — NEXT

- convert authentic Monty frames to SNES 4bpp sprite tiles.
- OAM path, initially simple forced-blank/static uploads; DMA once frame handling grows.
- preserve C64 internal coordinates; SNES renderer owns only the coordinate bridge.
- SNES controller input mapped into an SNES-local compatibility state.
- first controllable Room `$00` movement without world transitions.

## S3 — gameplay core

- movement, jump sweep, collision, room edges and world transitions.
- logical 32x20 collision state in WRAM, never derived from PPU tilemap state.
- score/lives/checkpoint state.
- compare behaviour room-by-room with the current PCE branch.

## S4 — mechanisms/enemies/items

Port in the same functional order as the PCE upstream, always after syncing it. Prefer data-driven SNES tables and DMA over PCE-style bank-switch structures.

## S5 — world/art parity

- expand rooms in the same order as the PCE port.
- preserve C64-semantic room IDs, properties, enemy records and mechanism state.
- SNES-specific handling for the 256-pixel viewport; do not distort gameplay coordinates to imitate the PCE's 320-pixel output mode.

## S6 — sound

SPC700/DSP backend after gameplay parity. Sound remains independent from the PCE PSG implementation.
