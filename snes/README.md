# Monty on the Run — SNES parallel port

This directory is the isolated Super Nintendo port of the PC Engine project.

## Hard isolation contract

- The canonical PCE development line remains `main`.
- The SNES line lives on `snes/parallel-port`.
- SNES commits may only change files below `snes/`.
- SNES work must never modify, replace, rename, delete, or regenerate root-level PCE/C64 source files.
- In particular, `src/`, `tools/`, root build scripts, documentation, and PCE generated data are read-only reference material from the SNES branch's point of view.
- PCE development flows one way into SNES: merge/rebase the latest `main` into `snes/parallel-port`, then adapt the equivalent behaviour under `snes/`.
- Do not merge SNES implementation commits back into PCE `main` unless this isolation policy is intentionally changed later.

Run `make guard` before every SNES commit. The guard fails if the SNES branch contains a committed change outside `snes/` relative to its current merge base with `main`.

## Initial architecture

The SNES port preserves the same C64-semantic gameplay model used by the PCE port: C64 coordinates, room IDs, 32x20 logical room geometry, tile properties, PAL-oriented gameplay timing, and behaviour-first regression targets. Platform rendering is separate.

The first target is deliberately small and safe: a bootable LoROM image with 65816 startup, Mode-1-ready PPU state, NMI frame pacing, and a PAL/NTSC logical clock scaffold. No PCE file is part of the SNES build.

## Build

Requirements: `ca65` and `ld65` from cc65.

```sh
cd snes
make                # PAL-first build
make REGION=ntsc    # NTSC build; 5/6 VBlank logical tick gate
```

Output:

```text
snes/build/monty.sfc
```

## Sync with PCE

The intended long-lived workflow is:

```sh
git fetch origin
git switch snes/parallel-port
git merge --no-edit origin/main
cd snes
make guard
```

After the merge, inspect new PCE gameplay changes and reproduce only the relevant behaviour in SNES-owned files. Never resolve a sync by overwriting PCE files from SNES.
