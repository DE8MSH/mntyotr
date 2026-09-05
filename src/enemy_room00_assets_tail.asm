; Authentic C64 enemy art used by Rooms $00-$02, converted by tools/enemy_room00.py.
; Every payload is eight PCE frames (4096 bytes). C64 4-frame types are duplicated
; into the opposite-direction frame group exactly like enemy_copy_flag does.
.data

enemy00_skate_patterns:
enemy_type09_patterns:
        incbin "enemy-type09-skate.dat"
enemy_type0e_patterns:
        incbin "enemy-type0e-clock.dat"
enemy_type0f_patterns:
        incbin "enemy-type0f-big-nose.dat"
enemy_type14_patterns:
        incbin "enemy-type14-wasp.dat"
enemy_type18_patterns:
        incbin "enemy-type18-kettle.dat"
enemy00_smiley_patterns:
enemy_type19_patterns:
        incbin "enemy-type19-smiley.dat"

; PCE sprite palettes 19..22 -> SAT palette indices 3..6.
; These are the C64 single-colour values used by Rooms $00-$02.
enemy_palette_cyan:                  ; C64 $03
        dw $000,$19d,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_purple:                ; C64 $04
        dw $000,$0a4,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_white:                 ; C64 $01
        dw $000,$1ff,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_yellow:                ; C64 $07
        dw $000,$1fb,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000

; Compatibility aliases retained for older source/tests.
enemy00_smiley_palette = enemy_palette_cyan
enemy00_skate_palette  = enemy_palette_purple
