; Phase 48 Room $09 generated ROM-tail assets.
; Original world position: directly above Room $01.

.data
room09_patterns:
        incbin "room09-patterns.dat"

room09_collision_map_rom:
        incbin "room09-map.dat"
room09_tile_properties_rom:
        db $01,$02,$02,$02,$03,$03,$01,$04

room09_screen_bat:
        incbin "room09-screen-bat.dat"
