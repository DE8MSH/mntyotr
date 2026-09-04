; PAL-oriented logical game clock.
;
; The PC Engine display refresh and C64 gameplay update rate are deliberately
; decoupled. Initial hardware-independent gate: 5 logical updates per 6 PCE
; VBlanks (~50 updates/s on a ~60 Hz display). A later calibrated fixed-point
; phase accumulator will use measured/verified refresh constants for ~50.12 Hz.
;
; game_clock_step returns C=1 when one C64 gameplay tick must execute.

.zp
game_clock_phase:       ds 1
game_tick_counter:      ds 1

.code

game_clock_init:
        stz     <game_clock_phase
        stz     <game_tick_counter
        rts

game_clock_step:
        lda     <game_clock_phase
        clc
        adc     #5
        cmp     #6
        bcc     .no_tick
        sbc     #6                      ; carry is set after CMP
        sta     <game_clock_phase
        sec
        rts
.no_tick:
        sta     <game_clock_phase
        clc
        rts
