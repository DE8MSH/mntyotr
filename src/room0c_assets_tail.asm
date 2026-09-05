; Phase 46 Room $0C generated ROM-tail assets.
; Original world position: directly below Room $05.

.data
room0c_patterns:
        incbin "room0c-patterns.dat"

room0c_collision_map_rom:
        incbin "room0c-map.dat"
room0c_tile_properties_rom:
        db $01,$01,$01,$02,$03,$03,$04,$01

room0c_screen_bat:
        incbin "room0c-screen-bat.dat"
