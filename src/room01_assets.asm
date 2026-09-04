; Exact room $01 custom graphics from C64 room_defs + Tiles.tile_library.
; The generated file contains blank char 0 followed by custom chars 1..8.

.data
room01_patterns:
        incbin "room01-patterns.dat"

; Two C64 colours not already present in the room-$00 shared BG palette set.
; Loaded into PCE BG palette slots 13 and 14.
room01_extra_palettes:
        ; slot 13: C64 purple $04
        dw $000,$10b,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
        ; slot 14: C64 blue $06
        dw $000,$120,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000

room01_tile_properties:
        ; source tiles $02,$63,$01,$0a,$40,$05,$55,$64 classified by
        ; Monty.SetTileProperty: 1,0,1,1,2,1,4,0.
        db $01,$00,$01,$01,$02,$01,$04,$00
