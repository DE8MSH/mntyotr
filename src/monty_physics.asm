; Monty movement/physics ported from the annotated C64 reconstruction.
; Gameplay coordinates remain in C64 pixel units and PAL-rate logical ticks.

.zp
monty_x:                ds 1
monty_y:                ds 1
monty_jump_phase:       ds 1           ; 0=ground, 1=ascent, 2=descent
monty_jump_index:       ds 1
monty_facing:           ds 1           ; 0=right, $80=left
monty_step_phase:       ds 1
monty_saved_left:       ds 1
monty_saved_right:      ds 1
collision_x:            ds 1
collision_y:            ds 1
collision_count:        ds 1
collision_ptr:          ds 2
jump_delta:             ds 1

.code

monty_physics_init:
        lda     #$40
        sta     <monty_x
        lda     #$b0
        sta     <monty_y
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_facing
        stz     <monty_step_phase
        stz     <monty_saved_left
        stz     <monty_saved_right
        rts

; A = logical room tile id 0..7. Return the room-$00 C64 collision property.
room00_get_tile_property:
        cmp     #8
        bcs     .empty
        tax
        lda     room00_tile_properties,x
        rts
.empty:
        cla
        rts

; X=column 0..31, Y=row 0..19. Returns logical tile id, or zero outside.
; The 640-byte room cannot be indexed with an 8-bit X register, so use the
; original-style pointer approach with a row*32 table.
room00_get_tile_xy:
        cpx     #32
        bcs     .outside
        cpy     #20
        bcs     .outside
        stx     <collision_x
        tya
        tax
        lda     #<room00_collision_map
        clc
        adc     room00_row_offset_lo,x
        sta     <collision_ptr
        lda     #>room00_collision_map
        adc     room00_row_offset_hi,x
        sta     <collision_ptr+1
        ldy     <collision_x
        lda     [collision_ptr],y
        rts
.outside:
        cla
        rts

room00_get_property_xy:
        bsr     room00_get_tile_xy
        jmp     room00_get_tile_property

; C64 horizontal probes: only test when (x-$0c) is 4-pixel aligned.
monty_check_tile_right:
        lda     <monty_x
        sec
        sbc     #$0c
        and     #$03
        bne     .clear
        lda     <monty_y
        sec
        sbc     #$32
        pha
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     <monty_x
        sec
        sbc     #$0c
        lsr     a
        lsr     a
        clc
        adc     #$02
        tax
        pla
        and     #$07
        bne     .three
        lda     #2
        bra     .count
.three:
        lda     #3
.count:
        sta     <collision_count
.loop:
        phx
        phy
        bsr     room00_get_property_xy
        ply
        plx
        cmp     #$01
        beq     .solid
        iny
        dec     <collision_count
        bne     .loop
.clear:
        clc
        rts
.solid:
        sec
        rts

monty_check_tile_left:
        lda     <monty_x
        sec
        sbc     #$0c
        and     #$03
        bne     .clear
        lda     <monty_y
        sec
        sbc     #$32
        pha
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     <monty_x
        sec
        sbc     #$0c
        lsr     a
        lsr     a
        sec
        sbc     #$01
        tax
        pla
        and     #$07
        bne     .three
        lda     #2
        bra     .count
.three:
        lda     #3
.count:
        sta     <collision_count
.loop:
        phx
        phy
        bsr     room00_get_property_xy
        ply
        plx
        cmp     #$01
        beq     .solid
        iny
        dec     <collision_count
        bne     .loop
.clear:
        clc
        rts
.solid:
        sec
        rts

monty_check_tile_above:
        lda     <monty_y
        sec
        sbc     #$32
        and     #$07
        bne     .clear
        lda     <monty_y
        sec
        sbc     #$32
        lsr     a
        lsr     a
        lsr     a
        sec
        sbc     #$01
        tay
        lda     <monty_x
        sec
        sbc     #$0c
        pha
        lsr     a
        lsr     a
        tax
        pla
        and     #$03
        beq     .two
        lda     #3
        bra     .count
.two:
        lda     #2
.count:
        sta     <collision_count
.loop:
        phx
        phy
        bsr     room00_get_property_xy
        ply
        plx
        cmp     #$01
        beq     .solid
        inx
        dec     <collision_count
        bne     .loop
.clear:
        clc
        rts
.solid:
        sec
        rts

monty_check_tile_below:
        lda     <monty_y
        sec
        sbc     #$32
        and     #$07
        bne     .clear
        lda     <monty_y
        sec
        sbc     #$32
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #$02
        tay
        lda     <monty_x
        sec
        sbc     #$0c
        pha
        lsr     a
        lsr     a
        tax
        pla
        and     #$03
        beq     .two
        lda     #3
        bra     .count
.two:
        lda     #2
.count:
        sta     <collision_count
.loop:
        phx
        phy
        bsr     room00_get_property_xy
        ply
        plx
        cmp     #$01
        beq     .solid
        cmp     #$02
        beq     .solid
        cmp     #$03
        beq     .solid
        inx
        dec     <collision_count
        bne     .loop
.clear:
        clc
        rts
.solid:
        sec
        rts

; C64 ToggleStepGate: increment a byte and return bit 0. Left moves on 1,
; right moves on 0, matching the two original call sites.
monty_toggle_step_gate:
        inc     <monty_step_phase
        lda     <monty_step_phase
        and     #$01
        rts

; Start jump and freeze horizontal direction for the arc, like jump_saved_*.
monty_jump_start:
        lda     <monty_jump_phase
        bne     .done
        lda     #1
        sta     <monty_jump_phase
        stz     <monty_jump_index
        lda     joynow
        and     #$80                    ; LEFT
        sta     <monty_saved_left
        lda     joynow
        and     #$20                    ; RIGHT
        sta     <monty_saved_right
.done:
        rts

; PCE pad -> C64 Monty movement semantics. joynow is refreshed by bare-startup
; every VBlank. PCE bits: I=$01, UP=$10, RIGHT=$20, DOWN=$40, LEFT=$80.
monty_update_input:
        lda     joynow
        and     #$01                    ; button I = C64 fire
        beq     .horizontal
        lda     <monty_jump_phase
        bne     .horizontal
        bsr     monty_jump_start
.horizontal:
        lda     <monty_jump_phase
        beq     .live_pad
        lda     <monty_saved_left
        bne     .left
        lda     <monty_saved_right
        bne     .right
        rts
.live_pad:
        lda     joynow
        and     #$80
        bne     .left
        lda     joynow
        and     #$20
        bne     .right
        rts
.left:
        bsr     monty_check_tile_left
        bcs     .done
        lda     #$80
        sta     <monty_facing
        bsr     monty_toggle_step_gate
        beq     .done
        dec     <monty_x
.done:
        rts
.right:
        bsr     monty_check_tile_right
        bcs     .done_right
        stz     <monty_facing
        bsr     monty_toggle_step_gate
        bne     .done_right
        inc     <monty_x
.done_right:
        rts

; Advance one exact C64 vertical jump-arc sample, clipping against room tiles.
monty_jump_step:
        lda     <monty_jump_phase
        beq     .done
        cmp     #1
        bne     .descent
        bsr     monty_check_tile_above
        bcs     .switch_down
        ldx     <monty_jump_index
        lda     monty_jump_arc_up,x
        cmp     #$ff
        beq     .switch_down
        sta     <jump_delta
        lda     <monty_y
        sec
        sbc     <jump_delta
        sta     <monty_y
        inc     <monty_jump_index
        rts
.switch_down:
        lda     #2
        sta     <monty_jump_phase
        stz     <monty_jump_index
        rts
.descent:
        bsr     monty_check_tile_below
        bcs     .land
        ldx     <monty_jump_index
        lda     monty_jump_arc_down,x
        cmp     #$ff
        beq     .land
        clc
        adc     <monty_y
        sta     <monty_y
        inc     <monty_jump_index
        rts
.land:
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_saved_left
        stz     <monty_saved_right
.done:
        rts

.data
room00_tile_properties:
        db $01,$01,$01,$02,$01,$01,$01,$01

room00_row_offset_lo:
        db $00,$20,$40,$60,$80,$a0,$c0,$e0,$00,$20,$40,$60,$80,$a0,$c0,$e0,$00,$20,$40,$60
room00_row_offset_hi:
        db $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02

monty_jump_arc_up:
        db $00,$03,$02,$02,$01,$02,$01,$01,$00,$01,$01,$01
        db $00,$01,$01,$01,$00,$01,$00,$01,$00,$00,$ff
monty_jump_arc_down:
        db $01,$00,$00,$00,$01,$00,$01,$00,$01,$00,$02,$01
        db $02,$01,$02,$02,$00,$ff
