; Authentic C64 special items for supported rooms $00-$0F.
; Normal play: R02 first aid, R04 milk, R08 teddy, R09/R0A/R0D cupcake,
; R0B smoke stack. R01 cake remains cheat-mode-only and is not spawned.

        include "room0b_decor_loader.asm"

SPECIAL_ITEM_VRAM = $5800

.bss
special_item_collected: ds 20
special_item_active: ds 1
special_item_index: ds 1
special_item_asset: ds 1
special_item_x: ds 1
special_item_y: ds 1
special_item_last_room: ds 1
special_item_player_x: ds 1

.code
.proc special_item_init
        ldx #19
.clear:
        stz special_item_collected,x
        dex
        bpl .clear
        stz special_item_active
        lda #$ff
        sta special_item_last_room
        call special_item_room_sync
        leave
.endp

.proc special_item_room_sync
        lda <monty_room
        cmp special_item_last_room
        bne .changed
        leave
.changed:
        sta special_item_last_room
        stz special_item_active
        cmp #$02
        bne .not02
        jmp .room02
.not02:
        cmp #$04
        bne .not04
        jmp .room04
.not04:
        cmp #$08
        bne .not08
        jmp .room08
.not08:
        cmp #$09
        bne .not09
        jmp .room09
.not09:
        cmp #$0a
        bne .not0a
        jmp .room0a
.not0a:
        cmp #$0b
        bne .not0b
        jmp .room0b
.not0b:
        cmp #$0d
        bne .none
        jmp .room0d
.none:
        leave
.room02:
        lda #11
        sta special_item_index
        stz special_item_asset
        lda #$88
        sta special_item_x
        lda #$a2
        sta special_item_y
        jmp .activate
.room04:
        lda #12
        sta special_item_index
        lda #1
        sta special_item_asset
        lda #$7c
        sta special_item_x
        lda #$c2
        sta special_item_y
        jmp .activate
.room08:
        lda #13
        sta special_item_index
        lda #2
        sta special_item_asset
        lda #$50
        sta special_item_x
        lda #$5a
        sta special_item_y
        jmp .activate
.room09:
        lda #14
        sta special_item_index
        lda #3
        sta special_item_asset
        lda #$28
        sta special_item_x
        lda #$62
        sta special_item_y
        jmp .activate
.room0a:
        lda #15
        sta special_item_index
        lda #3
        sta special_item_asset
        lda #$3c
        sta special_item_x
        lda #$ca
        sta special_item_y
        jmp .activate
.room0b:
        ; The base Room $0B loader draws the decorated BAT generated at build
        ; time. Upload its 25 exact decor chars before the room becomes visible.
        call room0b_upload_decor
        lda #16
        sta special_item_index
        lda #4
        sta special_item_asset
        lda #$38
        sta special_item_x
        lda #$7a
        sta special_item_y
        jmp .activate
.room0d:
        stz special_item_index
        lda #3
        sta special_item_asset
        lda #$70
        sta special_item_x
        lda #$c2
        sta special_item_y
.activate:
        ldx special_item_index
        lda special_item_collected,x
        bne .done
        lda #1
        sta special_item_active
        call special_item_upload
.done:
        leave
.endp

; Original 24x21 sprite bounding-box overlap.
.proc special_item_update
        lda special_item_active
        bne .check
        leave
.check:
        lda <monty_x
        asl a
        sta special_item_player_x
        sec
        sbc special_item_x
        cmp #24
        bcc .x_ok
        lda special_item_x
        sec
        sbc special_item_player_x
        cmp #24
        bcs .done
.x_ok:
        lda <monty_y
        clc
        adc #1
        sec
        sbc special_item_y
        cmp #21
        bcc .collect
        lda special_item_y
        sec
        sbc <monty_y
        cmp #22
        bcs .done
.collect:
        ldx special_item_index
        lda #$81
        sta special_item_collected,x
        stz special_item_active
        ; Original SI score award: +200.
        lda #2
        ldy #2
        call score_increase
        ; Original first-aid kit ($8E / record 11): +1 life.
        lda special_item_index
        cmp #11
        bne .done
        inc game_lives
.done:
        leave
.endp

; Select and expand the authentic one-colour C64 sprite into PCE VRAM.
.proc special_item_upload
        php
        sei
        tma3
        pha
        tma4
        pha
        lda special_item_asset
        bne .not_first
        jmp .first
.not_first:
        cmp #1
        bne .not_milk
        jmp .milk
.not_milk:
        cmp #2
        bne .not_teddy
        jmp .teddy
.not_teddy:
        cmp #3
        bne .smoke
        jmp .cupcake
.smoke:
        lda #<special_item_smoke_plane0
        sta <_bp
        lda #>special_item_smoke_plane0
        sta <_bp+1
        ldy #BANK(special_item_smoke_plane0)
        jmp .mapped
.first:
        lda #<special_item_first_aid_plane0
        sta <_bp
        lda #>special_item_first_aid_plane0
        sta <_bp+1
        ldy #BANK(special_item_first_aid_plane0)
        jmp .mapped
.milk:
        lda #<special_item_milk_plane0
        sta <_bp
        lda #>special_item_milk_plane0
        sta <_bp+1
        ldy #BANK(special_item_milk_plane0)
        jmp .mapped
.teddy:
        lda #<special_item_teddy_plane0
        sta <_bp
        lda #>special_item_teddy_plane0
        sta <_bp+1
        ldy #BANK(special_item_teddy_plane0)
        jmp .mapped
.cupcake:
        lda #<special_item_cupcake_plane0
        sta <_bp
        lda #>special_item_cupcake_plane0
        sta <_bp+1
        ldy #BANK(special_item_cupcake_plane0)
.mapped:
        call map_bp_to_mpr34
        lda #<SPECIAL_ITEM_VRAM
        sta <_di
        lda #>SPECIAL_ITEM_VRAM
        sta <_di+1
        call vdc_di_to_mawr
        cly
        ldx #4
.tile:
        lda #16
        sta special_item_player_x
.p0:
        lda [_bp],y
        sta VDC_DL
        iny
        lda [_bp],y
        sta VDC_DH
        iny
        dec special_item_player_x
        bne .p0
        lda #48
        sta special_item_player_x
.zero:
        stz VDC_DL
        stz VDC_DH
        dec special_item_player_x
        bne .zero
        dex
        bne .tile
        pla
        tam4
        pla
        tam3
        plp
        leave
.endp
