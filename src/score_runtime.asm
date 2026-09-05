; Authentic C64 live score arithmetic.
; Original score_in_memory is five display-ready ASCII digits ($30..$39).
; Score.Increase accepts A=amount and Y=digit (0=10000 .. 4=units), so
; A=5,Y=3 means +50 and A=2,Y=2 means +200. Carry/borrow behaviour matches
; refactored/src/subsystems/score.asm exactly.

.bss
score_digits:           ds 5
score_lsb:              ds 1

.code
score_init:
        ldx     #4
        lda     #$30
.init_loop:
        sta     score_digits,x
        dex
        bpl     .init_loop
        rts

; In: A=value to add at digit Y. Clobbers A/Y; matches C64 carry cascade.
score_increase:
        sta     score_lsb
        lda     score_digits,y
        cmp     #$20
        bne     .have_digit
        lda     #$30
.have_digit:
        clc
        adc     score_lsb
        cmp     #$3a
        bmi     .store_done
        sec
        sbc     #$0a
        sta     score_digits,y
        lda     #$01
        dey
        bpl     score_increase
        rts
.store_done:
        sta     score_digits,y
        rts

; Decrement by one. As in the C64 routine, Y=$ff signals total underflow.
score_decrement:
        ldy     #$04
.dec_loop:
        lda     score_digits,y
        sec
        sbc     #$01
        sta     score_digits,y
        cmp     #$2f
        beq     .borrow
        rts
.borrow:
        lda     #$39
        sta     score_digits,y
        dey
        bpl     .dec_loop
        rts

; Helper used by the arrested ending later: reset the underflowed score to zero.
score_zero:
        ldy     #$04
        lda     #$30
.zero_loop:
        sta     score_digits,y
        dey
        bpl     .zero_loop
        rts
