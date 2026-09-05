; Room $08 generated ROM-tail assets.
; Original world position: row 1, col $13, directly above Room $02.

.data
room08_patterns:
        incbin "room08-patterns.dat"

room08_collision_map_rom:
        incbin "room08-map.dat"
room08_tile_properties_rom:
        db $01,$02,$01,$03,$02,$03,$02,$04

room08_screen_bat:
        incbin "room08-screen-bat.dat"
