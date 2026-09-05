; Room $07 generated ROM-tail assets.
; Original world position: row 1, col $12, between Rooms $06 and $08.

.data
room07_patterns:
        incbin "room07-patterns.dat"

room07_collision_map_rom:
        incbin "room07-map.dat"
room07_tile_properties_rom:
        db $01,$01,$01,$02,$02,$02,$04,$01

room07_screen_bat:
        incbin "room07-screen-bat.dat"
