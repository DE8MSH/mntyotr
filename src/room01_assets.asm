; Exact room $01 custom graphics from C64 room_defs + Tiles.tile_library.
; The generated base file contains blank char 0 followed by custom chars 1..8.
; Phase 36 additionally binds the exact Room-$01 Decor.room_list graphics.

.data
room01_patterns:
        incbin "room01-patterns.dat"

room01_decor_patterns:
        ; Exact type $42 purple_flowers (4x4) then type $41 bunch_flower (3x3),
        ; preserving the original room-list/type-init order: 25 chars total.
        incbin "room01-decor-patterns.dat"

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
