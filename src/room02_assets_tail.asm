; Phase 38a Room $02 generated ROM-tail assets.
; Bulk graphics/map data stays at the ROM tail. The collision map and property
; bytes are copied into RAM on Room-$02 entry so physics never has to execute
; while the far Room-$02 asset bank is mapped over MPR3/MPR4.

.data
room02_patterns:
        incbin "room02-patterns.dat"
room02_collision_map_rom:
        incbin "room02-map.dat"
room02_screen_bat:
        incbin "room02-screen-bat.dat"

room02_tile_properties_rom:
        ; Source chars $02,$01,$27,$60,$3d,$42,$77,$55 classified by
        ; Monty.SetTileProperty: 1,1,2,3,2,2,0,4.
        db $01,$01,$02,$03,$02,$02,$00,$04
