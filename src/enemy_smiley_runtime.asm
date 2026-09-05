; First authentic moving enemy stage: Room $00 Smiley only.
; Original spawn record: 05 b8 8f 04 19 02 25
; SetupRoom -> X=$78, Y=$6a, vertical speed 2, range $25, initial dir forward.
;
; Runtime uses PCEAS --newproc relocation.  Newproc thunks live at the end of
; MPR7, save MPR6, map the target proc bank into $C000-$DFFF, then JMP to it.
; Therefore every exit from a relocated .proc MUST use PCEAS "leave" so the
; generated leave_proc helper restores MPR6 before RTS.  Raw RTS is invalid.
; Large sprite art remains independent and uses the proven MPR3/MPR4 upload
; path used by lift/cloud, with both mappings saved/restored around the upload.

ENEMY_SMILEY_VRAM  = $3800
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

; Cold-start state plus one bank-safe 2 KiB graphics upload.
.proc enemy_smiley_init
        lda     #$ff
        sta     enemy_smiley_last_room
        stz     enemy_smiley_active

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

        pla
        tam4
        pla
        tam3
        plp

        ; Nested proc CALL is safe: its thunk saves the current MPR6 mapping.
        call    enemy_smiley_room_sync
        leave
.endp

; Re-seed the original Room-$00 enemy record on room entry.
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
        leave
.room00:
        lda     #1
        sta     enemy_smiley_active
        lda     #$6a
        sta     enemy_smiley_y
        lda     #$01                    ; dir_idx4 -> vertical, forward/down
        sta     enemy_smiley_flags
        stz     enemy_smiley_count
        stz     enemy_smiley_anim
        leave
.endp

; Exact C64 MoveVertical state for record 05 b8 8f 04 19 02 25.
.proc enemy_smiley_update
        lda     enemy_smiley_active
        bne     .active
        leave
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
        leave
.endp

; Writes SAT entries 8/9 only.  The cloud routine remains the final SAT-DMA
; writer in main_loop, so this proc never changes the already-proven DMA order.
.proc enemy_smiley_update_satb
        lda     enemy_smiley_active
        bne     .show

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
        lda     enemy_smiley_anim
        and     #$06
        lsr     a
        sta     enemy_smiley_frame

        lda     #<ENEMY_SMILEY_SAT_L
        sta     <_di
        lda     #>ENEMY_SMILEY_SAT_L
        sta     <_di+1
        call    vdc_di_to_mawr

        ; Left 16x32 half. Original hardware X=$78 -> PCE SAT X=$80.
        lda     enemy_smiley_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     #$80
        sta     VDC_DL
        stz     VDC_DH
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
        lda     #$83                    ; sprite palette slot19 -> index3
        sta     VDC_DL
        lda     #$10                    ; 16x32
        sta     VDC_DH

        ; Right 16x32 half.
        lda     enemy_smiley_y
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH
        lda     #$90
        sta     VDC_DL
        stz     VDC_DH
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
        leave
.endp
