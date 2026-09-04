; Phase 42 Room $04 generated ROM-tail assets.
; Prepared only: Room $04 is not reachable yet. Keep bulk data behind runtime
; code so the confirmed Room $00-$03 physics/collision layout stays stable.

.data
room04_patterns:
        incbin "room04-patterns.dat"

room04_collision_map_rom:
        incbin "room04-map.dat"
room04_tile_properties_rom:
        ; Source chars $03,$62,$3c,$60,$43,$66,$02,$4f classified by
        ; Monty.SetTileProperty: 1,3,2,3,2,3,1,4.
        db $01,$03,$02,$03,$02,$03,$01,$04

room04_screen_bat:
        incbin "room04-screen-bat.dat"
