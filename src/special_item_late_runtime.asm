; Authentic normal-play special items missing from the early-room runtime.
; Source: SpecialItems.Data.si_spawn_tbl. Coordinates are C64 sprite X/Y and
; are deliberately not guessed from room artwork.

.bss
special_item_late_last_room: ds 1

.code
.proc special_item_late_room_sync
        lda <monty_room
        cmp special_item_late_last_room
        bne .changed
        leave
.changed:
        sta special_item_late_last_room
        cmp #$10
        bne .not_r10
        jmp .r10
.not_r10:
        cmp #$13
        bne .not_r13
        jmp .r13
.not_r13:
        cmp #$14
        bne .not_r14
        jmp .r14
.not_r14:
        cmp #$16
        bne .not_r16
        jmp .r16
.not_r16:
        cmp #$17
        bne .not_r17
        jmp .r17
.not_r17:
        cmp #$1a
        bne .not_r1a
        jmp .r1a
.not_r1a:
        cmp #$1b
        bne .not_r1b
        jmp .r1b
.not_r1b:
        cmp #$1f
        bne .not_r1f
        jmp .r1f
.not_r1f:
        cmp #$23
        bne .not_r23
        jmp .r23
.not_r23:
        cmp #$29
        bne .not_r29
        jmp .r29
.not_r29:
        cmp #$2b
        bne .not_r2b
        jmp .r2b
.not_r2b:
        cmp #$2d
        bne .done_dispatch
        jmp .r2d
.done_dispatch:
        leave

.r10:
        lda #17
        sta special_item_index
        lda #3
        sta special_item_asset
        lda #$30
        sta special_item_x
        lda #$ca
        sta special_item_y
        jmp .activate
.r13:
        lda #1
        sta special_item_index
        lda #5
        sta special_item_asset
        lda #$5a
        sta special_item_x
        lda #$7a
        sta special_item_y
        jmp .activate
.r14:
        lda #2
        sta special_item_index
        lda #3
        sta special_item_asset
        lda #$4c
        sta special_item_x
        lda #$82
        sta special_item_y
        jmp .activate
.r16:
        lda #4
        sta special_item_index
        lda #3
        sta special_item_asset
        lda #$23
        sta special_item_x
        lda #$aa
        sta special_item_y
        jmp .activate
.r17:
        lda #3
        sta special_item_index
        lda #6
        sta special_item_asset
        lda #$80
        sta special_item_x
        lda #$72
        sta special_item_y
        jmp .activate
.r1a:
        lda #6
        sta special_item_index
        lda #3
        sta special_item_asset
        lda #$40
        sta special_item_x
        lda #$6a
        sta special_item_y
        jmp .activate
.r1b:
        lda #5
        sta special_item_index
        lda #7
        sta special_item_asset
        lda #$38
        sta special_item_x
        lda #$62
        sta special_item_y
        jmp .activate
.r1f:
        lda #7
        sta special_item_index
        lda #3
        sta special_item_asset
        lda #$78
        sta special_item_x
        lda #$62
        sta special_item_y
        jmp .activate
.r23:
        lda #8
        sta special_item_index
        lda #8
        sta special_item_asset
        lda #$41
        sta special_item_x
        lda #$b2
        sta special_item_y
        jmp .activate
.r29:
        lda #9
        sta special_item_index
        lda #3
        sta special_item_asset
        lda #$44
        sta special_item_x
        lda #$9a
        sta special_item_y
        jmp .activate
.r2b:
        lda #10
        sta special_item_index
        lda #9
        sta special_item_asset
        lda #$68
        sta special_item_x
        lda #$5a
        sta special_item_y
        jmp .activate
.r2d:
        lda #18
        sta special_item_index
        lda #3
        sta special_item_asset
        lda #$6c
        sta special_item_x
        lda #$62
        sta special_item_y

.activate:
        ldx special_item_index
        lda special_item_collected,x
        bne .done
        lda #1
        sta special_item_active
        lda special_item_asset
        cmp #3
        bne .extra
        call special_item_upload       ; authentic cupcake already in early runtime
        leave
.extra:
        jsr .upload_extra
.done:
        leave

; Expand one of the five authentic C64 one-colour sprite planes into the same
; four PCE 16x16 chunks used by special_item_upload.
.upload_extra:
        php
        sei
        tma3
        pha
        tma4
        pha
        lda special_item_asset
        cmp #5
        bne .not_vase
        lda #<special_item_vase_plane0
        sta <_bp
        lda #>special_item_vase_plane0
        sta <_bp+1
        ldy #BANK(special_item_vase_plane0)
        bra .mapped
.not_vase:
        cmp #6
        bne .not_fly
        lda #<special_item_fly_spray_plane0
        sta <_bp
        lda #>special_item_fly_spray_plane0
        sta <_bp+1
        ldy #BANK(special_item_fly_spray_plane0)
        bra .mapped
.not_fly:
        cmp #7
        bne .not_joy
        lda #<special_item_joystick_plane0
        sta <_bp
        lda #>special_item_joystick_plane0
        sta <_bp+1
        ldy #BANK(special_item_joystick_plane0)
        bra .mapped
.not_joy:
        cmp #8
        bne .key
        lda #<special_item_jerry_can_plane0
        sta <_bp
        lda #>special_item_jerry_can_plane0
        sta <_bp+1
        ldy #BANK(special_item_jerry_can_plane0)
        bra .mapped
.key:
        lda #<special_item_key_plane0
        sta <_bp
        lda #>special_item_key_plane0
        sta <_bp+1
        ldy #BANK(special_item_key_plane0)
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
        rts
.endp
