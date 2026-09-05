; Authentic C64 Room $00 enemy art converted by tools/enemy_room00.py.
; Four unique frames per type; C64 enemy_copy_flag duplicates these for the
; opposite direction, so the PCE runtime reuses the same four frames.
.data
enemy00_skate_patterns:
        incbin "enemy00-skate.dat"
enemy00_smiley_patterns:
        incbin "enemy00-smiley.dat"

; Sprite palette slots 19/20 -> SAT palette indices 3/4.
; Skate type_idx $03 -> C64 purple $04. Smiley type_idx $05 -> C64 cyan $03.
enemy00_skate_palette:
        dw $000,$0a4,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy00_smiley_palette:
        dw $000,$19d,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
