; Phase 49 authentic C64 lift sprite pair converted to PCE 4bpp.
; Kept in the ROM tail so mechanics code can grow without shifting physics.

.data
moving_lift_patterns:
        incbin "lift-sprites.dat"

; VIC multicolour mapping used by lift_sprite.py:
; 0 transparent, 1 shared C64 red $02, 2 sprite-specific pulsing grey (fixed
; light grey $0f for this pass), 3 shared C64 light-red $0a.
; Values use the same GGGRRRBBB C64 quantization as the room palettes.
moving_lift_palette:
        dw $000,$062,$16d,$0eb,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
