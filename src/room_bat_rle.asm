; Compact 16-bit BAT RLE depacker for extended rooms.
; Mirrors the original game's idea: keep room layout compressed in ROM and
; expand only while entering a room instead of storing a full 36x20 BAT.
;
; Stream format (tools/bat_word_rle.py):
;   bit7=1: ((ctrl&$7f)+1) copies of one following little-endian BAT word
;   bit7=0: (ctrl+1) literal little-endian BAT words follow
;
; Input: _bp = packed stream address, Y = BANK(stream).
; Output: exact 36x20 visible room BAT at C64 rows 3..22.

.zp
room_rle_ctrl:          ds 1
room_rle_count:         ds 1
room_rle_word_lo:       ds 1
room_rle_word_hi:       ds 1
room_rle_cols:          ds 1
room_rle_rows:          ds 1

.code
.proc room_draw_rle_36x20
        php
        sei
        tma3
        pha
        tma4
        pha
        call    map_bp_to_mpr34

        lda     #<((3)*BAT_LINE+ROOM_X)
        sta     <_di
        lda     #>((3)*BAT_LINE+ROOM_X)
        sta     <_di+1
        lda     #36
        sta     <room_rle_cols
        lda     #20
        sta     <room_rle_rows
        call    vdc_di_to_mawr

.next_packet:
        lda     <room_rle_rows
        beq     .done
        bsr     .get_byte
        sta     <room_rle_ctrl
        and     #$7f
        inc     a
        sta     <room_rle_count
        lda     <room_rle_ctrl
        bmi     .run_packet

.literal_loop:
        bsr     .get_byte
        sta     <room_rle_word_lo
        bsr     .get_byte
        sta     <room_rle_word_hi
        bsr     .emit_word
        dec     <room_rle_count
        bne     .literal_loop
        bra     .next_packet

.run_packet:
        bsr     .get_byte
        sta     <room_rle_word_lo
        bsr     .get_byte
        sta     <room_rle_word_hi
.run_loop:
        bsr     .emit_word
        dec     <room_rle_count
        bne     .run_loop
        bra     .next_packet

; Advance the mapped ROM pointer one byte at a time. This avoids keeping a Y
; source index live across VDC helper calls and naturally crosses MPR3->MPR4.
.get_byte:
        cly
        lda     [_bp],y
        inc     <_bp
        bne     .got_byte
        inc     <_bp+1
.got_byte:
        rts

.emit_word:
        lda     <room_rle_word_lo
        sta     VDC_DL
        lda     <room_rle_word_hi
        sta     VDC_DH
        dec     <room_rle_cols
        bne     .emit_done

        dec     <room_rle_rows
        beq     .emit_done
        lda     #36
        sta     <room_rle_cols
        lda     <_di
        clc
        adc     #BAT_LINE
        sta     <_di
        bcc     .row_ptr_ok
        inc     <_di+1
.row_ptr_ok:
        call    vdc_di_to_mawr
.emit_done:
        rts

.done:
        pla
        tam4
        pla
        tam3
        plp
        leave
.endp
