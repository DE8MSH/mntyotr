; Phase 49 authentic C64 lift sprite pair converted to PCE 4bpp.
; Kept in the ROM tail so mechanics code can grow without shifting physics.

.data
moving_lift_patterns:
        incbin "lift-sprites.dat"

; VIC multicolour mapping used by lift_sprite.py:
; 0 transparent, 1 shared red, 2 sprite-specific pulsing grey (fixed light grey
; for this first PCE pass), 3 shared light-red.
moving_lift_palette:
        dw $000,$099,$16d,$0bb,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
