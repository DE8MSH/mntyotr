; Native PCE sprite bridge for Monty.
; The source frames are authentic C64 24x21 walk-left frames converted by
; tools/monty_sprite.py. Two adjacent 16x32 PCE sprites preserve 24px width.

MONTY_SPR_VRAM   = $3000
MONTY_SPR_WORDS  = 256          ; one converted frame = 512 bytes
MONTY_SAT_LEFT   = SAT_ADDR
MONTY_SAT_RIGHT  = SAT_ADDR + 4

.zp
monty_anim_frame:       ds 1
monty_anim_timer:       ds 1
monty_sprite_dirty:     ds 1

.code

monty_sprite_init:
        stz     <monty_anim_frame
        lda     #4
        sta     <monty_anim_timer
        lda     #1
        sta     <monty_sprite_dirty
        bsr     monty_upload_walk_frame
        rts

; Upload the selected 512-byte converted frame to sprite VRAM.
; Frame data is arranged as left-top,left-bottom,right-top,right-bottom 16x16 cells.
monty_upload_walk_frame:
        lda     #<MONTY_SPR_VRAM
        sta     <_di
        lda     #>MONTY_SPR_VRAM
        sta     <_di+1
        call    vdc_di_to_mawr

        lda     <monty_anim_frame
        and     #3
        tax
        lda     monty_frame_ptr_lo,x
        sta     <_bp
        lda     monty_frame_ptr_hi,x
        sta     <_bp+1
        lda     monty_frame_ptr_bank,x
        tay

        ; 512 bytes / 2 = 256 VDC words. TIA handles VDC data-port alternation.
        tia     [_bp],VDC_DL,512
        stz     <monty_sprite_dirty
        rts

; Keep the original C64 four-frame walking cadence: one frame every 4 logical ticks.
monty_sprite_animate:
        dec     <monty_anim_timer
        bne     .done
        lda     #4
        sta     <monty_anim_timer
        inc     <monty_anim_frame
        lda     <monty_anim_frame
        and     #3
        sta     <monty_anim_frame
        lda     #1
        sta     <monty_sprite_dirty
.done:
        lda     <monty_sprite_dirty
        beq     .no_upload
        bsr     monty_upload_walk_frame
.no_upload:
        rts

; SATB entries are 8 bytes: Y, X, pattern, attributes. PCE hardware position
; has +64 X and +64 Y origin biases. We write two 16x32 sprites side by side.
monty_sprite_update_satb:
        ; left sprite
        lda     #<MONTY_SAT_LEFT
        sta     <_di
        lda     #>MONTY_SAT_LEFT
        sta     <_di+1
        call    vdc_di_to_mawr
        lda     <monty_y
        clc
        adc     #64
        sta     VDC_DL
        stz     VDC_DH
        lda     <monty_x
        clc
        adc     #64
        sta     VDC_DL
        stz     VDC_DH
        lda     #<(MONTY_SPR_VRAM >> 5)
        sta     VDC_DL
        lda     #>(MONTY_SPR_VRAM >> 5)
        sta     VDC_DH
        lda     #$00
        sta     VDC_DL
        lda     #$10                ; 16x32, foreground priority
        sta     VDC_DH

        ; right sprite, same Y, X+16; second 16x32 pattern starts after 256 bytes.
        lda     <monty_y
        clc
        adc     #64
        sta     VDC_DL
        stz     VDC_DH
        lda     <monty_x
        clc
        adc     #80
        sta     VDC_DL
        stz     VDC_DH
        lda     #<((MONTY_SPR_VRAM + 128) >> 5)
        sta     VDC_DL
        lda     #>((MONTY_SPR_VRAM + 128) >> 5)
        sta     VDC_DH
        lda     #$00
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH
        rts

.data
monty_frame_ptr_lo:
        db <monty_walk_l_0,<monty_walk_l_1,<monty_walk_l_2,<monty_walk_l_3
monty_frame_ptr_hi:
        db >monty_walk_l_0,>monty_walk_l_1,>monty_walk_l_2,>monty_walk_l_3
monty_frame_ptr_bank:
        db ^monty_walk_l_0,^monty_walk_l_1,^monty_walk_l_2,^monty_walk_l_3

monty_walk_l_0:
        incbin "monty-walk-l.dat",0,512
monty_walk_l_1:
        incbin "monty-walk-l.dat",512,512
monty_walk_l_2:
        incbin "monty-walk-l.dat",1024,512
monty_walk_l_3:
        incbin "monty-walk-l.dat",1536,512
