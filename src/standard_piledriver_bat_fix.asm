; PCE BAT high-byte correction for original-style standard piledrivers.
; PILE_CHR0/1 live above tile $ff, so BAT high byte must contain tile bit 8
; together with the C64-derived palette nibble. The shaft BAT cells are static;
; animation changes only pattern pixels, exactly like the C64 charset shifts.

.code
piledriver_fix_bat_hi:
        lda     <piledriver_count
        bne     .driver0
        rts
.driver0:
        ldx     #0
        call    piledriver_fix_one_bat
        lda     <piledriver_count
        cmp     #2
        bne     .done
        ldx     #1
        call    piledriver_fix_one_bat
.done:
        rts

piledriver_fix_one_bat:
        cpx     #0
        bne     .d1
        lda     <piledriver_col0
        sta     <piledriver_tmp_col
        lda     <piledriver_row0
        sta     <piledriver_tmp_y
        lda     #4
        sta     <piledriver_tmp_h
        lda     #<PILE_CHR0
        sta     <piledriver_tmp_chr
        bra     .rows
.d1:
        lda     <piledriver_col1
        sta     <piledriver_tmp_col
        lda     <piledriver_row1
        sta     <piledriver_tmp_y
        lda     #6
        sta     <piledriver_tmp_h
        lda     #<PILE_CHR1
        sta     <piledriver_tmp_chr
.rows:
        ldx     #0
.row_loop:
        lda     <piledriver_tmp_y
        tay
        lda     piledriver_bat_row_lo,y
        clc
        adc     <piledriver_tmp_col
        sta     <_di
        lda     piledriver_bat_row_hi,y
        adc     #0
        sta     <_di+1
        call    vdc_di_to_mawr

        ; left: palette 6 + tile high bit 1
        txa
        clc
        adc     <piledriver_tmp_chr
        sta     VDC_DL
        lda     #$61
        sta     VDC_DH

        ; middle: palette 5 + tile high bit 1
        txa
        clc
        adc     #6
        clc
        adc     <piledriver_tmp_chr
        sta     VDC_DL
        lda     #$51
        sta     VDC_DH

        ; right: palette 4 + tile high bit 1
        txa
        clc
        adc     #12
        clc
        adc     <piledriver_tmp_chr
        sta     VDC_DL
        lda     #$41
        sta     VDC_DH

        inc     <piledriver_tmp_y
        inx
        cpx     <piledriver_tmp_h
        bne     .row_loop
        rts
