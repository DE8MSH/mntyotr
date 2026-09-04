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
.r0: tia monty_walk_r_0,VDC_DL,512
 bra .uploaded
.r1: tia monty_walk_r_1,VDC_DL,512
 bra .uploaded
.r2: tia monty_walk_r_2,VDC_DL,512
.uploaded:
 stz <monty_sprite_dirty
 lda <monty_facing
 sta <monty_sprite_last_facing
 stz <monty_sprite_last_mode
 rts
.left:
 cpx #0
 beq .l0
 cpx #1
 beq .l1
 cpx #2
 beq .l2
 tia monty_walk_l_3,VDC_DL,512
 bra .uploaded
.l0: tia monty_walk_l_0,VDC_DL,512
 bra .uploaded
.l1: tia monty_walk_l_1,VDC_DL,512
 bra .uploaded
.l2: tia monty_walk_l_2,VDC_DL,512
 bra .uploaded

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
.c0: tia monty_climb_0,VDC_DL,512
 bra .cdone
.c1: tia monty_climb_1,VDC_DL,512
 bra .cdone
.c2: tia monty_climb_2,VDC_DL,512
.cdone:
 stz <monty_sprite_dirty
 lda #1
 sta <monty_sprite_last_mode
 rts

; C64 JumpRight/JumpLeft use movement_ticker 0..11 and clamp at frame 11.
; The generated .dat files contain the exact 12 raw VIC slots converted to PCE.
; HuC6280 relative branches are limited to +/-128 bytes, so the two 12-way
; dispatch tables deliberately use absolute JMP for long exits/side selection.
monty_upload_jump_frame:
 lda #<MONTY_SPR_VRAM
 sta <_di
 lda #>MONTY_SPR_VRAM
 sta <_di+1
 call vdc_di_to_mawr
 lda <monty_anim_frame
 cmp #12
 bcc .index_ok
 lda #11
.index_ok:
 tax
 lda <monty_facing
 bpl .jump_right
 jmp .jump_left
.jump_right:
 cpx #0
 beq .jr0
 cpx #1
 beq .jr1
 cpx #2
 beq .jr2
 cpx #3
 beq .jr3
 cpx #4
 beq .jr4
 cpx #5
 beq .jr5
 cpx #6
 beq .jr6
 cpx #7
 beq .jr7
 cpx #8
 beq .jr8
 cpx #9
 beq .jr9
 cpx #10
 beq .jr10
 tia monty_sault_r_11,VDC_DL,512
 jmp .jdone
.jr0: tia monty_sault_r_0,VDC_DL,512
 jmp .jdone
.jr1: tia monty_sault_r_1,VDC_DL,512
 jmp .jdone
.jr2: tia monty_sault_r_2,VDC_DL,512
 jmp .jdone
.jr3: tia monty_sault_r_3,VDC_DL,512
 jmp .jdone
.jr4: tia monty_sault_r_4,VDC_DL,512
 jmp .jdone
.jr5: tia monty_sault_r_5,VDC_DL,512
 jmp .jdone
.jr6: tia monty_sault_r_6,VDC_DL,512
 jmp .jdone
.jr7: tia monty_sault_r_7,VDC_DL,512
 jmp .jdone
.jr8: tia monty_sault_r_8,VDC_DL,512
 jmp .jdone
.jr9: tia monty_sault_r_9,VDC_DL,512
 jmp .jdone
.jr10: tia monty_sault_r_10,VDC_DL,512
 jmp .jdone
.jump_left:
 cpx #0
 beq .jl0
 cpx #1
 beq .jl1
 cpx #2
 beq .jl2
 cpx #3
 beq .jl3
 cpx #4
 beq .jl4
 cpx #5
 beq .jl5
 cpx #6
 beq .jl6
 cpx #7
 beq .jl7
 cpx #8
 beq .jl8
 cpx #9
 beq .jl9
 cpx #10
 beq .jl10
 tia monty_sault_l_11,VDC_DL,512
 jmp .jdone
.jl0: tia monty_sault_l_0,VDC_DL,512
 jmp .jdone
.jl1: tia monty_sault_l_1,VDC_DL,512
 jmp .jdone
.jl2: tia monty_sault_l_2,VDC_DL,512
 jmp .jdone
.jl3: tia monty_sault_l_3,VDC_DL,512
 jmp .jdone
.jl4: tia monty_sault_l_4,VDC_DL,512
 jmp .jdone
.jl5: tia monty_sault_l_5,VDC_DL,512
 jmp .jdone
.jl6: tia monty_sault_l_6,VDC_DL,512
 jmp .jdone
.jl7: tia monty_sault_l_7,VDC_DL,512
 jmp .jdone
.jl8: tia monty_sault_l_8,VDC_DL,512
 jmp .jdone
.jl9: tia monty_sault_l_9,VDC_DL,512
 jmp .jdone
.jl10: tia monty_sault_l_10,VDC_DL,512
.jdone:
 stz <monty_sprite_dirty
 lda <monty_facing
 sta <monty_sprite_last_facing
 lda #2
 sta <monty_sprite_last_mode
 rts

; Animation state follows C64 UpdateState more closely:
; - walk: four frames, timer 4, only advances while moving
; - climb: four frames, timer 4 while vertical movement is active
; - explicit jump: 12 somersault frames, timer 4, clamped at frame 11
; Unsupported falling is not a jump action and therefore keeps walk-state art.
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
