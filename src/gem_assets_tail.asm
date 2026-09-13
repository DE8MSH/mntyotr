; Banked collectible data for rooms $00-$0F.
; Records are (room, target_x, target_y, BAT_lo, BAT_hi) and come from the
; original C64 FreedomKit.Data.item_tbl positions.

.data
gem_records:
        db $00,$4d,$94,$12,$03
        db $01,$89,$7c,$61,$02
        db $01,$49,$ac,$d1,$03
        db $01,$2d,$dc,$4a,$05
        db $02,$85,$74,$20,$02
        db $02,$41,$84,$8f,$02
        db $03,$29,$d4,$09,$05
        db $03,$29,$84,$89,$02
        db $04,$61,$74,$17,$02
        db $05,$5d,$64,$96,$01
        db $05,$31,$74,$0b,$02
        db $06,$35,$7c,$4c,$02
        db $06,$59,$ac,$d5,$03
        db $08,$5d,$6c,$d6,$01
        db $0a,$29,$6c,$c9,$01
        db $0a,$5d,$d4,$16,$05
        db $0d,$41,$bc,$4f,$04
        db $0e,$7d,$ac,$de,$03
        db $0f,$1d,$6c,$c6,$01
        db $0f,$69,$6c,$d9,$01

; Original C64 font character $34 used by RoomEntitiesInit for room collectibles:
;   3c 42 df c7 fb fb 46 3c
; Converted with the same one-bit -> PCE plane-0 layout as all room characters.
gem_tile_pattern:
        db $3c,$00,$42,$00,$df,$00,$c7,$00
        db $fb,$00,$fb,$00,$46,$00,$3c,$00
        db $00,$00,$00,$00,$00,$00,$00,$00
        db $00,$00,$00,$00,$00,$00,$00,$00
