; Authentic Room $0B enemy records from C64 Room.Data.enemy_spawn.rm_0b.
; enemy_smiley_room_sync clears unsupported rooms first; special_item_room_sync
; calls this immediately afterwards for Room $0B, so the shared movement,
; collision and SAT engines can own these slots normally.

.code
.proc enemy_room0b_seed
        ; slot 0: $07,$28,$7f,$03,$19,$01,$1f
        lda     #$30                    ; ($28>>1)+$1c
        sta     enemy_state_tbl+0
        lda     #$7a                    ; $f9-$7f
        sta     enemy_state_tbl+1
        lda     #$01                    ; C64 white
        sta     enemy_state_tbl+2
        lda     #$19
        sta     enemy_state_tbl+3
        lda     #$81                    ; dir_idx 3
        sta     enemy_state_tbl+4
        lda     #$1f
        sta     enemy_state_tbl+5
        sta     enemy_state_tbl+6       ; reverse start
        lda     #$01
        sta     enemy_state_tbl+7
        lda     #5                      ; sprite palette 21, white
        sta     enemy_palette_tbl+0
        stz     enemy_xmsb_tbl+0
        stz     enemy_anim_timer_tbl+0

        ; slot 1: $05,$a0,$2f,$03,$16,$02,$2b
        lda     #$6c                    ; ($a0>>1)+$1c
        sta     enemy_state_tbl+8
        lda     #$ca                    ; $f9-$2f
        sta     enemy_state_tbl+9
        lda     #$03                    ; C64 cyan
        sta     enemy_state_tbl+10
        lda     #$16
        sta     enemy_state_tbl+11
        lda     #$81
        sta     enemy_state_tbl+12
        lda     #$2b
        sta     enemy_state_tbl+13
        sta     enemy_state_tbl+14
        lda     #$02
        sta     enemy_state_tbl+15
        lda     #3                      ; sprite palette 19, cyan
        sta     enemy_palette_tbl+1
        stz     enemy_xmsb_tbl+1
        stz     enemy_anim_timer_tbl+1

        ; Upload type $19 to enemy slot 0 VRAM.
        lda     #<enemy_type19_patterns
        sta     <_bp
        lda     #>enemy_type19_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type19_patterns)
        lda     #<$3800
        sta     <_di
        lda     #>$3800
        sta     <_di+1
        call    enemy_room0b_upload_4k

        ; Upload type $16 to enemy slot 1 VRAM.
        lda     #<enemy_type16_patterns
        sta     <_bp
        lda     #>enemy_type16_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type16_patterns)
        lda     #<$4000
        sta     <_di
        lda     #>$4000
        sta     <_di+1
        call    enemy_room0b_upload_4k
        leave
.endp

.proc enemy_room0b_upload_4k
        php
        sei
        tma3
        pha
        tma4
        pha
        call    map_bp_to_mpr34
        call    vdc_di_to_mawr
        ldx     #16
        cly
.page:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        bne     .page
        inc     <_bp+1
        dex
        bne     .page
        pla
        tam4
        pla
        tam3
        plp
        leave
.endp
