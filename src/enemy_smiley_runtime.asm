; Authentic C64 four-slot enemy engine for Rooms $00-$02.
; State mirrors original enemy_state_tbl: 4 slots x 8 bytes:
; +0 X half-coordinate, +1 VIC Y, +2 C64 colour, +3 type_id,
; +4 flags(bit0 axis, bit7 direction), +5 range, +6 step, +7 speed.
; enemy_xmsb_tbl is the original horizontal sub-step parity store and
; enemy_anim_timer_tbl is the original per-slot animation counter.
;
; --newproc thunks save/map MPR6 and JMP into each proc. Externally returning
; paths use LEAVE; internal JSR helpers use RTS within the already-mapped proc.
; Enemy graphics are banked data and are uploaded through saved MPR3/MPR4.

ENEMY_SLOT0_VRAM = $3800
ENEMY_SLOT1_VRAM = $4000
ENEMY_SLOT2_VRAM = $4800
ENEMY_SLOT3_VRAM = $5000
ENEMY_SAT_BASE   = SAT_ADDR+32        ; entries 8..15, two PCE halves per C64 slot

.bss
enemy_state_tbl:          ds 32
enemy_xmsb_tbl:           ds 4
enemy_anim_timer_tbl:     ds 4
enemy_palette_tbl:        ds 4        ; PCE SAT palette index 3..6
enemy_smiley_last_room:   ds 1        ; generic enemy room cache; old name retained
enemy_tmp_slot:           ds 1
enemy_tmp_state:          ds 1
enemy_tmp_record_y:       ds 1
enemy_tmp_color:          ds 1
enemy_tmp_speed:          ds 1
enemy_tmp_frame:          ds 1
enemy_tmp_pat_lo:         ds 1
enemy_tmp_pat_hi:         ds 1
enemy_tmp_xhi:            ds 1

        include "enemy_room00_collision.asm"

.code

; Load the four C64 colours needed by Rooms $00-$02, then seed current room.
.proc enemy_smiley_init
        lda     #$ff
        sta     enemy_smiley_last_room

        lda     #19
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<enemy_palette_cyan
        sta     <_bp
        lda     #>enemy_palette_cyan
        sta     <_bp+1
        ldy     #BANK(enemy_palette_cyan)
        call    load_palettes

        lda     #20
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<enemy_palette_purple
        sta     <_bp
        lda     #>enemy_palette_purple
        sta     <_bp+1
        ldy     #BANK(enemy_palette_purple)
        call    load_palettes

        lda     #21
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<enemy_palette_white
        sta     <_bp
        lda     #>enemy_palette_white
        sta     <_bp+1
        ldy     #BANK(enemy_palette_white)
        call    load_palettes

        lda     #22
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<enemy_palette_yellow
        sta     <_bp
        lda     #>enemy_palette_yellow
        sta     <_bp+1
        ldy     #BANK(enemy_palette_yellow)
        call    load_palettes
        call    xfer_palettes

        call    enemy_smiley_room_sync
        leave
.endp

; Rebuild the original 4-slot state from the exact 7-byte room spawn records.
; SetupRoom conversions are reproduced literally: X=(x_grid>>1)+$1c,
; Y=$f9-y_grid, flags from 00/82/02/81/01, reverse starts step=range.
.proc enemy_smiley_room_sync
        lda     <monty_room
        cmp     enemy_smiley_last_room
        bne     .changed
        leave

.changed:
        sta     enemy_smiley_last_room
        jsr     .clear_slots

        lda     <monty_room
        cmp     #$00
        bne     .not_room00
        lda     #<.room00_records
        sta     <_bp
        lda     #>.room00_records
        sta     <_bp+1
        jmp     .seed_selected
.not_room00:
        cmp     #$01
        bne     .not_room01
        lda     #<.room01_records
        sta     <_bp
        lda     #>.room01_records
        sta     <_bp+1
        jmp     .seed_selected
.not_room01:
        cmp     #$02
        bne     .no_supported_enemies
        lda     #<.room02_records
        sta     <_bp
        lda     #>.room02_records
        sta     <_bp+1

.seed_selected:
        jsr     .decode_records
        jsr     .upload_slots
.no_supported_enemies:
        leave

.clear_slots:
        ldx     #31
        lda     #$ff
.clear_state:
        sta     enemy_state_tbl,x
        dex
        bpl     .clear_state

        ldx     #3
        cla
.clear_aux:
        sta     enemy_xmsb_tbl,x
        sta     enemy_anim_timer_tbl,x
        sta     enemy_palette_tbl,x
        dex
        bpl     .clear_aux
        rts

.decode_records:
        stz     enemy_tmp_slot
        stz     enemy_tmp_state
        cly

.decode_next:
        lda     [_bp],y
        cmp     #$ff
        bne     .decode_record
        jmp     .decode_done
.decode_record:
        sty     enemy_tmp_record_y
        tax
        lda     .colour_tbl,x
        sta     enemy_tmp_color
        ldx     enemy_tmp_state
        sta     enemy_state_tbl+2,x

        ; PCE palette mapping for the exact C64 colours used in rooms 00..02.
        ldy     enemy_tmp_slot
        lda     enemy_tmp_color
        cmp     #$03
        bne     .pal_not_cyan
        lda     #3
        bra     .pal_store
.pal_not_cyan:
        cmp     #$04
        bne     .pal_not_purple
        lda     #4
        bra     .pal_store
.pal_not_purple:
        cmp     #$01
        bne     .pal_yellow
        lda     #5
        bra     .pal_store
.pal_yellow:
        lda     #6
.pal_store:
        sta     enemy_palette_tbl,y

        ; Source +1: X grid.
        ldy     enemy_tmp_record_y
        iny
        lda     [_bp],y
        lsr     a
        clc
        adc     #$1c
        ldx     enemy_tmp_state
        sta     enemy_state_tbl,x

        ; Source +2: Y grid.
        iny
        lda     [_bp],y
        sta     enemy_tmp_color
        lda     #$f9
        sec
        sbc     enemy_tmp_color
        sta     enemy_state_tbl+1,x

        ; Source +3: dir_idx -> flags.
        iny
        lda     [_bp],y
        sty     enemy_tmp_record_y
        tay
        lda     .dir_flags,y
        ldx     enemy_tmp_state
        sta     enemy_state_tbl+4,x

        ; Source +4 type_id, +5 speed, +6 range.
        ldy     enemy_tmp_record_y
        iny
        lda     [_bp],y
        sta     enemy_state_tbl+3,x
        iny
        lda     [_bp],y
        sta     enemy_state_tbl+7,x
        iny
        lda     [_bp],y
        sta     enemy_state_tbl+5,x

        lda     enemy_state_tbl+4,x
        bmi     .reverse_start
        stz     enemy_state_tbl+6,x
        bra     .decoded_slot
.reverse_start:
        lda     enemy_state_tbl+5,x
        sta     enemy_state_tbl+6,x

.decoded_slot:
        iny
        inc     enemy_tmp_slot
        lda     enemy_tmp_state
        clc
        adc     #8
        sta     enemy_tmp_state
        lda     enemy_tmp_slot
        cmp     #4
        beq     .decode_done
        jmp     .decode_next
.decode_done:
        rts

; Upload one full 8-frame (4096-byte) PCE payload per active C64 enemy slot.
.upload_slots:
        php
        sei
        tma3
        pha
        tma4
        pha

        stz     enemy_tmp_slot
        stz     enemy_tmp_state
.upload_next:
        ldx     enemy_tmp_state
        lda     enemy_state_tbl,x
        cmp     #$ff
        beq     .upload_advance
        jsr     .select_asset
        call    map_bp_to_mpr34

        stz     <_di
        lda     enemy_tmp_slot
        asl     a
        asl     a
        asl     a
        clc
        adc     #$38
        sta     <_di+1
        call    vdc_di_to_mawr

        ldx     #16
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

.upload_advance:
        inc     enemy_tmp_slot
        lda     enemy_tmp_state
        clc
        adc     #8
        sta     enemy_tmp_state
        lda     enemy_tmp_slot
        cmp     #4
        beq     .upload_done
        jmp     .upload_next

.upload_done:
        pla
        tam4
        pla
        tam3
        plp
        rts

.select_asset:
        ldx     enemy_tmp_state
        lda     enemy_state_tbl+3,x
        cmp     #$09
        bne     .asset_not09
        lda     #<enemy_type09_patterns
        sta     <_bp
        lda     #>enemy_type09_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type09_patterns)
        rts
.asset_not09:
        cmp     #$0e
        bne     .asset_not0e
        lda     #<enemy_type0e_patterns
        sta     <_bp
        lda     #>enemy_type0e_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type0e_patterns)
        rts
.asset_not0e:
        cmp     #$0f
        bne     .asset_not0f
        lda     #<enemy_type0f_patterns
        sta     <_bp
        lda     #>enemy_type0f_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type0f_patterns)
        rts
.asset_not0f:
        cmp     #$14
        bne     .asset_not14
        lda     #<enemy_type14_patterns
        sta     <_bp
        lda     #>enemy_type14_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type14_patterns)
        rts
.asset_not14:
        cmp     #$18
        bne     .asset_type19
        lda     #<enemy_type18_patterns
        sta     <_bp
        lda     #>enemy_type18_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type18_patterns)
        rts
.asset_type19:
        lda     #<enemy_type19_patterns
        sta     <_bp
        lda     #>enemy_type19_patterns
        sta     <_bp+1
        ldy     #BANK(enemy_type19_patterns)
        rts

.dir_flags:
        db $00,$82,$02,$81,$01
.colour_tbl:
        db $00,$06,$02,$04,$05,$03,$07,$01,$08,$09,$0a,$0b,$0c,$0d,$0e,$0f

.room00_records:
        db $05,$b8,$8f,$04,$19,$02,$25
        db $03,$78,$37,$03,$09,$03,$13
        db $ff
.room01_records:
        db $06,$28,$27,$02,$0f,$02,$2c
        db $07,$28,$77,$04,$09,$04,$11
        db $05,$58,$57,$02,$18,$01,$2d
        db $ff
.room02_records:
        db $05,$b0,$a7,$04,$0e,$03,$27
        db $07,$68,$27,$03,$14,$02,$3c
        db $06,$a8,$57,$02,$09,$01,$1f
        db $05,$28,$67,$03,$19,$04,$0e
        db $ff
.endp

; C64 Enemies.Tick: collision was latched before this call; movement/animation
; runs only on odd frame_toggle. Slots are processed 3 -> 0.
.proc enemy_smiley_update
        call    enemy_room00_collision_update

        lda     <game_tick_counter
        and     #$01
        bne     .tick
        leave

.tick:
        ldy     #3
.slot_loop:
        sty     enemy_tmp_slot
        tya
        asl     a
        asl     a
        asl     a
        tax
        stx     enemy_tmp_state
        lda     enemy_state_tbl,x
        cmp     #$ff
        beq     .slot_done
        jsr     .process_slot
.slot_done:
        ldy     enemy_tmp_slot
        dey
        bpl     .slot_loop
        leave

.process_slot:
        lda     enemy_state_tbl+7,x
        sta     enemy_tmp_speed
        lda     enemy_state_tbl+4,x
        and     #$01
        beq     .horizontal
        jsr     .move_vertical
        bra     .animate
.horizontal:
        jsr     .move_horizontal
.animate:
        ldy     enemy_tmp_slot
        lda     enemy_anim_timer_tbl,y
        ina
        sta     enemy_anim_timer_tbl,y
        rts

.move_vertical:
        lda     enemy_state_tbl+4,x
        bmi     .vertical_up

        inc     enemy_state_tbl+6,x
        lda     enemy_state_tbl+6,x
        cmp     enemy_state_tbl+5,x
        bne     .vertical_down_move
        lda     enemy_state_tbl+4,x
        eor     #$80
        sta     enemy_state_tbl+4,x
        rts
.vertical_down_move:
        lda     enemy_state_tbl+1,x
        clc
        adc     enemy_tmp_speed
        sta     enemy_state_tbl+1,x
        rts

.vertical_up:
        dec     enemy_state_tbl+6,x
        bne     .vertical_up_move
        lda     enemy_state_tbl+4,x
        eor     #$80
        sta     enemy_state_tbl+4,x
        rts
.vertical_up_move:
        lda     enemy_state_tbl+1,x
        sec
        sbc     enemy_tmp_speed
        sta     enemy_state_tbl+1,x
        rts

.move_horizontal:
        lda     enemy_state_tbl+4,x
        bmi     .horizontal_left

        inc     enemy_state_tbl+6,x
        lda     enemy_state_tbl+6,x
        cmp     enemy_state_tbl+5,x
        bne     .horizontal_right_steps
        lda     enemy_state_tbl+4,x
        eor     #$80
        sta     enemy_state_tbl+4,x
        rts

.horizontal_right_steps:
        lda     enemy_tmp_speed
        sta     enemy_tmp_color
.hr_step:
        dec     enemy_tmp_color
        bmi     .horizontal_done
        ldy     enemy_tmp_slot
        lda     enemy_xmsb_tbl,y
        clc
        adc     #1
        and     #1
        sta     enemy_xmsb_tbl,y
        bne     .hr_step
        inc     enemy_state_tbl,x
        bra     .hr_step

.horizontal_left:
        dec     enemy_state_tbl+6,x
        bne     .horizontal_left_steps
        lda     enemy_state_tbl+4,x
        eor     #$80
        sta     enemy_state_tbl+4,x
        rts

.horizontal_left_steps:
        lda     enemy_tmp_speed
        sta     enemy_tmp_color
.hl_step:
        dec     enemy_tmp_color
        bmi     .horizontal_done
        ldy     enemy_tmp_slot
        lda     enemy_xmsb_tbl,y
        clc
        adc     #1
        and     #1
        sta     enemy_xmsb_tbl,y
        beq     .hl_step
        dec     enemy_state_tbl,x
        bra     .hl_step
.horizontal_done:
        rts
.endp

; Render all four C64 enemy slots into PCE SAT entries 8..15.
; C64 frame = ((anim_timer & 6)>>1) + (direction forward ? 4 : 0).
; SAT X = 2*internal_X + 8; SAT Y = VIC_Y + 14.
.proc enemy_smiley_update_satb
        lda     #<ENEMY_SAT_BASE
        sta     <_di
        lda     #>ENEMY_SAT_BASE
        sta     <_di+1
        call    vdc_di_to_mawr

        stz     enemy_tmp_slot
        stz     enemy_tmp_state
.render_slot:
        ldx     enemy_tmp_state
        lda     enemy_state_tbl,x
        cmp     #$ff
        bne     .show_slot
        jsr     .hide_pair
        jmp     .render_advance

.show_slot:
        lda     enemy_state_tbl+4,x
        and     #$80
        bne     .reverse_group
        lda     #4
        bra     .group_ready
.reverse_group:
        cla
.group_ready:
        sta     enemy_tmp_frame
        ldy     enemy_tmp_slot
        lda     enemy_anim_timer_tbl,y
        and     #$06
        lsr     a
        clc
        adc     enemy_tmp_frame
        sta     enemy_tmp_frame

        ; base pattern number = ($3800 >> 5) + slot*$40 + frame*8.
        lda     enemy_tmp_slot
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        clc
        adc     #$c0
        sta     enemy_tmp_pat_lo
        lda     #$01
        adc     #0
        sta     enemy_tmp_pat_hi
        lda     enemy_tmp_frame
        asl     a
        asl     a
        asl     a
        clc
        adc     enemy_tmp_pat_lo
        sta     enemy_tmp_pat_lo
        bcc     .pattern_ready
        inc     enemy_tmp_pat_hi
.pattern_ready:

        ; Left 16x32 half.
        ldx     enemy_tmp_state
        lda     enemy_state_tbl+1,x
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH

        lda     enemy_state_tbl,x
        stz     enemy_tmp_xhi
        asl     a
        bcc     .left_mul_ok
        inc     enemy_tmp_xhi
.left_mul_ok:
        clc
        adc     #8
        bcc     .left_add_ok
        inc     enemy_tmp_xhi
.left_add_ok:
        sta     VDC_DL
        lda     enemy_tmp_xhi
        sta     VDC_DH

        lda     enemy_tmp_pat_lo
        sta     VDC_DL
        lda     enemy_tmp_pat_hi
        sta     VDC_DH

        ldy     enemy_tmp_slot
        lda     enemy_palette_tbl,y
        ora     #$80
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH

        ; Right 16x32 half.
        ldx     enemy_tmp_state
        lda     enemy_state_tbl+1,x
        clc
        adc     #14
        sta     VDC_DL
        stz     VDC_DH

        lda     enemy_state_tbl,x
        stz     enemy_tmp_xhi
        asl     a
        bcc     .right_mul_ok
        inc     enemy_tmp_xhi
.right_mul_ok:
        clc
        adc     #24
        bcc     .right_add_ok
        inc     enemy_tmp_xhi
.right_add_ok:
        sta     VDC_DL
        lda     enemy_tmp_xhi
        sta     VDC_DH

        lda     enemy_tmp_pat_lo
        clc
        adc     #2
        sta     VDC_DL
        lda     enemy_tmp_pat_hi
        adc     #0
        sta     VDC_DH

        ldy     enemy_tmp_slot
        lda     enemy_palette_tbl,y
        ora     #$80
        sta     VDC_DL
        lda     #$10
        sta     VDC_DH
        jmp     .render_advance

.hide_pair:
        ldy     #2
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
        dey
        bne     .hide_one
        rts

.render_advance:
        inc     enemy_tmp_slot
        lda     enemy_tmp_state
        clc
        adc     #8
        sta     enemy_tmp_state
        lda     enemy_tmp_slot
        cmp     #4
        beq     .render_done
        jmp     .render_slot
.render_done:
        leave
.endp
