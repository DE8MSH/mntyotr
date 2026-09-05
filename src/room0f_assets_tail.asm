; Exact C64 Room $0F (first ESCAPE TUNNEL room) generated ROM-tail assets.
.data
room0f_patterns:
        incbin "room0f-patterns.dat"

room0f_collision_map_rom:
        incbin "room0f-map.dat"
room0f_tile_properties_rom:
        db $01,$01,$01,$03,$02,$03,$02,$01

room0f_screen_bat:
        incbin "room0f-screen-bat.dat"
