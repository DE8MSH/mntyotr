; Exact runtime wrapper for the proven safe Piledriver renderer.
; Keeps the stable regenerated-VRAM implementation, but restores two C64 rules:
;  1) delay and driver selection use TWO independent random draws;
;  2) CheckTiles kills only while descending and only when Monty's upper 2x2
;     character footprint overlaps the currently selected shaft.
;
; Original CheckTiles then tests pd_sprite_y[index] + position >= monty_y.
; Scratch state lives in normal RAM so this mechanism does not consume more ZP.

.bss
pile_exact_rng:       ds 1
pile_exact_base_col:  ds 1
pile_exact_base_row:  ds 1
pile_exact_pd_col:    ds 1
pile_exact_pd_row:    ds 1
pile_exact_pd_height: ds 1
pile_exact_pd_y:      ds 1

.code

piledriver_exact_init:
        lda     #$a5
        sta     pile_exact_rng
        rts

; Piledriver requires independent successive random bytes. The C64 source calls
; its shared hardware-mixed RNG twice; this local state preserves that observable
; rule without coupling delay and driver choice to game_tick_counter.
piledriver_exact_random:
        lda     pile_exact_rng
        asl     a
        bcc     .store
        eor     #$1d
.store:
        bne     .nonzero
        lda     #$a5
.nonzero:
        sta     pile_exact_rng
        rts

piledriver_exact_update:
        lda     <pile_static_count
        bne     .active
        rts
.active:
        lda     <pile_static_state
        bne     .moving

        dec     <pile_static_delay
        beq     .activate
        rts
.activate:
        ; First original RNG call: next idle delay $14..$53.
        call    piledriver_exact_random
        and     #$3f
        clc
        adc     #$14
        sta     <pile_static_delay

        ; Second independent original RNG call: choose one of two Room01 drivers.
        call    piledriver_exact_random
        and     #1
        tax
        lda     <pile_static_count
        cmp     #2
        beq     .picked
        ldx     #0
.picked:
        stx     <pile_static_index
        lda     #1
        sta     <pile_static_state
        lda     #5
        sta     <pile_static_position
        stz     <pile_static_shift
        jmp     piledriver_static_upload_selected

.moving:
        cmp     #2
        beq     .retract

        inc     <pile_static_position
        inc     <pile_static_position
        ldx     <pile_static_index
        lda     <pile_static_position
        cpx     #0
        bne     .limit1
        cmp     <pile_static_limit0
        bra     .limit_cmp
.limit1:
        cmp     <pile_static_limit1
.limit_cmp:
        bcc     .move_down
        lda     #2
        sta     <pile_static_state
        rts
.move_down:
        lda     <pile_static_position
        sec
        sbc     #5
        sta     <pile_static_shift
        call    piledriver_static_upload_selected
        jmp     piledriver_exact_check_tiles

.retract:
        dec     <pile_static_position
        dec     <pile_static_position
        lda     <pile_static_position
        cmp     #6
        bcs     .move_up
        stz     <pile_static_state
        stz     <pile_static_shift
        lda     #$ff
        sta     <pile_static_index
        rts
.move_up:
        sec
        sbc     #5
        sta     <pile_static_shift
        jmp     piledriver_static_upload_selected

; Equivalent of C64 CheckTiles for the PCE representation. Original scans
; tile offsets 00,01,28,29: Monty's upper 2x2 screen characters.
piledriver_exact_check_tiles:
        lda     <pile_static_index
        cmp     #$ff
        bne     .index_ok
        jmp     .done
.index_ok:
        lda     <pile_static_state
        cmp     #2
        bne     .state_ok
        jmp     .done
.state_ok:

        ; C64 screen column = (monty_x-$0c)>>2.
        lda     <monty_x
        sec
        sbc     #$0c
        lsr     a
        lsr     a
        sta     pile_exact_base_col

        ; C64 screen row = (monty_y-$32)>>3.
        lda     <monty_y
        sec
        sbc     #$32
        lsr     a
        lsr     a
        lsr     a
        sta     pile_exact_base_row

        lda     <pile_static_index
        bne     .driver1
        lda     <monty_room
        cmp     #$01
        beq     .d0_room01
        cmp     #$02
        beq     .d0_room02
        cmp     #$0b
        beq     .d0_room0b
        rts
.d0_room01:
        lda     #$07
        sta     pile_exact_pd_col
        lda     #$05
        sta     pile_exact_pd_row
        lda     #4
        sta     pile_exact_pd_height
        lda     #$5c
        sta     pile_exact_pd_y
        bra     .overlap
.d0_room02:
        lda     #$15
        sta     pile_exact_pd_col
        lda     #$05
        sta     pile_exact_pd_row
        lda     #4
        sta     pile_exact_pd_height
        lda     #$5c
        sta     pile_exact_pd_y
        bra     .overlap
.d0_room0b:
        lda     #$13
        sta     pile_exact_pd_col
        lda     #$11
        sta     pile_exact_pd_row
        lda     #4
        sta     pile_exact_pd_height
        lda     #$bc
        sta     pile_exact_pd_y
        bra     .overlap
.driver1:
        lda     <monty_room
        cmp     #$01
        bne     .done
        lda     #$1f
        sta     pile_exact_pd_col
        lda     #$0c
        sta     pile_exact_pd_row
        lda     #6
        sta     pile_exact_pd_height
        lda     #$94
        sta     pile_exact_pd_y

.overlap:
        ; Horizontal intersection: Monty [base,base+1], shaft [col,col+2].
        lda     pile_exact_base_col
        clc
        adc     #1
        cmp     pile_exact_pd_col
        bcc     .done
        lda     pile_exact_pd_col
        clc
        adc     #2
        cmp     pile_exact_base_col
        bcc     .done

        ; Vertical intersection of Monty's upper 2 chars with shaft rows.
        lda     pile_exact_base_row
        clc
        adc     #1
        cmp     pile_exact_pd_row
        bcc     .done
        lda     pile_exact_pd_row
        clc
        adc     pile_exact_pd_height
        dec     a
        cmp     pile_exact_base_row
        bcc     .done

        ; Exact C64 final test.
        lda     pile_exact_pd_y
        clc
        adc     <pile_static_position
        cmp     <monty_y
        bcc     .done
        lda     #4
        sta     <monty_action_counter
.done:
        rts
