; Authentic C64 enemy art used by Rooms $00-$08, converted by tools/enemy_room00.py.
; Every payload is eight PCE frames (4096 bytes). C64 4-frame types are duplicated
; into the opposite-direction frame group exactly like enemy_copy_flag does.
.data

enemy00_skate_patterns:
enemy_type09_patterns:
        incbin "enemy-type09-skate.dat"
enemy_type0a_patterns:
        incbin "enemy-type0a-lamp.dat"
enemy_type0b_patterns:
        incbin "enemy-type0b-knight.dat"
enemy_type0e_patterns:
        incbin "enemy-type0e-clock.dat"
enemy_type0f_patterns:
        incbin "enemy-type0f-big-nose.dat"
enemy_type11_patterns:
        incbin "enemy-type11-rubik.dat"
enemy_type13_patterns:
        incbin "enemy-type13-pi-pie.dat"
enemy_type14_patterns:
        incbin "enemy-type14-wasp.dat"
enemy_type15_patterns:
        incbin "enemy-type15-bubble.dat"
enemy_type16_patterns:
        incbin "enemy-type16-sad-ghost.dat"
enemy_type18_patterns:
        incbin "enemy-type18-kettle.dat"
enemy00_smiley_patterns:
enemy_type19_patterns:
        incbin "enemy-type19-smiley.dat"
enemy_type1b_patterns:
        incbin "enemy-type1b-hand.dat"
enemy_type1c_patterns:
        incbin "enemy-type1c-tank.dat"
enemy_type1d_patterns:
        incbin "enemy-type1d-jelly-fish.dat"

; PCE sprite palettes 19..25 -> SAT palette indices 3..9.
; Values use the same unified C64 -> PCE GGGRRRBBB quantization as room art.
enemy_palette_cyan:                  ; C64 $03 -> $19d
        dw $000,$19d,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_purple:                ; C64 $04 -> $0a4
        dw $000,$0a4,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_white:                 ; C64 $01 -> $1ff
        dw $000,$1ff,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_yellow:                ; C64 $07 -> $1fb
        dw $000,$1fb,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_red:                   ; C64 $02 -> $062
        dw $000,$062,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_green:                 ; C64 $05 -> $152
        dw $000,$152,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
enemy_palette_light_blue:            ; C64 $0e -> $0de
        dw $000,$0de,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
