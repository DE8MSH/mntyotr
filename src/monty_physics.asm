; Behavioural data ported from the annotated C64 reconstruction.
; Keep gameplay constants in C64 units (pixels / logical PAL ticks).

.zp
monty_x:                ds 1
monty_y:                ds 1
monty_jump_phase:       ds 1           ; 0=ground, 1=ascent, 2=descent
monty_jump_index:       ds 1
monty_facing:           ds 1

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
; Room $00 definition uses library chars 0A,0B,01,3A,15,00,00,00.
room00_get_tile_property:
        cmp     #8
        bcs     .empty
        tax
        lda     room00_tile_properties,x
        rts
.empty:
        cla
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

; Advance one vertical jump-arc sample. This preserves the original C64
; per-frame deltas. Collision clipping/landing is attached in the next step.
monty_jump_step:
        lda     <monty_jump_phase
        beq     .done
        cmp     #1
        bne     .descent
        ldx     <monty_jump_index
        lda     monty_jump_arc_up,x
        cmp     #$ff
        beq     .switch_down
        sta     jump_delta
        lda     <monty_y
        sec
        sbc     jump_delta
        sta     <monty_y
        inc     <monty_jump_index
        rts
.switch_down:
        lda     #2
        sta     <monty_jump_phase
        stz     <monty_jump_index
        rts
.descent:
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

.zp
jump_delta:             ds 1

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
