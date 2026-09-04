; Native PCE sprite bridge for Monty: authentic C64 walk L/R, climb and somersault frames.
MONTY_SPR_VRAM=$3000
MONTY_SAT_LEFT=SAT_ADDR
MONTY_SAT_RIGHT=SAT_ADDR+4
.zp
monty_anim_frame: ds 1
monty_anim_timer: ds 1
monty_sprite_dirty: ds 1
monty_sprite_last_facing: ds 1
monty_sprite_last_mode: ds 1       ; 0=walk, 1=climb, 2=jump/somersault
.code

monty_sprite_init:
 stz <monty_anim_frame
 lda #4
 sta <monty_anim_timer
 lda #$ff
 sta <monty_sprite_last_facing
 sta <monty_sprite_last_mode
 lda #1
 sta <monty_sprite_dirty
 call monty_upload_walk_frame
 stz <monty_sprite_last_mode
 st0 #$13
 st1 #<SAT_ADDR
 st2 #>SAT_ADDR
 rts

; All frame uploads use the same bank-safe 512-byte path. Room/decor growth can
; move any of these labels across an 8 KiB HuCard bank boundary, so direct TIA
; from a sprite label is intentionally forbidden for walk, climb and jump.
monty_upload_walk_frame:
 lda <monty_anim_frame
 and #3
 tax
 lda <monty_facing
 bmi .left
 lda monty_walk_r_lo,x
 sta <_bp
 lda monty_walk_r_hi,x
 sta <_bp+1
 ldy monty_walk_r_bank,x
 bra .upload
.left:
 lda monty_walk_l_lo,x
 sta <_bp
 lda monty_walk_l_hi,x
 sta <_bp+1
 ldy monty_walk_l_bank,x
.upload:
 call monty_upload_far_512
 stz <monty_sprite_dirty
 lda <monty_facing
 sta <monty_sprite_last_facing
 stz <monty_sprite_last_mode
 rts

monty_upload_climb_frame:
 lda <monty_anim_frame
 and #3
 tax
 lda monty_climb_lo,x
 sta <_bp
 lda monty_climb_hi,x
 sta <_bp+1
 ldy monty_climb_bank,x
 call monty_upload_far_512
 stz <monty_sprite_dirty
 lda #1
 sta <monty_sprite_last_mode
 rts

monty_upload_jump_frame:
 lda <monty_anim_frame
 cmp #12
 bcc .index_ok
 lda #11
.index_ok:
 tax
 lda <monty_facing
 bmi .left
 lda monty_sault_r_lo,x
 sta <_bp
 lda monty_sault_r_hi,x
 sta <_bp+1
 ldy monty_sault_r_bank,x
 bra .upload
.left:
 lda monty_sault_l_lo,x
 sta <_bp
 lda monty_sault_l_hi,x
 sta <_bp+1
 ldy monty_sault_l_bank,x
.upload:
 call monty_upload_far_512
 stz <monty_sprite_dirty
 lda <monty_facing
 sta <monty_sprite_last_facing
 lda #2
 sta <monty_sprite_last_mode
 rts

; Copy one 512-byte PCE sprite frame from arbitrary banked ROM to VRAM.
; map_bp_to_mpr34 maps the selected bank into MPR3 and the following bank into
; MPR4, so a frame may also straddle a bank boundary safely.
monty_upload_far_512:
 php
 sei
 tma3
 pha
 tma4
 pha
 call map_bp_to_mpr34

 lda #<MONTY_SPR_VRAM
 sta <_di
 lda #>MONTY_SPR_VRAM
 sta <_di+1
 call vdc_di_to_mawr

 ldx #2
 cly
.page:
 lda [_bp],y
 sta VDC_DL
 iny
 lda [_bp],y
 sta VDC_DH
 iny
 bne .page
 inc <_bp+1
 dex
 bne .page

 pla
 tam4
 pla
 tam3
 plp
 rts

; Compile-time far-pointer tables. Keeping them in code space means frame
; selection itself never depends on whichever ROM bank currently contains data.
monty_walk_l_lo:
 db <monty_walk_l_0,<monty_walk_l_1,<monty_walk_l_2,<monty_walk_l_3
monty_walk_l_hi:
 db >monty_walk_l_0,>monty_walk_l_1,>monty_walk_l_2,>monty_walk_l_3
monty_walk_l_bank:
 db BANK(monty_walk_l_0),BANK(monty_walk_l_1),BANK(monty_walk_l_2),BANK(monty_walk_l_3)
monty_walk_r_lo:
 db <monty_walk_r_0,<monty_walk_r_1,<monty_walk_r_2,<monty_walk_r_3
monty_walk_r_hi:
 db >monty_walk_r_0,>monty_walk_r_1,>monty_walk_r_2,>monty_walk_r_3
monty_walk_r_bank:
 db BANK(monty_walk_r_0),BANK(monty_walk_r_1),BANK(monty_walk_r_2),BANK(monty_walk_r_3)
monty_climb_lo:
 db <monty_climb_0,<monty_climb_1,<monty_climb_2,<monty_climb_3
monty_climb_hi:
 db >monty_climb_0,>monty_climb_1,>monty_climb_2,>monty_climb_3
monty_climb_bank:
 db BANK(monty_climb_0),BANK(monty_climb_1),BANK(monty_climb_2),BANK(monty_climb_3)

monty_sault_l_lo:
 db <monty_sault_l_0,<monty_sault_l_1,<monty_sault_l_2,<monty_sault_l_3
 db <monty_sault_l_4,<monty_sault_l_5,<monty_sault_l_6,<monty_sault_l_7
 db <monty_sault_l_8,<monty_sault_l_9,<monty_sault_l_10,<monty_sault_l_11
monty_sault_l_hi:
 db >monty_sault_l_0,>monty_sault_l_1,>monty_sault_l_2,>monty_sault_l_3
 db >monty_sault_l_4,>monty_sault_l_5,>monty_sault_l_6,>monty_sault_l_7
 db >monty_sault_l_8,>monty_sault_l_9,>monty_sault_l_10,>monty_sault_l_11
monty_sault_l_bank:
 db BANK(monty_sault_l_0),BANK(monty_sault_l_1),BANK(monty_sault_l_2),BANK(monty_sault_l_3)
 db BANK(monty_sault_l_4),BANK(monty_sault_l_5),BANK(monty_sault_l_6),BANK(monty_sault_l_7)
 db BANK(monty_sault_l_8),BANK(monty_sault_l_9),BANK(monty_sault_l_10),BANK(monty_sault_l_11)
monty_sault_r_lo:
 db <monty_sault_r_0,<monty_sault_r_1,<monty_sault_r_2,<monty_sault_r_3
 db <monty_sault_r_4,<monty_sault_r_5,<monty_sault_r_6,<monty_sault_r_7
 db <monty_sault_r_8,<monty_sault_r_9,<monty_sault_r_10,<monty_sault_r_11
monty_sault_r_hi:
 db >monty_sault_r_0,>monty_sault_r_1,>monty_sault_r_2,>monty_sault_r_3
 db >monty_sault_r_4,>monty_sault_r_5,>monty_sault_r_6,>monty_sault_r_7
 db >monty_sault_r_8,>monty_sault_r_9,>monty_sault_r_10,>monty_sault_r_11
monty_sault_r_bank:
 db BANK(monty_sault_r_0),BANK(monty_sault_r_1),BANK(monty_sault_r_2),BANK(monty_sault_r_3)
 db BANK(monty_sault_r_4),BANK(monty_sault_r_5),BANK(monty_sault_r_6),BANK(monty_sault_r_7)
 db BANK(monty_sault_r_8),BANK(monty_sault_r_9),BANK(monty_sault_r_10),BANK(monty_sault_r_11)

; Animation state follows C64 UpdateState more closely:
; - walk: four frames, timer 4, only advances while moving
; - climb: four frames, timer 4 while vertical movement is active
; - explicit jump: 12 somersault frames, timer 4, clamped at frame 11
monty_sprite_animate:
 lda <monty_jump_phase
 beq .not_jump
 lda <monty_sprite_last_mode
 cmp #2
 beq .jump_tick
 stz <monty_anim_frame
 lda #4
 sta <monty_anim_timer
 lda #1
 sta <monty_sprite_dirty
 bra .maybe_upload_jump
.jump_tick:
 dec <monty_anim_timer
 bne .maybe_upload_jump
 lda #4
 sta <monty_anim_timer
 lda <monty_anim_frame
 cmp #11
 bcs .maybe_upload_jump
 inc <monty_anim_frame
 lda #1
 sta <monty_sprite_dirty
.maybe_upload_jump:
 lda <monty_sprite_dirty
 beq .done
 call monty_upload_jump_frame
 bra .done

.not_jump:
 lda <monty_climbing
 beq .walk_mode
 lda <monty_sprite_last_mode
 cmp #1
 beq .animate_four
 stz <monty_anim_frame
 lda #4
 sta <monty_anim_timer
 lda #1
 sta <monty_sprite_dirty
 bra .maybe_upload_four
.walk_mode:
 lda <monty_sprite_last_mode
 beq .check_dir
 stz <monty_anim_frame
 lda #4
 sta <monty_anim_timer
 lda #1
 sta <monty_sprite_dirty
.check_dir:
 lda <monty_facing
 cmp <monty_sprite_last_facing
 beq .check_motion
 stz <monty_anim_frame
 lda #4
 sta <monty_anim_timer
 lda #1
 sta <monty_sprite_dirty
.check_motion:
 lda <monty_is_moving
 bne .animate_four
 bra .maybe_upload_four
.animate_four:
 dec <monty_anim_timer
 bne .maybe_upload_four
 lda #4
 sta <monty_anim_timer
 inc <monty_anim_frame
 lda <monty_anim_frame
 and #3
 sta <monty_anim_frame
 lda #1
 sta <monty_sprite_dirty
.maybe_upload_four:
 lda <monty_sprite_dirty
 beq .done
 lda <monty_climbing
 beq .upload_walk
 call monty_upload_climb_frame
 bra .done
.upload_walk:
 call monty_upload_walk_frame
.done:
 rts

; Coordinate bridge from the C64 internal Monty values to PCE SAT space.
; C64 visible X = 2*(monty_x-$0c), visible Y = (monty_y+1)-$32.
; PCE SAT origin is +32 X / +64 Y, therefore SAT X=2*x+8, SAT Y=y+15.
monty_sprite_update_satb:
 lda #<MONTY_SAT_LEFT
 sta <_di
 lda #>MONTY_SAT_LEFT
 sta <_di+1
 call vdc_di_to_mawr
 lda <monty_y
 clc
 adc #15
 sta VDC_DL
 stz VDC_DH
 lda <monty_x
 asl a
 ldx #0
 bcc .left_no_asl_carry
 inx
.left_no_asl_carry:
 clc
 adc #8
 bcc .left_no_add_carry
 inx
.left_no_add_carry:
 sta VDC_DL
 stx VDC_DH
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
 adc #15
 sta VDC_DL
 stz VDC_DH
 lda <monty_x
 asl a
 ldx #0
 bcc .right_no_asl_carry
 inx
.right_no_asl_carry:
 clc
 adc #24
 bcc .right_no_add_carry
 inx
.right_no_add_carry:
 sta VDC_DL
 stx VDC_DH
 lda #<((MONTY_SPR_VRAM+64)>>5)
 sta VDC_DL
 lda #>((MONTY_SPR_VRAM+64)>>5)
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
monty_sprite_palette:
 dw $000,$1ff,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000
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
monty_sault_l_0: incbin "monty-sault-l.dat",0,512
monty_sault_l_1: incbin "monty-sault-l.dat",512,512
monty_sault_l_2: incbin "monty-sault-l.dat",1024,512
monty_sault_l_3: incbin "monty-sault-l.dat",1536,512
monty_sault_l_4: incbin "monty-sault-l.dat",2048,512
monty_sault_l_5: incbin "monty-sault-l.dat",2560,512
monty_sault_l_6: incbin "monty-sault-l.dat",3072,512
monty_sault_l_7: incbin "monty-sault-l.dat",3584,512
monty_sault_l_8: incbin "monty-sault-l.dat",4096,512
monty_sault_l_9: incbin "monty-sault-l.dat",4608,512
monty_sault_l_10: incbin "monty-sault-l.dat",5120,512
monty_sault_l_11: incbin "monty-sault-l.dat",5632,512
monty_sault_r_0: incbin "monty-sault-r.dat",0,512
monty_sault_r_1: incbin "monty-sault-r.dat",512,512
monty_sault_r_2: incbin "monty-sault-r.dat",1024,512
monty_sault_r_3: incbin "monty-sault-r.dat",1536,512
monty_sault_r_4: incbin "monty-sault-r.dat",2048,512
monty_sault_r_5: incbin "monty-sault-r.dat",2560,512
monty_sault_r_6: incbin "monty-sault-r.dat",3072,512
monty_sault_r_7: incbin "monty-sault-r.dat",3584,512
monty_sault_r_8: incbin "monty-sault-r.dat",4096,512
monty_sault_r_9: incbin "monty-sault-r.dat",4608,512
monty_sault_r_10: incbin "monty-sault-r.dat",5120,512
monty_sault_r_11: incbin "monty-sault-r.dat",5632,512
