; Authentic Room $00 enemies: Smiley (slot0) and Skate (slot1).
; Spawn records copied from C64 room_data.asm:
;   05 b8 8f 04 19 02 25  -> Smiley
;   03 78 37 03 09 03 13  -> Skate
; SetupRoom conversion and MoveVertical state machine follow the original.

ENEMY00_SKATE_VRAM  = $3800
ENEMY00_SMILEY_VRAM = $3c00
ENEMY00_SMILEY_L    = SAT_ADDR+32     ; SAT entry 8
ENEMY00_SMILEY_R    = SAT_ADDR+36     ; SAT entry 9
ENEMY00_SKATE_L     = SAT_ADDR+40     ; SAT entry 10
ENEMY00_SKATE_R     = SAT_ADDR+44     ; SAT entry 11

.bss
enemy00_last_room:      ds 1
enemy00_active:         ds 1
enemy00_smiley_x:       ds 1
enemy00_smiley_y:       ds 1
enemy00_smiley_flags:   ds 1
enemy00_smiley_count:   ds 1
enemy00_smiley_anim:    ds 1
enemy00_skate_x:        ds 1
enemy00_skate_y:        ds 1
enemy00_skate_flags:    ds 1
enemy00_skate_count:    ds 1
enemy00_skate_anim:     ds 1
enemy00_tmp:            ds 1

.code
enemy00_init:
        lda     #$ff
        sta     enemy00_last_room
        stz     enemy00_active
        ; Anim counters are initialized by room_sync before Room00 can render.
        ; Sprite assets are banked ROM data. Preserve the caller's MPR3/MPR4
        ; mapping across both 2 KiB uploads, like the other bank-safe assets.
        php
        sei
        tma3
        pha
        tma4
        pha
        call    enemy00_upload_skate
        call    enemy00_upload_smiley
        pla
        tam4
        pla
        tam3
        plp
        rts

enemy00_room_sync:
        lda     <monty_room
        cmp     enemy00_last_room
        bne     .changed
        rts
.changed:
        sta     enemy00_last_room
        cmp     #$00
        beq     .room00
        stz     enemy00_active
        rts
.room00:
        lda     #1
        sta     enemy00_active

        ; Smiley SetupRoom: x=$b8/2+$1c=$78, y=$f9-$8f=$6a.
        lda     #$78
        sta     enemy00_smiley_x
        lda     #$6a
        sta     enemy00_smiley_y
        lda     #$01                    ; dir_idx4 -> vertical, forward/down
        sta     enemy00_smiley_flags
        stz     enemy00_smiley_count     ; bit7 clear -> counter 0
        stz     enemy00_smiley_anim

        ; Skate SetupRoom: x=$78/2+$1c=$58, y=$f9-$37=$c2.
        lda     #$58
        sta     enemy00_skate_x
        lda     #$c2
        sta     enemy00_skate_y
        lda     #$81                    ; dir_idx3 -> vertical, reverse/up
        sta     enemy00_skate_flags
        lda     #$13                    ; bit7 set -> counter starts at range
        sta     enemy00_skate_count
        stz     enemy00_skate_anim
        rts

enemy00_update:
        lda     enemy00_active
        bne     .active
        rts
.active:
        ; Slot0 Smiley: speed 2, range $25.
        lda     enemy00_smiley_flags
        bmi     .smiley_up
        inc     enemy00_smiley_count
        lda     enemy00_smiley_count
        cmp     #$25
        bne     .smiley_down_move
        lda     enemy00_smiley_flags
        eor     #$80
        sta     enemy00_smiley_flags
        bra     .smiley_done
.smiley_down_move:
        lda     enemy00_smiley_y
        clc
        adc     #2
        sta     enemy00_smiley_y
        bra     .smiley_done
.smiley_up:
        dec     enemy00_smiley_count
        bne     .smiley_up_move
        lda     enemy00_smiley_flags
        eor     #$80
        sta     enemy00_smiley_flags
        bra     .smiley_done
.smiley_up_move:
        lda     enemy00_smiley_y
        sec
        sbc     #2
        sta     enemy00_smiley_y
.smiley_done:
        inc     enemy00_smiley_anim

        ; Slot1 Skate: speed 3, range $13.
        lda     enemy00_skate_flags
        bmi     .skate_up
        inc     enemy00_skate_count
        lda     enemy00_skate_count
        cmp     #$13
        bne     .skate_down_move
        lda     enemy00_skate_flags
        eor     #$80
        sta     enemy00_skate_flags
        bra     .skate_done
.skate_down_move:
        lda     enemy00_skate_y
        clc
        adc     #3
        sta     enemy00_skate_y
        bra     .skate_done
.skate_up:
        dec     enemy00_skate_count
        bne     .skate_up_move
        lda     enemy00_skate_flags
        eor     #$80
        sta     enemy00_skate_flags
        bra     .skate_done
.skate_up_move:
        lda     enemy00_skate_y
        sec
        sbc     #3
        sta     enemy00_skate_y
.skate_done:
        inc     enemy00_skate_anim
        rts

; Upload four 512-byte PCE frames (2048 bytes) per type. map_bp_to_mpr34 makes
; the two adjacent HuCard banks visible, so a 2 KiB block is safe across a bank edge.
enemy00_upload_skate:
        lda     #<enemy00_skate_patterns
        sta     <_bp
        lda     #>enemy00_skate_patterns
        sta     <_bp+1
        ldy     #BANK(enemy00_skate_patterns)
        call    map_bp_to_mpr34
        lda     #<ENEMY00_SKATE_VRAM
        sta     <_di
        lda     #>ENEMY00_SKATE_VRAM
        sta     <_di+1
        bra     enemy00_upload_2k

enemy00_upload_smiley:
        lda     #<enemy00_smiley_patterns
        sta     <_bp
        lda     #>enemy00_smiley_patterns
        sta     <_bp+1
        ldy     #BANK(enemy00_smiley_patterns)
        call    map_bp_to_mpr34
        lda     #<ENEMY00_SMILEY_VRAM
        sta     <_di
        lda     #>ENEMY00_SMILEY_VRAM
        sta     <_di+1

enemy00_upload_2k:
        call    vdc_di_to_mawr
        ldx     #8                      ; 8 pages x 256 bytes = 2048 bytes
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
        rts

; C64 sprite animation: timer++, (timer & 6)>>1 gives frame 0..3, each for two ticks.
enemy00_update_satb:
        lda     enemy00_active
        bne     .show
        jmp     enemy00_hide
.show:
        ; Smiley entries 8/9. C64 hardware X/Y -> PCE SAT: +8 X, +14 Y.
        lda     #<ENEMY00_SMILEY_L
        sta     <_di
        lda     #>ENEMY00_SMILEY_L
        sta     <_di+1
        call    vdc_di_to_mawr
        lda     enemy00_smiley_anim
        and     #$06
        lsr     a
        sta     enemy00_tmp
        lda     enemy00_smiley_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     enemy00_smiley_x
        clc
        adc     #8
        sta     VDC_DL
        stz     VDC_DH
        call    enemy00_smiley_pat_left
        lda     #$84                    ; sprite palette slot20 -> index4
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        lda     enemy00_smiley_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     enemy00_smiley_x
        clc
        adc     #24
        sta     VDC_DL
        stz     VDC_DH
        call    enemy00_smiley_pat_right
        lda     #$84
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        ; Skate entries 10/11.
        lda     enemy00_skate_anim
        and     #$06
        lsr     a
        sta     enemy00_tmp
        lda     enemy00_skate_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     enemy00_skate_x
        clc
        adc     #8
        sta     VDC_DL
        stz     VDC_DH
        call    enemy00_skate_pat_left
        lda     #$83                    ; sprite palette slot19 -> index3
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        lda     enemy00_skate_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     enemy00_skate_x
        clc
        adc     #24
        sta     VDC_DL
        stz     VDC_DH
        call    enemy00_skate_pat_right
        lda     #$83
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH
        jmp     enemy00_sat_dma

enemy00_hide:
        lda     #<ENEMY00_SMILEY_L
        sta     <_di
        lda     #>ENEMY00_SMILEY_L
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #4
.hide_loop:
        cla
        sta     VDC_DL
        lda     #1
        sta     VDC_DH
        cla
        sta     VDC_DL
        sta     VDC_DH
        sta     VDC_DL
        sta     VDC_DH
        sta     VDC_DL
        sta     VDC_DH
        dex
        bne     .hide_loop

enemy00_sat_dma:
        st0     #$13
        st1     #<SAT_ADDR
        st2     #>SAT_ADDR
        rts

; Pattern number is VRAM word address >>5. Each frame is $100 words; right half +$40.
enemy00_smiley_pat_left:
        lda     enemy00_tmp
        asl     a
        asl     a
        asl     a
        clc
        adc     #<(ENEMY00_SMILEY_VRAM>>5)
        sta     VDC_DL
        lda     #>(ENEMY00_SMILEY_VRAM>>5)
        adc     #0
        sta     VDC_DH
        rts
enemy00_smiley_pat_right:
        lda     enemy00_tmp
        asl     a
        asl     a
        asl     a
        clc
        adc     #<((ENEMY00_SMILEY_VRAM+$40)>>5)
        sta     VDC_DL
        lda     #>((ENEMY00_SMILEY_VRAM+$40)>>5)
        adc     #0
        sta     VDC_DH
        rts
enemy00_skate_pat_left:
        lda     enemy00_tmp
        asl     a
        asl     a
        asl     a
        clc
        adc     #<(ENEMY00_SKATE_VRAM>>5)
        sta     VDC_DL
        lda     #>(ENEMY00_SKATE_VRAM>>5)
        adc     #0
        sta     VDC_DH
        rts
enemy00_skate_pat_right:
        lda     enemy00_tmp
        asl     a
        asl     a
        asl     a
        clc
        adc     #<((ENEMY00_SKATE_VRAM+$40)>>5)
        sta     VDC_DL
        lda     #>((ENEMY00_SKATE_VRAM+$40)>>5)
        adc     #0
        sta     VDC_DH
        rts
