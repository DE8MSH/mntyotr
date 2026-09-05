# Monty on the Run — PC Engine WIP release

This prerelease contains the Bank 0 layout fix for pceas `--newproc` builds.

- Fixes `.PROC thunks between $FF6F-$FF74 are overwritten by code or data!`.
- Shares the identical `score_init` / `score_zero` reset implementation.
- Frees 11 bytes in Bank 0 without removing score behaviour.
- Keeps the exact C64 five-ASCII-digit score arithmetic introduced in the previous integration.

Build with `./build.sh`; expected ROM output is `build/monty.pce`.
