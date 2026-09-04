; Native PCE sprite bridge for Monty: authentic C64 walk L/R frames.
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
 rts

; Select frame pointer table from C64-facing state (0=right,$80=left).
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
 lda monty_r_ptr_lo,x
 sta <_bp
 lda monty_r_ptr_hi,x
 sta <_bp+1
 lda monty_r_ptr_bank,x
 bra .bank
.left:
 lda monty_l_ptr_lo,x
 sta <_bp
 lda monty_l_ptr_hi,x
 sta <_bp+1
 lda monty_l_ptr_bank,x
.bank:
 tay
 tia [_bp],VDC_DL,512
 stz <monty_sprite_dirty
 lda <monty_facing
 sta <monty_sprite_last_facing
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
 lda #$00
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
 lda #<((MONTY_SPR_VRAM+128)>>5)
 sta VDC_DL
 lda #>((MONTY_SPR_VRAM+128)>>5)
 sta VDC_DH
 lda #$00
 sta VDC_DL
 lda #$10
 sta VDC_DH
 rts
.data
monty_l_ptr_lo: db <monty_walk_l_0,<monty_walk_l_1,<monty_walk_l_2,<monty_walk_l_3
monty_l_ptr_hi: db >monty_walk_l_0,>monty_walk_l_1,>monty_walk_l_2,>monty_walk_l_3
monty_l_ptr_bank: db ^monty_walk_l_0,^monty_walk_l_1,^monty_walk_l_2,^monty_walk_l_3
monty_r_ptr_lo: db <monty_walk_r_0,<monty_walk_r_1,<monty_walk_r_2,<monty_walk_r_3
monty_r_ptr_hi: db >monty_walk_r_0,>monty_walk_r_1,>monty_walk_r_2,>monty_walk_r_3
monty_r_ptr_bank: db ^monty_walk_r_0,^monty_walk_r_1,^monty_walk_r_2,^monty_walk_r_3
monty_walk_l_0: incbin "monty-walk-l.dat",0,512
monty_walk_l_1: incbin "monty-walk-l.dat",512,512
monty_walk_l_2: incbin "monty-walk-l.dat",1024,512
monty_walk_l_3: incbin "monty-walk-l.dat",1536,512
monty_walk_r_0: incbin "monty-walk-r.dat",0,512
monty_walk_r_1: incbin "monty-walk-r.dat",512,512
monty_walk_r_2: incbin "monty-walk-r.dat",1024,512
monty_walk_r_3: incbin "monty-walk-r.dat",1536,512
