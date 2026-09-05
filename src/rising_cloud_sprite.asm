; Phase 50: visible authentic rising-cloud sprite for Room $01.
; Collision continues to be maintained by rising_cloud.asm. This module renders
; the original C64 frames $98/$99/$9A with the wobble cycle $98,$99,$9A,$99
; while following rising_cloud_y pixel-for-pixel.

CLOUD_SPR_VRAM = $3400
CLOUD_SAT_LEFT = SAT_ADDR+24          ; SAT entry 6
CLOUD_SAT_RIGHT= SAT_ADDR+28          ; SAT entry 7
CLOUD_SAT_X    = 128                  ; screen col $0C (96px) + PCE SAT origin 32

.zp
rising_cloud_sprite_frame: ds 1

.code

rising_cloud_sprite_init:
        call    rising_cloud_sprite_upload
        jmp     rising_cloud_sprite_update_satb

rising_cloud_sprite_upload:
        php
        sei
        tma3
        pha
        tma4
        pha
        lda     #<rising_cloud_patterns
        sta     <_bp
        lda     #>rising_cloud_patterns
        sta     <_bp+1
        ldy     #BANK(rising_cloud_patterns)
        call    map_bp_to_mpr34
        lda     #<CLOUD_SPR_VRAM
        sta     <_di
        lda     #>CLOUD_SPR_VRAM
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #6
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

rising_cloud_sprite_select_frame:
        lda     <rising_cloud_tick
        and     #$0c
        lsr     a
        lsr     a
        tax
        lda     rising_cloud_sprite_cycle,x
        sta     <rising_cloud_sprite_frame
        rts

rising_cloud_sprite_update_satb:
        lda     <monty_room
        cmp     #1
        beq     .room01
        jmp     rising_cloud_sprite_hide
.room01:
        lda     <rising_cloud_y
        cmp     #$da
        bcc     .check_top
        jmp     rising_cloud_sprite_hide
.check_top:
        cmp     #$40
        bcs     .visible
        jmp     rising_cloud_sprite_hide
.visible:
        call    rising_cloud_sprite_select_frame
        lda     #<CLOUD_SAT_LEFT
        sta     <_di
        lda     #>CLOUD_SAT_LEFT
        sta     <_di+1
        call    vdc_di_to_mawr

        lda     <rising_cloud_y
        clc
        adc     #15
        sta     VDC_DL
        stz     VDC_DH
        lda     #<CLOUD_SAT_X
        sta     VDC_DL
        lda     #>CLOUD_SAT_X
        sta     VDC_DH
        ldx     <rising_cloud_sprite_frame
        lda     rising_cloud_pat_left_lo,x
        sta     VDC_DL
        lda     rising_cloud_pat_left_hi,x
        sta     VDC_DH
        lda     #$82
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        lda     <rising_cloud_y
        clc
        adc     #15
        sta     VDC_DL
        stz     VDC_DH
        lda     #<(CLOUD_SAT_X+16)
        sta     VDC_DL
        lda     #>(CLOUD_SAT_X+16)
        sta     VDC_DH
        ldx     <rising_cloud_sprite_frame
        lda     rising_cloud_pat_right_lo,x
        sta     VDC_DL
        lda     rising_cloud_pat_right_hi,x
        sta     VDC_DH
        lda     #$82
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH
        jmp     rising_cloud_sprite_sat_dma

rising_cloud_sprite_hide:
        lda     #<CLOUD_SAT_LEFT
        sta     <_di
        lda     #>CLOUD_SAT_LEFT
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #2
.hide_one:
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
        bne     .hide_one

; Final SAT writer in main_loop. Arm one SAT DMA and return immediately.
; Debug/HUD BAT text is static between state changes and must not be redrawn on
; every frame; doing so wasted VDC bandwidth and bank-switch time.
rising_cloud_sprite_sat_dma:
        st0     #$13
        st1     #<SAT_ADDR
        st2     #>SAT_ADDR
        rts

.data
rising_cloud_sprite_cycle:
        db 0,1,2,1
rising_cloud_pat_left_lo:
        db $a0,$a8,$b0
rising_cloud_pat_left_hi:
        db $01,$01,$01
rising_cloud_pat_right_lo:
        db $a2,$aa,$b2
rising_cloud_pat_right_hi:
        db $01,$01,$01
