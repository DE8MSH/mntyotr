; Phase 45 Room $0A generated ROM-tail assets.
; Room $0A is directly below Room $01 in the original world grid.

.data
room0a_patterns:
        incbin "room0a-patterns.dat"

room0a_collision_map_rom:
        incbin "room0a-map.dat"
room0a_tile_properties_rom:
        db $01,$03,$02,$02,$01,$01,$01,$01

room0a_screen_bat:
        incbin "room0a-screen-bat.dat"
