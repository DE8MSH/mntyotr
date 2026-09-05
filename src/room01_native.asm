; Native room $01 generated from the exact C64 RLE stream.
; Phase 49 keeps a RAM collision copy so UpdateRisingCloud can move code-8
; property-3 cells through the room without baking a permanent ladder into ROM.

.bss
room01_collision_map:
        ds 640

.data
room01_collision_map_rom:
        incbin "room01-map.dat"
room01_screen_bat:
        incbin "room01-screen-bat.dat"
