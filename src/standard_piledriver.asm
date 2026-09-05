; Standard C64 piledriver mechanism for currently ported rooms $01/$02/$0B.
;
; IMPORTANT: the original piledriver is NOT a sprite. RoomInit DrawShaft writes a
; 3-character-wide shaft into screen RAM and animation shifts bitmap bytes inside
; two independent 18-character charset buffers:
;   driver 0 chars $10..$21, driver 1 chars $22..$33.
; This PCE implementation mirrors that model with two 144-byte RAM glyph buffers
; (3 columns * 6 chars * 8 rows), dynamic BG patterns and fixed BAT cells.

PILE_CHR0 = CHR_GAME + 64
PILE_CHR1 = PILE_CHR0 + 18
PILE_PAL_LEFT  = 6                 ; C64 $0F light grey
PILE_PAL_MID   = 5                 ; C64 $0C medium grey
PILE_PAL_RIGHT = 4                 ; C64 $0B dark grey

.zp
piledriver_last_room: ds 1
piledriver_count:     ds 1
piledriver_state:     ds 1          ; 0 idle, 1 descending, 2 retracting
piledriver_delay:     ds 1
piledriver_index:     ds 1          ; $ff idle, 0/1 selected
piledriver_position:  ds 1
piledriver_col0:      ds 1
piledriver_row0:      ds 1
piledriver_limit0:    ds 1
piledriver_y0:        ds 1
piledriver_col1:      ds 1
piledriver_row1:      ds 1
piledriver_limit1:    ds 1
piledriver_y1:        ds 1
piledriver_tmp_x:     ds 1
piledriver_tmp_y:     ds 1
piledriver_tmp_h:     ds 1
piledriver_tmp_chr:   ds 1
piledriver_tmp_col:   ds 1
piledriver_tmp_rows:  ds 1
piledriver_tmp_cols:  ds 1

.bss
piledriver_buf0: ds 144
piledriver_buf1: ds 144

.code

piledriver_init:
        lda     #$ff
        sta     <piledriver_last_room
        sta     <piledriver_index
        stz     <piledriver_count
        stz     <piledriver_state
        lda     #1
        sta     <piledriver_delay
        call    piledriver_clear_seed_buffers
        call    piledriver_upload_both
        rts

; Called after room graphics have been loaded. This draws the shafts at their
; ORIGINAL C64 screen coordinates and resets both independent glyph buffers.
piledriver_room_sync:
        lda     <monty_room
        cmp     <piledriver_last_room
        bne     .changed
        rts
.changed:
        sta     <piledriver_last_room
        stz     <piledriver_count
        stz     <piledriver_state
        lda     #1
        sta     <piledriver_delay
        lda     #$ff
        sta     <piledriver_index

        lda     <monty_room
        cmp     #$01
        beq     .room01
        cmp     #$02
        beq     .room02
        cmp     #$0b
        beq     .room0b
        rts

.room01:
        ; Original config_tbl:
        ; $01,$07,$05,$04,$10 and $01,$1f,$0c,$06,$22
        lda     #2
        sta     <piledriver_count
        lda     #$07
        sta     <piledriver_col0
        lda     #$05
        sta     <piledriver_row0
        lda     #$1f
        sta     <piledriver_limit0
        lda     #$5c                    ; row*8+$34
        sta     <piledriver_y0
        lda     #$1f
        sta     <piledriver_col1
        lda     #$0c
        sta     <piledriver_row1
        lda     #$2f
        sta     <piledriver_limit1
        lda     #$94
        sta     <piledriver_y1
        jmp     piledriver_prepare_room

.room02:
        ; $02,$15,$05,$04,$10
        lda     #1
        sta     <piledriver_count
        lda     #$15
        sta     <piledriver_col0
        lda     #$05
        sta     <piledriver_row0
        lda     #$1f
        sta     <piledriver_limit0
        lda     #$5c
        sta     <piledriver_y0
        jmp     piledriver_prepare_room

.room0b:
        ; $0b,$13,$11,$04,$10
        lda     #1
        sta     <piledriver_count
        lda     #$13
        sta     <piledriver_col0
        lda     #$11
        sta     <piledriver_row0
        lda     #$1f
        sta     <piledriver_limit0
        lda     #$bc
        sta     <piledriver_y0

piledriver_prepare_room:
        call    piledriver_clear_seed_buffers
        call    piledriver_upload_both
        ldx     #0
        call    piledriver_draw_shaft
        lda     <piledriver_count
        cmp     #2
        bne     .done
        ldx     #1
        call    piledriver_draw_shaft
.done:
        rts

; ---------------------------------------------------------------------------
; Exact C64 animation state machine.
; ---------------------------------------------------------------------------
piledriver_update:
        lda     <piledriver_count
        bne     .active_room
        rts
.active_room:
        lda     <piledriver_state
        bne     .step

        lda     #$ff
        sta     <piledriver_index
        dec     <piledriver_delay
        beq     .activate
        rts

.activate:
        ; Original delay is random $14..$53. game_tick_counter supplies the
        ; deterministic test-build entropy while preserving the same range.
        lda     game_tick_counter
        and     #$3f
        clc
        adc     #$14
        sta     <piledriver_delay
        ldx     #0
        lda     <piledriver_count
        cmp     #2
        bne     .picked
        lda     game_tick_counter
        and     #1
        tax
.picked:
        stx     <piledriver_index
        lda     #1
        sta     <piledriver_state
        lda     #5
        sta     <piledriver_position
        ; Original SeedGlyphs runs again on activation.
        call    piledriver_seed_selected
        rts

.step:
        cmp     #2
        beq     .retract

        inc     <piledriver_position
        inc     <piledriver_position
        ldx     <piledriver_index
        lda     <piledriver_position
        cpx     #0
        bne     .limit1
        cmp     <piledriver_limit0
        bra     .limit_cmp
.limit1:
        cmp     <piledriver_limit1
.limit_cmp:
        bcc     .move_down
        inc     <piledriver_state
        rts
.move_down:
        call    piledriver_shift_down
        call    piledriver_shift_down
        call    piledriver_upload_selected
        jmp     piledriver_check_hit

.retract:
        dec     <piledriver_position
        dec     <piledriver_position
        lda     <piledriver_position
        cmp     #6
        bcs     .move_up
        stz     <piledriver_state
        lda     #$ff
        sta     <piledriver_index
        rts
.move_up:
        call    piledriver_shift_up
        call    piledriver_shift_up
        call    piledriver_upload_selected
        rts

; Source death dispatch for standard piledriver is action_counter=4.
piledriver_check_hit:
        ldx     <piledriver_index
        cpx     #0
        bne     .driver1
        lda     <piledriver_col0
        sta     <piledriver_tmp_x
        lda     <piledriver_y0
        bra     .have
.driver1:
        lda     <piledriver_col1
        sta     <piledriver_tmp_x
        lda     <piledriver_y1
.have:
        clc
        adc     <piledriver_position
        cmp     <monty_y
        bcc     .done

        ; screen column to gameplay-X used by the current Monty collision model.
        lda     <piledriver_tmp_x
        asl     a
        asl     a
        clc
        adc     #$0c
        sta     <piledriver_tmp_x
        lda     <monty_x
        cmp     <piledriver_tmp_x
        bcc     .done
        lda     <piledriver_tmp_x
        clc
        adc     #12
        cmp     <monty_x
        bcc     .done
        lda     #4
        sta     <monty_action_counter
.done:
        rts

; ---------------------------------------------------------------------------
; C64 glyph buffers / SeedGlyphs / MoveDown / MoveUp.
; Buffer layout is exactly left[48], middle[48], right[48].
; ---------------------------------------------------------------------------
piledriver_clear_seed_buffers:
        lda     #<piledriver_buf0
        sta     <_bp
        lda     #>piledriver_buf0
        sta     <_bp+1
        call    piledriver_clear_one
        lda     #<piledriver_buf1
        sta     <_bp
        lda     #>piledriver_buf1
        sta     <_bp+1
        call    piledriver_clear_one
        ldx     #0
        call    piledriver_seed_buffer_x
        ldx     #1
        call    piledriver_seed_buffer_x
        rts

piledriver_clear_one:
        cly
        lda     #0
.clear:
        sta     [_bp],y
        iny
        cpy     #144
        bne     .clear
        rts

piledriver_seed_selected:
        ldx     <piledriver_index
piledriver_seed_buffer_x:
        cpx     #0
        bne     .buf1
        lda     #<piledriver_buf0
        sta     <_di
        lda     #>piledriver_buf0
        bra     .base
.buf1:
        lda     #<piledriver_buf1
        sta     <_di
        lda     #>piledriver_buf1
.base:
        sta     <_di+1
        ldx     #0
.seed_loop:
        lda     piledriver_seed_left,x
        ldy     piledriver_seed_off_left,x
        sta     [_di],y
        lda     piledriver_seed_mid,x
        ldy     piledriver_seed_off_mid,x
        sta     [_di],y
        lda     piledriver_seed_right,x
        ldy     piledriver_seed_off_right,x
        sta     [_di],y
        inx
        cpx     #8
        bne     .seed_loop
        rts

piledriver_select_buffer:
        lda     <piledriver_index
        bne     .buf1
        lda     #<piledriver_buf0
        sta     <_bp
        lda     #>piledriver_buf0
        sta     <_bp+1
        rts
.buf1:
        lda     #<piledriver_buf1
        sta     <_bp
        lda     #>piledriver_buf1
        sta     <_bp+1
        rts

; Exact MoveDown: for each 48-byte column copy byte 46..0 into 47..1.
piledriver_shift_down:
        call    piledriver_select_buffer
        ldx     #3
.col:
        ldy     #46
.byte:
        lda     [_bp],y
        phy
        iny
        sta     [_bp],y
        ply
        dey
        cpy     #$ff
        bne     .byte
        lda     <_bp
        clc
        adc     #48
        sta     <_bp
        bcc     .next_col
        inc     <_bp+1
.next_col:
        dex
        bne     .col
        rts

; Exact MoveUp: for each 48-byte column copy byte 1..47 into 0..46.
piledriver_shift_up:
        call    piledriver_select_buffer
        ldx     #3
.col:
        ldy     #1
.byte:
        lda     [_bp],y
        phy
        dey
        sta     [_bp],y
        ply
        iny
        cpy     #48
        bne     .byte
        lda     <_bp
        clc
        adc     #48
        sta     <_bp
        bcc     .next_col
        inc     <_bp+1
.next_col:
        dex
        bne     .col
        rts

; ---------------------------------------------------------------------------
; PCE dynamic BG-pattern upload.
; Each C64 8-byte character becomes one PCE 1bpp tile: plane0 data, other planes 0.
; ---------------------------------------------------------------------------
piledriver_upload_both:
        ldx     #0
        call    piledriver_upload_buffer_x
        ldx     #1
        call    piledriver_upload_buffer_x
        rts

piledriver_upload_selected:
        ldx     <piledriver_index
piledriver_upload_buffer_x:
        cpx     #0
        bne     .buf1
        lda     #<piledriver_buf0
        sta     <_bp
        lda     #>piledriver_buf0
        sta     <_bp+1
        lda     #<(PILE_CHR0*16)
        sta     <_di
        lda     #>(PILE_CHR0*16)
        bra     .upload
.buf1:
        lda     #<piledriver_buf1
        sta     <_bp
        lda     #>piledriver_buf1
        sta     <_bp+1
        lda     #<(PILE_CHR1*16)
        sta     <_di
        lda     #>(PILE_CHR1*16)
.upload:
        sta     <_di+1
        call    vdc_di_to_mawr
        cly
        ldx     #18
.char:
        lda     #8
        sta     <piledriver_tmp_rows
.rows:
        lda     [_bp],y
        sta     VDC_DL
        stz     VDC_DH
        iny
        dec     <piledriver_tmp_rows
        bne     .rows
        lda     #8
        sta     <piledriver_tmp_rows
.blank_planes:
        stz     VDC_DL
        stz     VDC_DH
        dec     <piledriver_tmp_rows
        bne     .blank_planes
        dex
        bne     .char
        rts

; ---------------------------------------------------------------------------
; Original DrawShaft: 3 columns wide, height rows, left/mid/right palettes.
; Driver 0 uses char rows 0..5 / +6 / +12; driver 1 has its own 18 tiles.
; ---------------------------------------------------------------------------
piledriver_draw_shaft:
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
        ; BAT address = screen_row*64 + absolute C64 screen column.
        lda     <piledriver_tmp_y
        clc
        adc     #0
        tay
        lda     piledriver_bat_row_lo,y
        clc
        adc     <piledriver_tmp_col
        sta     <_di
        lda     piledriver_bat_row_hi,y
        adc     #0
        sta     <_di+1
        call    vdc_di_to_mawr

        ; left = base+row, palette 6
        txa
        clc
        adc     <piledriver_tmp_chr
        sta     VDC_DL
        lda     #PILE_PAL_LEFT
        asl     a
        asl     a
        asl     a
        asl     a
        sta     VDC_DH

        ; middle = base+6+row, palette 5
        txa
        clc
        adc     #6
        clc
        adc     <piledriver_tmp_chr
        sta     VDC_DL
        lda     #PILE_PAL_MID
        asl     a
        asl     a
        asl     a
        asl     a
        sta     VDC_DH

        ; right = base+12+row, palette 4
        txa
        clc
        adc     #12
        clc
        adc     <piledriver_tmp_chr
        sta     VDC_DL
        lda     #PILE_PAL_RIGHT
        asl     a
        asl     a
        asl     a
        asl     a
        sta     VDC_DH

        inc     <piledriver_tmp_y
        inx
        cpx     <piledriver_tmp_h
        bne     .row_loop
        rts

; Compatibility no-op: old first pass used SAT sprites. Keeping this symbol lets
; existing call sites remain harmless while proving there are no piledriver SAT writes.
piledriver_update_satb:
        rts

.data
; Exact normal piledriver_frame_data from mechanisms_data.asm.
piledriver_seed_left:
        db $0f,$0f,$00,$ff,$ff,$ff,$7f,$00
piledriver_seed_mid:
        db $ff,$ff,$00,$ff,$ff,$ff,$ff,$00
piledriver_seed_right:
        db $f0,$f0,$00,$ff,$ff,$ff,$fe,$00

; Y offsets for first 8 seed bytes of each 48-byte column.
piledriver_seed_off_left:
        db 0,1,2,3,4,5,6,7
piledriver_seed_off_mid:
        db 48,49,50,51,52,53,54,55
piledriver_seed_off_right:
        db 96,97,98,99,100,101,102,103

; 64-word BAT row offsets for screen rows 0..27.
piledriver_bat_row_lo:
        db $00,$40,$80,$c0,$00,$40,$80,$c0,$00,$40,$80,$c0,$00,$40,$80,$c0
        db $00,$40,$80,$c0,$00,$40,$80,$c0,$00,$40,$80,$c0
piledriver_bat_row_hi:
        db $00,$00,$00,$00,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03
        db $04,$04,$04,$04,$05,$05,$05,$05,$06,$06,$06,$06
