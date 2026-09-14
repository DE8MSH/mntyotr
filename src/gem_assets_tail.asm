; Banked collectible data for rooms $00-$33.
; Records are (room, target_x, target_y, BAT_lo, BAT_hi) and come directly from
; the original C64 FreedomKit.Data.item_tbl positions.
;
; Conversion used for every record:
;   target_x = $15 + 4*col
;   target_y = $4c + 8*row
;   BAT      = (row+3)*64 + (col+4)
;
; The original table contains 64 normal room collectibles. Rooms without a
; record intentionally have no normal gem.

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
        db $11,$71,$6c,$db,$01
        db $11,$71,$bc,$5b,$04
        db $12,$85,$8c,$e0,$02
        db $12,$71,$c4,$9b,$04
        db $12,$4d,$84,$92,$02
        db $13,$61,$ac,$d7,$03
        db $13,$45,$d4,$10,$05
        db $14,$75,$8c,$dc,$02
        db $15,$41,$6c,$cf,$01
        db $15,$61,$8c,$d7,$02
        db $15,$4d,$a4,$92,$03
        db $16,$41,$94,$0f,$03
        db $16,$7d,$a4,$9e,$03
        db $17,$65,$cc,$d8,$04
        db $18,$21,$54,$07,$01
        db $18,$21,$cc,$c7,$04
        db $19,$35,$d4,$0c,$05
        db $1a,$59,$94,$15,$03
        db $1b,$21,$8c,$c7,$02
        db $1b,$1d,$bc,$46,$04
        db $1b,$71,$74,$1b,$02
        db $1c,$41,$bc,$4f,$04
        db $1d,$79,$6c,$dd,$01
        db $1d,$65,$94,$18,$03
        db $1d,$21,$a4,$87,$03
        db $1e,$89,$9c,$61,$03
        db $1e,$85,$64,$a0,$01
        db $1e,$49,$9c,$51,$03
        db $1f,$3d,$cc,$ce,$04
        db $1f,$51,$bc,$53,$04
        db $20,$35,$cc,$cc,$04
        db $21,$7d,$dc,$5e,$05
        db $22,$3d,$8c,$ce,$02
        db $22,$41,$c4,$8f,$04
        db $26,$3d,$bc,$4e,$04
        db $27,$21,$bc,$47,$04
        db $28,$85,$ac,$e0,$03
        db $29,$49,$5c,$51,$01
        db $2a,$39,$8c,$cd,$02
        db $2a,$55,$9c,$54,$03
        db $2c,$25,$64,$88,$01
        db $2c,$75,$9c,$5c,$03
        db $2d,$8d,$a4,$a2,$03
        db $2e,$35,$ac,$cc,$03

; Original C64 font character $34 used by RoomEntitiesInit for room collectibles:
;   3c 42 df c7 fb fb 46 3c
; Converted with the same one-bit -> PCE plane-0 layout as all room characters.
gem_tile_pattern:
        db $3c,$00,$42,$00,$df,$00,$c7,$00
        db $fb,$00,$fb,$00,$46,$00,$3c,$00
        db $00,$00,$00,$00,$00,$00,$00,$00
        db $00,$00,$00,$00,$00,$00,$00,$00
