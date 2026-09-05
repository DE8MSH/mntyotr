; Phase 45 Room $0B generated ROM-tail assets.
; Room $0B is directly below Room $02 and immediately right of Room $0E.

.data
room0b_patterns:
        incbin "room0b-patterns.dat"

room0b_collision_map_rom:
        incbin "room0b-map.dat"
room0b_tile_properties_rom:
        db $01,$01,$03,$02,$02,$03,$01,$04

room0b_screen_bat:
        incbin "room0b-screen-bat.dat"
