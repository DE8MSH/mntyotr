; Phase 44 Room $0E generated ROM-tail assets.
; Down-neighbour of Room $03 on the real route to Room $04.

.data
room0e_patterns:
        incbin "room0e-patterns.dat"

room0e_collision_map_rom:
        incbin "room0e-map.dat"
room0e_tile_properties_rom:
        db $01,$01,$03,$02,$03,$02,$01,$04

room0e_screen_bat:
        incbin "room0e-screen-bat.dat"
