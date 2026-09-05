; Phase 41 Room $03 ROM-tail assets.
; Bulk room data stays behind the confirmed runtime code. Collision/properties
; are copied into the shared tail-room RAM cache on entry.

.data
room03_patterns:
        incbin "room03-patterns.dat"

room03_collision_map_rom:
        incbin "room03-map.dat"
room03_tile_properties_rom:
        ; Source chars $01,$2f,$00,$65,$5f,$44,$11,$55 classified by
        ; Monty.SetTileProperty: 1,2,1,3,3,2,1,4.
        db $01,$02,$01,$03,$03,$02,$01,$04

room03_screen_bat:
        incbin "room03-screen-bat.dat"

; PCE BG palette slot 15: C64 light blue $0e -> unified GGGRRRBBB $0de.
room03_extra_palette:
        dw $000,$0de,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
