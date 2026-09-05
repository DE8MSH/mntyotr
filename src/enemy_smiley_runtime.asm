; Authentic Room $00 moving enemies: Smiley + Skate.
; Original records:
;   Smiley 05 b8 8f 04 19 02 25 -> X=$78,Y=$6a, flags=$01,count=0, speed2, range$25
;   Skate  03 78 37 03 09 03 13 -> X=$58,Y=$c2, flags=$81,count=$13,speed3, range$13
;
; PCEAS --newproc thunks live at the end of MPR7, save MPR6, map the target
; proc bank into $C000-$DFFF, then JMP to it. Every .proc exit MUST use leave.
; Large sprite art uses the proven MPR3/MPR4 far-data upload path.
;
; C64 Enemies.Tick is gated by frame_toggle=1, so enemy movement/animation runs
; at half the PAL game-frame rate. game_tick_counter bit0 reproduces that gate.

ENEMY_SMILEY_VRAM  = $3800
ENEMY_SKATE_VRAM   = $3c00
ENEMY_SMILEY_SAT_L = SAT_ADDR+32      ; SAT entry 8
ENEMY_SMILEY_SAT_R = SAT_ADDR+36      ; SAT entry 9
ENEMY_SKATE_SAT_L  = SAT_ADDR+40      ; SAT entry 10
ENEMY_SKATE_SAT_R  = SAT_ADDR+44      ; SAT entry 11

.bss
enemy_smiley_last_room: ds 1
enemy_smiley_active:    ds 1
enemy_smiley_x:         ds 1
enemy_smiley_y:         ds 1
enemy_smiley_flags:     ds 1
enemy_smiley_count:     ds 1
enemy_smiley_anim:      ds 1
enemy_smiley_frame:     ds 1
enemy_skate_active:     ds 1
enemy_skate_x:          ds 1
enemy_skate_y:          ds 1
enemy_skate_flags:      ds 1
enemy_skate_count:      ds 1
enemy_skate_anim:       ds 1
enemy_skate_frame:      ds 1

.code

; Cold-start palettes plus both authentic 2 KiB sprite payloads.
.proc enemy_smiley_init
        lda     #$ff
        sta     enemy_smiley_last_room
        stz     enemy_smiley_active
        stz     enemy_skate_active

        ; Sprite palette 19: Smiley, C64 cyan $03.
        lda     #19
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<enemy00_smiley_palette
        sta     <_bp
        lda     #>enemy00_smiley_palette
        sta     <_bp+1
        ldy     #BANK(enemy00_smiley_palette)
        call    load_palettes

        ; Sprite palette 20: Skate, C64 purple $04.
        lda     #20
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<enemy00_skate_palette
        sta     <_bp
        lda     #>enemy00_skate_palette
        sta     <_bp+1
        ldy     #BANK(enemy00_skate_palette)
        call    load_palettes
        call    xfer_palettes

        php
        sei
        tma3
        pha
        tma4
        pha

        ; Smiley: four 512-byte frames.
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
        ldx     #8
        cly
.smiley_page:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        bne     .smiley_page
        inc     <_bp+1
        dex
        bne     .smiley_page

        ; Skate: four 512-byte frames.
        lda     #<enemy00_skate_patterns
        sta     <_bp
        lda     #>enemy00_skate_patterns
        sta     <_bp+1
        ldy     #BANK(enemy00_skate_patterns)
        call    map_bp_to_mpr34
        lda     #<ENEMY_SKATE_VRAM
        sta     <_di
        lda     #>ENEMY_SKATE_VRAM
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #8
        cly
.skate_page:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        bne     .skate_page
        inc     <_bp+1
        dex
        bne     .skate_page

        pla
        tam4
        pla
        tam3
        plp

        call    enemy_smiley_room_sync
        leave
.endp

; Re-seed both exact C64 Room-$00 state records on room entry.
.proc enemy_smiley_room_sync
        lda     <monty_room
        cmp     enemy_smiley_last_room
        bne     .changed
        leave
.changed:
        sta     enemy_smiley_last_room
        cmp     #$00
        beq     .room00
        stz     enemy_smiley_active
        stz     enemy_skate_active
        leave
.room00:
        lda     #1
        sta     enemy_smiley_active
        sta     enemy_skate_active

        lda     #$78
        sta     enemy_smiley_x
        lda     #$6a
        sta     enemy_smiley_y
        lda     #$01                    ; dir_idx4 -> vertical/down
        sta     enemy_smiley_flags
        stz     enemy_smiley_count
        stz     enemy_smiley_anim

        lda     #$58
        sta     enemy_skate_x
        lda     #$c2
        sta     enemy_skate_y
        lda     #$81                    ; dir_idx3 -> vertical/up
        sta     enemy_skate_flags
        lda     #$13                    ; negative flags preserve range as count
        sta     enemy_skate_count
        stz     enemy_skate_anim
        leave
.endp

; Exact C64 MoveVertical for both Room-$00 records. Enemies.Tick itself is
; called only on odd frame_toggle; game_tick_counter bit0 reproduces that.
.proc enemy_smiley_update
        lda     <game_tick_counter
        and     #$01
        bne     .tick
        leave
.tick:
        lda     enemy_smiley_active
        beq     .skate

        lda     enemy_smiley_flags
        bmi     .smiley_up
        inc     enemy_smiley_count
        lda     enemy_smiley_count
        cmp     #$25
        bne     .smiley_down_move
        lda     enemy_smiley_flags
        eor     #$80
        sta     enemy_smiley_flags
        bra     .smiley_anim
.smiley_down_move:
        lda     enemy_smiley_y
        clc
        adc     #2
        sta     enemy_smiley_y
        bra     .smiley_anim
.smiley_up:
        dec     enemy_smiley_count
        bne     .smiley_up_move
        lda     enemy_smiley_flags
        eor     #$80
        sta     enemy_smiley_flags
        bra     .smiley_anim
.smiley_up_move:
        lda     enemy_smiley_y
        sec
        sbc     #2
        sta     enemy_smiley_y
.smiley_anim:
        inc     enemy_smiley_anim

.skate:
        lda     enemy_skate_active
        bne     .skate_active
        leave
.skate_active:
        lda     enemy_skate_flags
        bmi     .skate_up
        inc     enemy_skate_count
        lda     enemy_skate_count
        cmp     #$13
        bne     .skate_down_move
        lda     enemy_skate_flags
        eor     #$80
        sta     enemy_skate_flags
        bra     .skate_anim
.skate_down_move:
        lda     enemy_skate_y
        clc
        adc     #3
        sta     enemy_skate_y
        bra     .skate_anim
.skate_up:
        dec     enemy_skate_count
        bne     .skate_up_move
        lda     enemy_skate_flags
        eor     #$80
        sta     enemy_skate_flags
        bra     .skate_anim
.skate_up_move:
        lda     enemy_skate_y
        sec
        sbc     #3
        sta     enemy_skate_y
.skate_anim:
        inc     enemy_skate_anim
        leave
.endp

; Exact C64 enemy coordinate bridge:
; SetupRoom stores a half-X in enemy_state_tbl. ProcessSprites later ASLs that
; byte when writing VIC X. With the PCE SAT +32 origin versus C64 game +24,
; SAT X = 2*enemy_x + 8. Y is already VIC Y, so SAT Y = enemy_y + 14.
.proc enemy_smiley_update_satb
        lda     enemy_smiley_active
        bne     .show

        lda     #<ENEMY_SMILEY_SAT_L
        sta     <_di
        lda     #>ENEMY_SMILEY_SAT_L
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #4
.hide_loop:
        cla
        sta     VDC_DL
        lda     #1
        sta     VDC_DH                  ; Y=$0100, offscreen
        cla
        sta     VDC_DL
        sta     VDC_DH
        sta     VDC_DL
        sta     VDC_DH
        sta     VDC_DL
        sta     VDC_DH
        dex
        bne     .hide_loop
        leave

.show:
        ; Smiley frame: C64 (timer & 6)>>1, four unique frames reused both dirs.
        lda     enemy_smiley_anim
        and     #$06
        lsr     a
        sta     enemy_smiley_frame

        lda     #<ENEMY_SMILEY_SAT_L
        sta     <_di
        lda     #>ENEMY_SMILEY_SAT_L
        sta     <_di+1
        call    vdc_di_to_mawr

        ; Smiley left half: SAT X = 2*$78+8 = $00F8.
        lda     enemy_smiley_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     enemy_smiley_x
        asl     a
        ldx     #0
        bcc     .sm_l_mul_ok
        inx
.sm_l_mul_ok:
        clc
        adc     #8
        bcc     .sm_l_add_ok
        inx
.sm_l_add_ok:
        sta     VDC_DL
        stx     VDC_DH
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
        lda     #$83                    ; sprite palette slot19
        sta     VDC_DL
        lda     #$10                    ; 16x32
        sta     VDC_DH

        ; Smiley right half: SAT X = 2*$78+24 = $0108.
        lda     enemy_smiley_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     enemy_smiley_x
        asl     a
        ldx     #0
        bcc     .sm_r_mul_ok
        inx
.sm_r_mul_ok:
        clc
        adc     #24
        bcc     .sm_r_add_ok
        inx
.sm_r_add_ok:
        sta     VDC_DL
        stx     VDC_DH
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
        lda     #$83
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        ; Skate frame and SAT entries 10/11 immediately follow Smiley 8/9.
        lda     enemy_skate_anim
        and     #$06
        lsr     a
        sta     enemy_skate_frame

        ; Skate left half: SAT X = 2*$58+8 = $00B8.
        lda     enemy_skate_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     enemy_skate_x
        asl     a
        ldx     #0
        bcc     .sk_l_mul_ok
        inx
.sk_l_mul_ok:
        clc
        adc     #8
        bcc     .sk_l_add_ok
        inx
.sk_l_add_ok:
        sta     VDC_DL
        stx     VDC_DH
        lda     enemy_skate_frame
        asl     a
        asl     a
        asl     a
        clc
        adc     #<(ENEMY_SKATE_VRAM>>5)
        sta     VDC_DL
        lda     #>(ENEMY_SKATE_VRAM>>5)
        adc     #0
        sta     VDC_DH
        lda     #$84                    ; sprite palette slot20
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        ; Skate right half: SAT X = 2*$58+24 = $00C8.
        lda     enemy_skate_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     enemy_skate_x
        asl     a
        ldx     #0
        bcc     .sk_r_mul_ok
        inx
.sk_r_mul_ok:
        clc
        adc     #24
        bcc     .sk_r_add_ok
        inx
.sk_r_add_ok:
        sta     VDC_DL
        stx     VDC_DH
        lda     enemy_skate_frame
        asl     a
        asl     a
        asl     a
        clc
        adc     #<((ENEMY_SKATE_VRAM+$40)>>5)
        sta     VDC_DL
        lda     #>((ENEMY_SKATE_VRAM+$40)>>5)
        adc     #0
        sta     VDC_DH
        lda     #$84
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH
        leave
.endp
