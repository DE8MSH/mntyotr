; PAL is the behavioural timing reference. On a PAL SNES one gameplay update
; runs per VBlank. For NTSC bring-up we retain the PCE port's simple 5/6 gate,
; yielding approximately 50 logical updates per second from ~60 VBlanks.
;
; Returns C=1 when the gameplay core should advance.

game_clock_init:
        stz     logic_phase
        rts

game_clock_step:
.ifdef SNES_NTSC
        lda     logic_phase
        clc
        adc     #5
        cmp     #6
        bcc     @no_tick
        sbc     #6
        sta     logic_phase
        sec
        rts
@no_tick:
        sta     logic_phase
        clc
        rts
.else
        sec
        rts
.endif
