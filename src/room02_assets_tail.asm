; Phase 37 Room $02 generated assets.
; Keep this bulk data in the ROM-tail include area so adding the room does not
; move the already-confirmed gameplay/physics code merely by growing assets.

.data
room02_patterns:
        incbin "room02-patterns.dat"
room02_collision_map:
        incbin "room02-map.dat"
room02_screen_bat:
        incbin "room02-screen-bat.dat"

room02_tile_properties:
        ; Source chars $02,$01,$27,$60,$3d,$42,$77,$55 classified by
        ; Monty.SetTileProperty: 1,1,2,3,2,2,0,4.
        db $01,$01,$02,$03,$02,$02,$00,$04
