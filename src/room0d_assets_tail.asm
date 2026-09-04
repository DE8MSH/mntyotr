; Phase 44 Room $0D generated ROM-tail assets.
; Part of the real Room $03 -> $0E -> $0D -> $04 route.

.data
room0d_patterns:
        incbin "room0d-patterns.dat"

room0d_collision_map_rom:
        incbin "room0d-map.dat"
room0d_tile_properties_rom:
        db $01,$01,$04,$01,$01,$01,$01,$01

room0d_screen_bat:
        incbin "room0d-screen-bat.dat"
