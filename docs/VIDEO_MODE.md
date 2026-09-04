# Video mode: C64 -> PC Engine

## C64 reference

The normal VIC-II active display matrix is **320x200 pixels**, equivalently
**40x25 cells of 8x8 pixels**. PAL VIC-II (6569) generates 312 raster lines per
frame and runs at about 50.12 Hz; the larger PAL border/overscan region is not
part of the 320x200 game matrix.

For this port, `320x200` is therefore the coordinate space that matters for
pixel-faithful game graphics. We do not attempt to reproduce the analogue PAL
overscan/border dimensions as game pixels.

Monty's room playfield itself is 32x20 C64 cells (256x160) embedded inside that
40x25 screen matrix; HUD/borders consume the remainder.

## PCE mapping

The PC Engine VDC supports a programmable horizontal display width. HDR.HDW is
the number of active 8-pixel tiles minus one. HDW=$27 therefore means 40 tiles,
or **320 active pixels**. The VCE's PCC=01 selects the 7.159 MHz pixel clock
appropriate to medium-width modes.

The initial target is consequently:

- physical PCE active width: 320 pixels
- physical PCE active height: 224 lines
- logical C64 canvas: 320x200
- C64 canvas vertical placement: y=12..211
- top padding: 12 lines
- bottom padding: 12 lines
- X coordinates: 1:1 C64 -> PCE
- Y coordinates inside the C64 canvas: 1:1 C64 -> PCE

This is preferable to 256x224 because a 256-pixel PCE mode would require
horizontal resampling of every C64 coordinate and graphic.

## Current bring-up test

`src/main.asm` now switches VCE PCC to the 7.159 MHz clock and programs
VDC HDR.HDW=$27. It prints a 40-character ruler. Seeing all forty characters is
the first width test.

The exact HSR/HDE porch/centering values are **not frozen yet**. The first test
inherits CORE's safe startup timing and changes the active-width/clock fields.
This must be checked in Geargrafx and on real hardware before final timing is
called stable. Once verified, explicit HSR/HDR values will replace the inherited
bring-up timing.

## PAL gameplay timing

Video geometry and game timing are separate problems. Original PAL gameplay is
about 50.12 updates/s while a normal PCE video signal is about 60 Hz. The port
will therefore use a logical PAL tick scheduler instead of speeding game logic
up to the display refresh. A phase accumulator will decide which PCE VBlank
frames advance the C64 game state.
