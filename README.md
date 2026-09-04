# Monty on the Run — PC Engine port

Work-in-progress 1:1 gameplay port of the C64 *Monty on the Run* reconstruction to the NEC PC Engine / HuCard.

## Goals

- PC Engine `.pce` ROM, suitable for emulators and real hardware/flash carts
- Preserve C64 room layouts, movement, jump physics, collisions and game logic as closely as practical
- Preserve the C64 visual appearance while converting assets to PCE VDC/VCE formats
- Linux Mint 22 development/build environment
- Reproducible install, build, run and smoke-test scripts
- Gameplay first; PCE PSG music/SFX port follows after the gameplay core

## Reference source

The behavioural reference is Dave-Agent's commented/refactored C64 reconstruction:

https://github.com/Dave-Agent/monty-on-the-run

The original commercial binary is not included in this repository.

## Planned build interface

```sh
./install.sh
./build.sh
./run.sh

# or
make
make debug
make smoke
make run
make clean
```

Expected release ROM:

```text
build/monty.pce
```

## Status

Phase 1: source analysis, HuC6280/PCE memory and video architecture, Linux Mint 22 toolchain, and first bootable ROM.

This repository is currently under active bring-up; a ROM should not be considered a playable port until explicitly marked as such.
