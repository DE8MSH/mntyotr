; First authentic moving enemy stage: Room $00 Smiley only.
; Keeps runtime in the proven main code bank and banks only the large sprite art.
; Original spawn record: 05 b8 8f 04 19 02 25
; SetupRoom -> X=$78, Y=$6a, vertical speed 2, range $25, initial dir forward.

ENEMY_SMILEY_VRAM = $3800
ENEMY_SMILEY_SAT_L = SAT_ADDR+32      ; SAT entry 8
ENEMY_SMILEY_SAT_R = SAT_ADDR+36      ; SAT entry 9

.bss
enemy_smiley_last_room: ds 1
enemy_smiley_active:    ds 1
enemy_smiley_y:         ds 1
enemy_smiley_flags:     ds 1
enemy_smiley_count:     ds 1
enemy_smiley_anim:      ds 1
enemy_smiley_frame:     ds 1

.code

enemy_smiley_init:
        lda     #$ff
        sta     enemy_smiley_last_room
        stz     enemy_smiley_active
        call    enemy_smiley_upload_patterns
        jmp     enemy_smiley_room_sync

enemy_smiley_room_sync:
        lda     <monty_room
        cmp     enemy_smiley_last_room
        bne     .changed
        rts
.changed:
        sta     enemy_smiley_last_room
        cmp     #$00
        beq     .room00
        stz     enemy_smiley_active
        rts
.room00:
        lda     #1
        sta     enemy_smiley_active
        lda     #$6a
        sta     enemy_smiley_y
        lda     #$01
        sta     enemy_smiley_flags
        stz     enemy_smiley_count
        stz     enemy_smiley_anim
        rts

; Exact C64 MoveVertical state for this record.
enemy_smiley_update:
        lda     enemy_smiley_active
        bne     .active
        rts
.active:
        lda     enemy_smiley_flags
        bmi     .up

        inc     enemy_smiley_count
        lda     enemy_smiley_count
        cmp     #$25
        bne     .down_move
        lda     enemy_smiley_flags
        eor     #$80
        sta     enemy_smiley_flags
        bra     .anim
.down_move:
        lda     enemy_smiley_y
        clc
        adc     #2
        sta     enemy_smiley_y
        bra     .anim

.up:
        dec     enemy_smiley_count
        bne     .up_move
        lda     enemy_smiley_flags
        eor     #$80
        sta     enemy_smiley_flags
        bra     .anim
.up_move:
        lda     enemy_smiley_y
        sec
        sbc     #2
        sta     enemy_smiley_y
.anim:
        inc     enemy_smiley_anim
        rts

; Bank only the 2 KiB sprite payload, following the already proven lift/cloud path.
enemy_smiley_upload_patterns:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<enemy00_smiley_patterns
        sta     <_bp
        lda     #>enemy00_smiley_patterns
        sta     <_bp+1
        ldy     #BANK(enemy00_smiley_patterns)
        call    map_bp_to_mpr34

        lda     #<ENEMY_SMILEY_VRAM
        sta     <_di
        lda     #>ENEMY_SMILEY_VRAM
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #8                      ; 2048 bytes
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
        rts

; Writes SAT entries 8/9 only. Rising cloud remains the final SAT-DMA writer.
enemy_smiley_update_satb:
        lda     enemy_smiley_active
        bne     .show
        jmp     enemy_smiley_hide
.show:
        lda     enemy_smiley_anim
        and     #$06
        lsr     a
        sta     enemy_smiley_frame

        lda     #<ENEMY_SMILEY_SAT_L
        sta     <_di
        lda     #>ENEMY_SMILEY_SAT_L
        sta     <_di+1
        call    vdc_di_to_mawr

        ; left 16x32 half, original hardware X=$78 -> PCE SAT X=$80.
        lda     enemy_smiley_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     #$80
        sta     VDC_DL
        stz     VDC_DH
        call    enemy_smiley_pattern_left
        lda     #$83                    ; sprite palette slot19 -> index3
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        ; right 16x32 half.
        lda     enemy_smiley_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     #$90
        sta     VDC_DL
        stz     VDC_DH
        call    enemy_smiley_pattern_right
        lda     #$83
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH
        rts

enemy_smiley_hide:
        lda     #<ENEMY_SMILEY_SAT_L
        sta     <_di
        lda     #>ENEMY_SMILEY_SAT_L
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #2
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
        rts

enemy_smiley_pattern_left:
        lda     enemy_smiley_frame
        asl     a
        asl     a
        asl     a
        clc
        adc     #<(ENEMY_SMILEY_VRAM>>5)
        sta     VDC_DL
        lda     #>(ENEMY_SMILEY_VRAM>>5)
        adc     #0
        sta     VDC_DH
        rts

enemy_smiley_pattern_right:
        lda     enemy_smiley_frame
        asl     a
        asl     a
        asl     a
        clc
        adc     #<((ENEMY_SMILEY_VRAM+$40)>>5)
        sta     VDC_DL
        lda     #>((ENEMY_SMILEY_VRAM+$40)>>5)
        adc     #0
        sta     VDC_DH
        rts
