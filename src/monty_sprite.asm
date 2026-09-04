; Native PCE sprite bridge for Monty: authentic C64 walk L/R and climb frames.
MONTY_SPR_VRAM=$3000
MONTY_SAT_LEFT=SAT_ADDR
MONTY_SAT_RIGHT=SAT_ADDR+4
.zp
monty_anim_frame: ds 1
monty_anim_timer: ds 1
monty_sprite_dirty: ds 1
monty_sprite_last_facing: ds 1
.code
monty_sprite_init:
 stz <monty_anim_frame
 lda #4
 sta <monty_anim_timer
 lda #$ff
 sta <monty_sprite_last_facing
 lda #1
 sta <monty_sprite_dirty
 bsr monty_upload_walk_frame
 st0 #$13
 st1 #<SAT_ADDR
 st2 #>SAT_ADDR
 rts

; PCEAS block-transfer operands are absolute addresses.  The old code tried
; `tia [_bp],...`, but TIA has no indirect-source addressing mode.  Dispatch
; the small frame set first and assemble a real TIA for each source label.
monty_upload_walk_frame:
 lda #<MONTY_SPR_VRAM
 sta <_di
 lda #>MONTY_SPR_VRAM
 sta <_di+1
 call vdc_di_to_mawr
 lda <monty_anim_frame
 and #3
 tax
 lda <monty_facing
 bmi .left
 cpx #0
 beq .r0
 cpx #1
 beq .r1
 cpx #2
 beq .r2
 tia monty_walk_r_3,VDC_DL,512
 bra .uploaded
.r0:
 tia monty_walk_r_0,VDC_DL,512
 bra .uploaded
.r1:
 tia monty_walk_r_1,VDC_DL,512
 bra .uploaded
.r2:
 tia monty_walk_r_2,VDC_DL,512
 bra .uploaded
.left:
 cpx #0
 beq .l0
 cpx #1
 beq .l1
 cpx #2
 beq .l2
 tia monty_walk_l_3,VDC_DL,512
 bra .uploaded
.l0:
 tia monty_walk_l_0,VDC_DL,512
 bra .uploaded
.l1:
 tia monty_walk_l_1,VDC_DL,512
 bra .uploaded
.l2:
 tia monty_walk_l_2,VDC_DL,512
.uploaded:
 stz <monty_sprite_dirty
 lda <monty_facing
 sta <monty_sprite_last_facing
 rts

monty_upload_climb_frame:
 lda #<MONTY_SPR_VRAM
 sta <_di
 lda #>MONTY_SPR_VRAM
 sta <_di+1
 call vdc_di_to_mawr
 lda <monty_anim_frame
 and #3
 tax
 cpx #0
 beq .c0
 cpx #1
 beq .c1
 cpx #2
 beq .c2
 tia monty_climb_3,VDC_DL,512
 bra .cdone
.c0:
 tia monty_climb_0,VDC_DL,512
 bra .cdone
.c1:
 tia monty_climb_1,VDC_DL,512
 bra .cdone
.c2:
 tia monty_climb_2,VDC_DL,512
.cdone:
 stz <monty_sprite_dirty
 rts

monty_sprite_animate:
 lda <monty_facing
 cmp <monty_sprite_last_facing
 beq .same_dir
 lda #1
 sta <monty_sprite_dirty
.same_dir:
 dec <monty_anim_timer
 bne .maybe
 lda #4
 sta <monty_anim_timer
 inc <monty_anim_frame
 lda <monty_anim_frame
 and #3
 sta <monty_anim_frame
 lda #1
 sta <monty_sprite_dirty
.maybe:
 lda <monty_sprite_dirty
 beq .done
 bsr monty_upload_walk_frame
.done:
 rts

monty_sprite_update_satb:
 lda #<MONTY_SAT_LEFT
 sta <_di
 lda #>MONTY_SAT_LEFT
 sta <_di+1
 call vdc_di_to_mawr
 lda <monty_y
 clc
 adc #64
 sta VDC_DL
 stz VDC_DH
 lda <monty_x
 clc
 adc #64
 sta VDC_DL
 stz VDC_DH
 lda #<(MONTY_SPR_VRAM>>5)
 sta VDC_DL
 lda #>(MONTY_SPR_VRAM>>5)
 sta VDC_DH
 lda #$80
 sta VDC_DL
 lda #$10
 sta VDC_DH
 lda <monty_y
 clc
 adc #64
 sta VDC_DL
 stz VDC_DH
 lda <monty_x
 clc
 adc #80
 sta VDC_DL
 stz VDC_DH
 lda #<((MONTY_SPR_VRAM+256)>>5)
 sta VDC_DL
 lda #>((MONTY_SPR_VRAM+256)>>5)
 sta VDC_DH
 lda #$80
 sta VDC_DL
 lda #$10
 sta VDC_DH
 st0 #$13
 st1 #<SAT_ADDR
 st2 #>SAT_ADDR
 rts
.data
monty_walk_l_0: incbin "monty-walk-l.dat",0,512
monty_walk_l_1: incbin "monty-walk-l.dat",512,512
monty_walk_l_2: incbin "monty-walk-l.dat",1024,512
monty_walk_l_3: incbin "monty-walk-l.dat",1536,512
monty_walk_r_0: incbin "monty-walk-r.dat",0,512
monty_walk_r_1: incbin "monty-walk-r.dat",512,512
monty_walk_r_2: incbin "monty-walk-r.dat",1024,512
monty_walk_r_3: incbin "monty-walk-r.dat",1536,512
monty_climb_0: incbin "monty-climb.dat",0,512
monty_climb_1: incbin "monty-climb.dat",512,512
monty_climb_2: incbin "monty-climb.dat",1024,512
monty_climb_3: incbin "monty-climb.dat",1536,512
