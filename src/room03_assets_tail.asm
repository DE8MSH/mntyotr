; Phase 40 Room $03 generated ROM-tail assets.
; Prepared only: Room $03 is not reachable yet. Keeping all bulk data here
; preserves the confirmed runtime/physics layout while we validate ROM growth.

.data
room03_patterns:
        incbin "room03-patterns.dat"

room03_collision_map_rom:
        incbin "room03-map.dat"
room03_tile_properties_rom:
        ; Source chars $01,$2f,$00,$65,$5f,$44,$11,$55 classified by
        ; Monty.SetTileProperty: 1,2,1,3,3,2,1,4.
        db $01,$02,$01,$03,$03,$02,$01,$04

room03_screen_bat:
        incbin "room03-screen-bat.dat"
