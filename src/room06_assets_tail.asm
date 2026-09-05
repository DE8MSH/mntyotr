; Room $06 generated ROM-tail assets.
; Original world position: row 1, col $11, directly above Room $05.

.data
room06_patterns:
        incbin "room06-patterns.dat"

room06_collision_map_rom:
        incbin "room06-map.dat"
room06_tile_properties_rom:
        db $01,$02,$03,$02,$03,$02,$01,$03

room06_screen_bat:
        incbin "room06-screen-bat.dat"
