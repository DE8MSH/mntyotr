; PAL-oriented logical game clock.
;
; The PC Engine display refresh and C64 gameplay update rate are deliberately
; decoupled. Initial hardware-independent gate: 5 logical updates per 6 PCE
; VBlanks (~50 updates/s on a ~60 Hz display). A later calibrated fixed-point
; phase accumulator will use measured/verified refresh constants for ~50.12 Hz.
;
; game_clock_step returns C=1 when one C64 gameplay tick must execute.
;
; Keep both tiny clock routines relocatable. Bank 0 is the fixed HOME/thunk
; bank and must retain headroom as the complete game grows; --newproc places
; these bodies in the normal code banks and leaves only compact far-call thunks
; in HOME. Carry is intentionally set immediately before LEAVE in step().

.zp
game_clock_phase:       ds 1
game_tick_counter:      ds 1

.code

.proc game_clock_init
        stz     <game_clock_phase
        stz     <game_tick_counter
        leave
.endp

.proc game_clock_step
        lda     <game_clock_phase
        clc
        adc     #5
        cmp     #6
        bcc     .no_tick
        sbc     #6                      ; carry is set after CMP
        sta     <game_clock_phase
        call    monty_sprite_tick_watchdog
        sec
        leave
.no_tick:
        sta     <game_clock_phase
        clc
        leave
.endp

; Walking/climbing animation must never depend solely on a decrementing private
; timer. If that byte is ever cleared/corrupted, DEC $00 becomes $FF and Monty
; appears frozen for hundreds of ticks even though movement still works.
;
; Use the monotonic logical gameplay counter as a second, deterministic clock.
; The normal monty_sprite_animate routine still handles jumps, facing changes and
; immediate dirty uploads; this watchdog only guarantees that ordinary 4-frame
; walk/climb animation continues while Monty was moving on the previous tick.
.proc monty_sprite_tick_watchdog
        lda     <monty_is_moving
        beq     .done
        lda     <monty_jump_phase
        bne     .done

        lda     <game_tick_counter
        lsr     a
        lsr     a
        and     #3
        cmp     <monty_anim_frame
        beq     .done
        sta     <monty_anim_frame
        lda     #4
        sta     <monty_anim_timer
        lda     #1
        sta     <monty_sprite_dirty

        lda     <monty_climbing
        beq     .walk
        call    monty_upload_climb_frame
        bra     .done
.walk:
        call    monty_upload_walk_frame
.done:
        leave
.endp
