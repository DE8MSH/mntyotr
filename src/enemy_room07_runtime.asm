; Exact C64 Room $07 enemy activation.
; Room07 uses four Bubble enemies (type $15), whose graphics/collision path is
; already shared with Rooms $00-$05. Keep this small shim separate while the
; generic selector is extended for the new Room06/08-only sprite types.

.code
.proc enemy_room07_room_sync
        lda     <monty_room
        cmp     #$07
        beq     .room07
        leave

.room07:
        ; enemy_smiley_room_sync clears all four slots on room entry. Once this
        ; shim has seeded slot 0, subsequent frames become a cheap no-op.
        lda     enemy_state_tbl
        cmp     #$ff
        beq     .seed
        leave

.seed:
        ldx     #31
.copy_state:
        lda     .room07_state,x
        sta     enemy_state_tbl,x
        dex
        bpl     .copy_state

        ldx     #3
.clear_aux:
        stz     enemy_xmsb_tbl,x
        stz     enemy_anim_timer_tbl,x
        lda     .room07_palettes,x
        sta     enemy_palette_tbl,x
        dex
        bpl     .clear_aux

        jsr     .upload_bubbles
        leave

; Upload the same authentic 8-frame Bubble payload into each slot's private
; VRAM range ($3800,$4000,$4800,$5000), preserving the generic SAT renderer.
.upload_bubbles:
        php
        sei
        tma3
        pha
        tma4
        pha

        stz     enemy_tmp_slot
.upload_next:
        lda     #<enemy_type15_patterns
        sta     <_bp
        lda     #>enemy_type15_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type15_patterns)
        call    map_bp_to_mpr34

        stz     <_di
        lda     enemy_tmp_slot
        asl     a
        asl     a
        asl     a
        clc
        adc     #$38
        sta     <_di+1
        call    vdc_di_to_mawr

        ldx     #16
        cly
.upload_page:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        bne     .upload_page
        inc     <_bp+1
        dex
        bne     .upload_page

        inc     enemy_tmp_slot
        lda     enemy_tmp_slot
        cmp     #4
        bne     .upload_next

        pla
        tam4
        pla
        tam3
        plp
        rts

; Exact SetupRoom-transformed state from room_data.asm:
; source records:
;   $02,$28,$2f,$03,$15,$02,$17
;   $05,$a0,$9f,$04,$15,$03,$1a
;   $03,$40,$9f,$04,$15,$01,$27
;   $04,$f0,$a7,$04,$15,$02,$24
.room07_state:
        db $30,$ca,$02,$15,$81,$17,$17,$02
        db $6c,$5a,$03,$15,$01,$1a,$00,$03
        db $3c,$5a,$04,$15,$01,$27,$00,$01
        db $94,$52,$05,$15,$01,$24,$00,$02
.room07_palettes:
        db $07,$03,$04,$08
.endp
