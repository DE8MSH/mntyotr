# Monty on the Run — SNES parallel port

This directory is the isolated Super Nintendo port of the PC Engine project.
The PCE port remains the behavioural reference; the SNES implementation follows it without modifying or depending on PCE/C64 build files.

## Hard isolation contract

- Canonical PCE development line: `main` (or an explicitly selected PCE upstream branch).
- SNES development line: `snes/parallel-port`.
- SNES commits may only change files below `snes/`.
- SNES work must never modify, replace, rename, delete, or regenerate root-level PCE/C64 files.
- `src/`, `tools/`, root build scripts, documentation and generated PCE data are read-only reference material from the SNES branch's point of view.
- PCE development flows one way into SNES: sync the PCE branch, then independently reproduce the equivalent behaviour below `snes/`.
- The SNES build reads no PCE source/tool file. Verified C64/PCE semantics needed by SNES are copied into SNES-owned generators/fixtures.

Run `make guard` before every SNES commit. `./build.sh` runs the stricter working-tree guard automatically.

## Current status

S0 boot bring-up is complete and S1 video proof is implemented:

- 65816 native-mode startup.
- 32 KiB headerless LoROM image with vectors and patched checksum.
- PAL-first NMI frame pacing; NTSC uses the same simple 5/6 logical-tick gate as the PCE bring-up.
- SNES Mode 1, BG1 only.
- Room `$00` decoded from the verified 640-cell C64-semantic RLE.
- 32x20 gameplay playfield rendered 1:1 as 256x160 pixels inside 256x224.
- Native SNES 4bpp tiles and BGR555 CGRAM generated at build time.
- Room `$00` decor is included; decor that exists only in the C64/PCE side gutters is clipped because the SNES viewport is the 32-column gameplay playfield.

Next milestone: Monty sprite conversion, OAM and controller input.

## Linux Mint 22 install

Linux Mint 22 is based on Ubuntu 24.04/Noble. The required `cc65` package provides `ca65` and `ld65`.

From the repository root:

```sh
git switch snes/parallel-port
cd snes
./install.sh
```

`install.sh` installs:

```text
cc65
make
python3
git
```

It then performs a PAL smoke build. Root is not required if `sudo` is available.

Manual equivalent:

```sh
sudo apt-get update
sudo apt-get install -y cc65 make python3 git
cd snes
./build.sh pal
```

## Build

PAL build (default/reference):

```sh
cd snes
./build.sh
# or
./build.sh pal
```

NTSC build:

```sh
./build.sh ntsc
```

Make can also be used directly:

```sh
make
make REGION=ntsc
make assets
make smoke
make clean
```

Output:

```text
snes/build/monty.sfc
```

Generated SNES-only assets are kept under:

```text
snes/build/assets/
```

No generated file is written into the PCE/C64 trees.

## Build pipeline

`tools/room00_assets.py` produces:

```text
room00.chr   50 native SNES 4bpp tiles (base room + decor)
room00.map   32x32 SNES BG1 tilemap containing the 32x20 room
c64.pal      16-colour SNES BGR555 palette
```

`ca65` assembles the 65816 source, `ld65` links one 32 KiB LoROM bank, then `tools/fix_checksum.py` patches the header checksum and `tools/test_rom.py` performs a static smoke test.

## Sync with the PCE branch

Normal sync from PCE `main`:

```sh
git switch snes/parallel-port
cd snes
./sync-pce.sh
```

To follow another temporary PCE development branch:

```sh
PCE_BRANCH=feature/some-pce-work ./sync-pce.sh
```

The sync script only merges the selected upstream branch into the SNES branch; all SNES adaptation still belongs below `snes/`.

Equivalent manual workflow:

```sh
git fetch origin
git switch snes/parallel-port
git merge --no-edit origin/main
cd snes
python3 tools/check_isolation.py --base origin/main --working-tree
./build.sh pal
```

After each sync, inspect new PCE gameplay changes and reproduce only the relevant behaviour in SNES-owned files. Never resolve a sync by overwriting PCE files from SNES.

## Directory layout

```text
snes/
├── README.md
├── Makefile
├── install.sh
├── build.sh
├── sync-pce.sh
├── lorom.cfg
├── docs/
├── src/
│   ├── main.asm
│   ├── hardware.inc
│   ├── game_clock.asm
│   └── room00.asm
└── tools/
    ├── check_isolation.py
    ├── room00_assets.py
    ├── fix_checksum.py
    └── test_rom.py
```
