# SNES porting rules

## Ownership boundary

`snes/**` is SNES-owned. Everything outside `snes/**` is upstream/reference and must remain byte-for-byte untouched by SNES commits.

This is intentionally stronger than merely avoiding conflicts: no SNES helper is allowed to emit generated files into `src/`, `tools/`, `build/`, or any other PCE/C64 path.

## Upstream model

`main` is the canonical PCE line. `snes/parallel-port` follows it, never the other way around.

For every meaningful PCE gameplay change:

1. Sync `main` into `snes/parallel-port`.
2. Read the PCE change as behavioural/reference evidence.
3. Reproduce the behaviour independently under `snes/`.
4. Add SNES-local tests or fixtures when useful.
5. Run `make guard` before committing.

Platform-specific PCE implementation details are not mechanically copied when the SNES has a cleaner native equivalent. HuC6280 MPR banking, VDC BAT/SAT writes, and PCE VRAM upload paths should become SNES WRAM/ROM addressing, PPU tilemaps/OAM, and DMA respectively.

## Shared semantics to preserve

- C64 gameplay coordinate system.
- Room IDs and world topology.
- 32x20 logical room cells.
- Tile/property collision semantics.
- Jump and movement behaviour.
- Enemy/mechanism/item state and ordering.
- PAL gameplay cadence as the reference speed.

## Forbidden SNES changes

SNES commits must not modify or delete any file outside `snes/`, including root-level build/release files. A future exception requires an explicit policy change first.
