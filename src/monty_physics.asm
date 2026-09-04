; Behavioural data ported from the annotated C64 reconstruction.
; Keep gameplay constants in C64 units (pixels / logical PAL ticks).

.zp
monty_x:                ds 1
monty_y:                ds 1
monty_jump_phase:       ds 1           ; 0=ground, 1=ascent, 2=descent
monty_jump_index:       ds 1
monty_facing:           ds 1
collision_x:            ds 1
collision_y:            ds 1
collision_count:        ds 1
jump_delta:             ds 1

.code

monty_physics_init:
        lda     #$40                    ; provisional room-$00 bring-up position
        sta     <monty_x
        lda     #$b0
        sta     <monty_y
        stz     <monty_jump_phase
        stz     <monty_jump_index
        stz     <monty_facing
        rts

; A = logical room tile id 0..7. Returns its C64 collision property in A.
room00_get_tile_property:
        cmp     #8
        bcs     .empty
        tax
        lda     room00_tile_properties,x
        rts
.empty:
        cla
        rts

; Read logical room tile at X=column (0..31), Y=row (0..19).
; Returns tile id in A, or 0 outside the room. Uses the generated 640-byte map.
room00_get_tile_xy:
        cpx     #32
        bcs     .outside
        cpy     #20
        bcs     .outside
        stx     <collision_x
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a                       ; row * 32
        clc
        adc     <collision_x
        tax
        lda     room00_collision_map,x
        rts
.outside:
        cla
        rts

; Read C64 collision property at logical room tile X/Y.
room00_get_property_xy:
        bsr     room00_get_tile_xy
        jmp     room00_get_tile_property

; C64-compatible horizontal probes. The original checks only on a 4-pixel
; horizontal boundary and samples up to three vertical tile positions.
; Carry set = solid property 1 encountered.
monty_check_tile_right:
        lda     <monty_x
        sec
        sbc     #$0c
        and     #$03
        bne     .clear
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
        clc
        adc     #$02
        tax
        lda     #3
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
        lda     #3
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

; Vertical probes preserve the C64 8-pixel boundary test and sample the
; columns touched by Monty's 12-pixel-wide logical collision footprint.
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
        lsr     a
        lsr     a
        tax
        lda     #3
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
        lsr     a
        lsr     a
        tax
        lda     #3
        sta     <collision_count
.loop:
        phx
        phy
        bsr     room00_get_property_xy
        ply
        plx
        cmp     #$01
        beq     .solid
        ; Properties 2/3 are also blocking below during an active jump,
        ; matching the C64 movement path. Property 4 event handling follows.
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

; Start a C64 jump arc if currently grounded.
monty_jump_start:
        lda     <monty_jump_phase
        bne     .done
        lda     #1
        sta     <monty_jump_phase
        stz     <monty_jump_index
.done:
        rts

; Advance one vertical jump-arc sample, clipping against the room map.
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
.done:
        rts

.data
room00_tile_properties:
        db $01,$01,$01,$02,$01,$01,$01,$01

; Exact C64 Y-delta sequences. $FF terminates each phase.
monty_jump_arc_up:
        db $00,$03,$02,$02,$01,$02,$01,$01,$00,$01,$01,$01
        db $00,$01,$01,$01,$00,$01,$00,$01,$00,$00,$ff
monty_jump_arc_down:
        db $01,$00,$00,$00,$01,$00,$01,$00,$01,$00,$02,$01
        db $02,$01,$02,$02,$00,$ff
