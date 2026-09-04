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
monty_room:             ds 1
monty_room_exit:        ds 1           ; 0=none, 1=left, 2=right, 3=up, 4=down
monty_tile_state:       ds 1
monty_is_moving:        ds 1
monty_climbing:         ds 1
monty_falling:          ds 1           ; C64 monty_jumping_flag2 proxy: unsupported fall
collision_x:            ds 1
collision_y:            ds 1
collision_count:        ds 1
collision_ptr:          ds 2
jump_delta:             ds 1

.code

monty_physics_init:
        lda     #$86
        sta     <monty_x
        lda     #$b0
        sta     <monty_y
        stz     <monty_jump_phase
        stz     <monty_jump_index
        lda     #$80
        sta     <monty_facing
        stz     <monty_step_phase
        stz     <monty_saved_left
        stz     <monty_saved_right
        stz     <monty_room
        stz     <monty_room_exit
        stz     <monty_tile_state
        stz     <monty_is_moving
        stz     <monty_climbing
        stz     <monty_falling
        rts

room00_get_tile_property:
        beq     .empty
        cmp     #9
        bcs     .empty
        dec     a
        tax
        lda     room00_tile_properties,x
        rts
.empty:
        cla
        rts

room00_get_tile_xy:
        cpy     #3
        bcc     .outside
        cpy     #23
        bcs     .outside
        tya
        sec
        sbc     #3
        tay
        cpx     #2
        bcc     .outside
        cpx     #38
        bcs     .outside
        cpx     #4
        bcs     .check_right
        ldx     #4
        bra     .to_room_col
.check_right:
        cpx     #36
        bcc     .to_room_col
        ldx     #35
.to_room_col:
        txa
        sec
        sbc     #4
        tax
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
        call    room00_get_tile_xy
        jmp     room00_get_tile_property

monty_update_tile_state:
        stz     <monty_tile_state
        lda     <monty_y
        sec
        sbc     #$32
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     <monty_x
        sec
        sbc     #$0c
        lsr     a
        lsr     a
        tax
        lda     #3
        sta     <collision_count
.row:
        phx
        phy
        call    room00_get_property_xy
        ply
        plx
        cmp     #3
        beq     .surface
        inx
        phx
        phy
        call    room00_get_property_xy
        ply
        plx
        cmp     #3
        beq     .surface
        dex
        iny
        dec     <collision_count
        bne     .row
        rts
.surface:
        lda     #1
        sta     <monty_tile_state
        rts

monty_check_tile_right:
        lda <monty_x
        sec
        sbc #$0c
        and #$03
        bne .clear
        lda <monty_y
        sec
        sbc #$32
        pha
        lsr a
        lsr a
        lsr a
        tay
        lda <monty_x
        sec
        sbc #$0c
        lsr a
        lsr a
        clc
        adc #$02
        tax
        pla
        and #$07
        bne .three
        lda #2
        bra .count
.three: lda #3
.count: sta <collision_count
.loop:
        phx
        phy
        call room00_get_property_xy
        ply
        plx
        cmp #$01
        beq .solid
        iny
        dec <collision_count
        bne .loop
.clear: clc
        rts
.solid: sec
        rts

monty_check_tile_left:
        lda <monty_x
        sec
        sbc #$0c
        and #$03
        bne .clear
        lda <monty_y
        sec
        sbc #$32
        pha
        lsr a
        lsr a
        lsr a
        tay
        lda <monty_x
        sec
        sbc #$0c
        lsr a
        lsr a
        sec
        sbc #$01
        tax
        pla
        and #$07
        bne .three
        lda #2
        bra .count
.three: lda #3
.count: sta <collision_count
.loop:
        phx
        phy
        call room00_get_property_xy
        ply
        plx
        cmp #$01
        beq .solid
        iny
        dec <collision_count
        bne .loop
.clear: clc
        rts
.solid: sec
        rts

monty_check_tile_above:
        lda <monty_y
        sec
        sbc #$32
        and #$07
        bne .clear
        lda <monty_y
        sec
        sbc #$32
        lsr a
        lsr a
        lsr a
        sec
        sbc #$01
        tay
        lda <monty_x
        sec
        sbc #$0c
        pha
        lsr a
        lsr a
        tax
        pla
        and #$03
        beq .two
        lda #3
        bra .count
.two: lda #2
.count: sta <collision_count
.loop:
        phx
        phy
        call room00_get_property_xy
        ply
        plx
        cmp #$01
        beq .solid
        inx
        dec <collision_count
        bne .loop
.clear: clc
        rts
.solid: sec
        rts

monty_check_tile_below:
        lda <monty_y
        sec
        sbc #$32
        and #$07
        bne .clear
        lda <monty_y
        sec
        sbc #$32
        lsr a
        lsr a
        lsr a
        clc
        adc #$02
        tay
        lda <monty_x
        sec
        sbc #$0c
        pha
        lsr a
        lsr a
        tax
        pla
        and #$03
        beq .two
        lda #3
        bra .count
.two: lda #2
.count: sta <collision_count
.loop:
        phx
        phy
        call room00_get_property_xy
        ply
        plx
        cmp #$01
        beq .solid
        cmp #$02
        beq .solid
        cmp #$03
        beq .solid
        inx
        dec <collision_count
        bne .loop
.clear: clc
        rts
.solid: sec
        rts

monty_toggle_step_gate:
        inc <monty_step_phase
        lda <monty_step_phase
        and #$01
        rts

monty_jump_start:
        lda <monty_jump_phase
        bne .done
        lda <monty_falling
        bne .done
        lda #1
        sta <monty_jump_phase
        stz <monty_jump_index
        lda joynow
        and #$80
        sta <monty_saved_left
        lda joynow
        and #$20
        sta <monty_saved_right
.done:  rts

monty_check_room_edges:
        stz <monty_room_exit
        lda <monty_x
        cmp #$15
        bcc .left_exit
        cmp #$9c
        bcs .right_exit
        lda <monty_y
        cmp #$4c
        bcc .up_exit
        rts
.left_exit:
        lda #1
        sta <monty_room_exit
        lda #$9b
        sta <monty_x
        rts
.right_exit:
        lda #2
        sta <monty_room_exit
        lda #$15
        sta <monty_x
        rts
.up_exit:
        lda #3
        sta <monty_room_exit
        lda #$da
        sta <monty_y
        rts

; PCE bits after HuC joypad transform: I=$01 UP=$10 RIGHT=$20 DOWN=$40 LEFT=$80.
; The order mirrors C64 UpdateMovement: refresh tile state, start an unsupported
; fall before processing live controls, then set monty_is_moving as soon as a
; directional move is accepted (before ToggleStepGate changes the coordinate).
monty_update_input:
        stz <monty_is_moving
        stz <monty_climbing
        call monty_update_tile_state

        ; C64 $14D1-$14EF: if not on a property-3 surface, not in a jump action,
        ; and there is no tile below, enter the separate falling state.
        lda <monty_tile_state
        bne .not_falling
        lda <monty_jump_phase
        bne .not_falling
        lda <monty_falling
        bne .fall_step
        call monty_check_tile_below
        bcs .not_falling
        lda #1
        sta <monty_falling
.fall_step:
        call monty_check_tile_below
        bcs .land_from_fall
        inc <monty_y
        lda #1
        sta <monty_is_moving
        call monty_check_room_edges
        rts
.land_from_fall:
        stz <monty_falling
.not_falling:

        lda joynow
        and #$01
        beq .directions
        lda <monty_jump_phase
        bne .directions
        lda <monty_falling
        bne .directions
        call monty_jump_start
.directions:
        lda <monty_jump_phase
        bne .horizontal
        lda <monty_tile_state
        beq .horizontal
        lda joynow
        and #$10
        bne .up
        lda joynow
        and #$40
        bne .down
.horizontal:
        lda <monty_jump_phase
        beq .live_pad
        lda <monty_saved_left
        bne .left
        lda <monty_saved_right
        bne .right
        rts
.live_pad:
        lda joynow
        and #$80
        bne .left
        lda joynow
        and #$20
        bne .right
        rts
.up:
        call monty_check_tile_above
        bcs .done_vertical
        dec <monty_y
        lda #1
        sta <monty_is_moving
        sta <monty_climbing
        call monty_check_room_edges
.done_vertical:
        rts
.down:
        call monty_check_tile_below
        bcs .done_down
        inc <monty_y
        lda #1
        sta <monty_is_moving
        sta <monty_climbing
.done_down:
        rts
.left:
        call monty_check_tile_left
        bcs .done
        lda #$80
        sta <monty_facing
        lda #1
        sta <monty_is_moving
        call monty_toggle_step_gate
        beq .done
        dec <monty_x
        call monty_check_room_edges
.done:  rts
.right:
        call monty_check_tile_right
        bcs .done_right
        stz <monty_facing
        lda #1
        sta <monty_is_moving
        call monty_toggle_step_gate
        bne .done_right
        inc <monty_x
        call monty_check_room_edges
.done_right:
        rts

monty_jump_step:
        lda <monty_jump_phase
        beq .done
        cmp #1
        bne .descent
        call monty_check_tile_above
        bcs .switch_down
        ldx <monty_jump_index
        lda monty_jump_arc_up,x
        cmp #$ff
        beq .switch_down
        sta <jump_delta
        lda <monty_y
        sec
        sbc <jump_delta
        sta <monty_y
        inc <monty_jump_index
        call monty_check_room_edges
        rts
.switch_down:
        lda #2
        sta <monty_jump_phase
        stz <monty_jump_index
        rts
.descent:
        call monty_check_tile_below
        bcs .land
        ldx <monty_jump_index
        lda monty_jump_arc_down,x
        cmp #$ff
        beq .land
        clc
        adc <monty_y
        sta <monty_y
        inc <monty_jump_index
        rts
.land:
        stz <monty_jump_phase
        stz <monty_jump_index
        stz <monty_saved_left
        stz <monty_saved_right
.done:  rts

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
