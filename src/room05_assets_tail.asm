; Phase 46 Room $05 generated ROM-tail assets.
; Original world position: immediately left of Room $04.

.data
room05_patterns:
        incbin "room05-patterns.dat"

room05_collision_map_rom:
        incbin "room05-map.dat"
room05_tile_properties_rom:
        db $01,$02,$02,$03,$03,$01,$02,$03

room05_screen_bat:
        incbin "room05-screen-bat.dat"
