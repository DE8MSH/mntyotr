; Phase 50: Room $01 rising cloud collision + stateless moving-platform push.
;
; C64 SpecialItems.UpdateRisingCloud:
;   - active only in Room $01
;   - fixed screen columns $0C-$0E (logical room cols 8..10)
;   - moves upward one pixel on odd logical ticks
;   - writes screen code $08 (Room01 tile $64 / property 3) into its row
;   - clears the row below as the cloud rises
;
; The PCE port keeps the authentic mutable property-3 strip. The visual sprite
; follows rising_cloud_y separately. A small stateless push keeps a player who
; is exactly on the cloud top aligned with its 1px motion. Before that push the
; COMPLETE prospective 2x3/3x3 tile footprint is checked for property-1 solids;
; this prevents the cloud from pushing Monty through a ceiling/wall that enters
; the middle of his footprint before the normal aligned CheckTileAbove can see it.

CLOUD_OFFSCREEN_ROW = $ff
CLOUD_VIS_COL       = 12
CLOUD_CODE          = 8
CLOUD_PAL           = 12
CLOUD_BAT_WORD      = $c000+CHR_GAME+CLOUD_CODE

.zp
rising_cloud_last_room:  ds 1
rising_cloud_y:          ds 1
rising_cloud_tick:       ds 1
rising_cloud_row:        ds 1
rising_cloud_push:       ds 1
rising_cloud_tmp_row:    ds 1
rising_cloud_top_y:      ds 1
rising_cloud_probe_x:    ds 1
rising_cloud_probe_y:    ds 1
rising_cloud_probe_cols: ds 1
rising_cloud_probe_rows: ds 1
rising_cloud_probe_ctr:  ds 1

.code

rising_cloud_init:
        lda     #$ff
        sta     <rising_cloud_last_room
        sta     <rising_cloud_row
        lda     #$d9
        sta     <rising_cloud_y
        stz     <rising_cloud_tick
        stz     <rising_cloud_push
        rts

rising_cloud_room_sync:
        lda     <monty_room
        cmp     <rising_cloud_last_room
        bne     .changed
        rts
.changed:
        sta     <rising_cloud_last_room
        stz     <rising_cloud_push
        cmp     #1
        beq     .enter_room01
        lda     #$ff
        sta     <rising_cloud_row
        rts
.enter_room01:
        call    rising_cloud_copy_room01_map
        lda     #$d9
        sta     <rising_cloud_y
        stz     <rising_cloud_tick
        lda     #$ff
        sta     <rising_cloud_row
        jmp     rising_cloud_refresh_row

rising_cloud_copy_room01_map:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<room01_collision_map_rom
        sta     <_bp
        lda     #>room01_collision_map_rom
        sta     <_bp+1
        ldy     #BANK(room01_collision_map_rom)
        call    map_bp_to_mpr34

        lda     #<room01_collision_map
        sta     <_di
        lda     #>room01_collision_map
        sta     <_di+1

        ldx     #2
        cly
.copy_page:
        lda     [_bp],y
        sta     [_di],y
        iny
        bne     .copy_page
        inc     <_bp+1
        inc     <_di+1
        dex
        bne     .copy_page

        cly
        ldx     #128
.copy_tail:
        lda     [_bp],y
        sta     [_di],y
        iny
        dex
        bne     .copy_tail

        pla
        tam4
        pla
        tam3
        plp
        rts

rising_cloud_update:
        lda     <monty_room
        cmp     #1
        beq     .room01
        rts
.room01:
        inc     <rising_cloud_tick
        lda     <rising_cloud_tick
        and     #1
        bne     .move_tick
        rts
.move_tick:
        call    rising_cloud_detect_push
        dec     <rising_cloud_y
        lda     <rising_cloud_push
        beq     .refresh
        call    rising_cloud_can_push_up
        bcs     .refresh
        dec     <monty_y
        lda     #1
        sta     <monty_is_moving
.refresh:
        jmp     rising_cloud_refresh_row

; Stateless support test. Walking changes X before this routine runs; jumping
; changes jump_phase before this routine runs, so either action releases without
; any persistent attach state.
rising_cloud_detect_push:
        stz     <rising_cloud_push
        lda     <monty_jump_phase
        bne     .done
        lda     <monty_falling
        bne     .done
        lda     <monty_x
        cmp     #$36
        bcc     .done
        cmp     #$49
        bcs     .done
        lda     <rising_cloud_y
        sec
        sbc     #$10
        sta     <rising_cloud_top_y
        cmp     <monty_y
        bne     .done
        lda     #1
        sta     <rising_cloud_push
.done:
        rts

; C=1 if moving Monty upward by one pixel would make ANY tile in his complete
; prospective footprint overlap a property-1 solid. Unlike CheckTileAbove this
; deliberately does not depend on an 8px alignment gate. This is needed for a
; moving platform because a ceiling row can enter the middle of the footprint.
rising_cloud_can_push_up:
        lda     <monty_y
        sec
        sbc     #1
        sec
        sbc     #$32
        lsr     a
        lsr     a
        lsr     a
        sta     <rising_cloud_probe_y

        lda     <monty_x
        sec
        sbc     #$0c
        pha
        lsr     a
        lsr     a
        sta     <rising_cloud_probe_x
        pla
        and     #$03
        beq     .two_cols
        lda     #3
        bra     .store_cols
.two_cols:
        lda     #2
.store_cols:
        sta     <rising_cloud_probe_cols
        lda     #3
        sta     <rising_cloud_probe_rows

.row_loop:
        lda     <rising_cloud_probe_cols
        sta     <rising_cloud_probe_ctr
        ldx     <rising_cloud_probe_x
        ldy     <rising_cloud_probe_y
.col_loop:
        phx
        phy
        call    room00_get_property_xy
        ply
        plx
        cmp     #$01
        beq     .blocked
        inx
        dec     <rising_cloud_probe_ctr
        bne     .col_loop
        inc     <rising_cloud_probe_y
        dec     <rising_cloud_probe_rows
        bne     .row_loop
        clc
        rts
.blocked:
        sec
        rts

rising_cloud_refresh_row:
        lda     <rising_cloud_y
        cmp     #$da
        bcs     .no_new_row
        cmp     #$52
        bcc     .no_new_row
        sec
        sbc     #$32
        lsr     a
        lsr     a
        lsr     a
        sec
        sbc     #3
        cmp     <rising_cloud_row
        bne     .replace_row
        rts

.no_new_row:
        lda     <rising_cloud_row
        cmp     #$ff
        beq     .row_done
        call    rising_cloud_clear_row
        lda     #$ff
        sta     <rising_cloud_row
.row_done:
        rts

.replace_row:
        sta     <rising_cloud_tmp_row
        lda     <rising_cloud_row
        cmp     #$ff
        beq     .set_new
        call    rising_cloud_clear_row
.set_new:
        lda     <rising_cloud_tmp_row
        sta     <rising_cloud_row
        jmp     rising_cloud_set_row

rising_cloud_clear_row:
        sta     <rising_cloud_tmp_row
        tax
        lda     #<room01_collision_map
        clc
        adc     rising_cloud_row_lo,x
        sta     <_di
        lda     #>room01_collision_map
        adc     rising_cloud_row_hi,x
        sta     <_di+1
        ldy     #8
        cla
        sta     [_di],y
        iny
        sta     [_di],y
        iny
        sta     [_di],y

        lda     <rising_cloud_tmp_row
        tax
        lda     rising_cloud_bat_lo,x
        sta     <_di
        lda     rising_cloud_bat_hi,x
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #3
.clear_word:
        lda     #<CHR_GAME
        sta     VDC_DL
        lda     #>CHR_GAME
        sta     VDC_DH
        dex
        bne     .clear_word
        rts

rising_cloud_set_row:
        tax
        lda     #<room01_collision_map
        clc
        adc     rising_cloud_row_lo,x
        sta     <_di
        lda     #>room01_collision_map
        adc     rising_cloud_row_hi,x
        sta     <_di+1
        ldy     #8
        lda     #CLOUD_CODE
        sta     [_di],y
        iny
        sta     [_di],y
        iny
        sta     [_di],y

        lda     <rising_cloud_row
        tax
        lda     rising_cloud_bat_lo,x
        sta     <_di
        lda     rising_cloud_bat_hi,x
        sta     <_di+1
        call    vdc_di_to_mawr
        ldx     #3
.draw_word:
        lda     #<CLOUD_BAT_WORD
        sta     VDC_DL
        lda     #>CLOUD_BAT_WORD
        sta     VDC_DH
        dex
        bne     .draw_word
        rts

.data
rising_cloud_row_lo:
        db $00,$20,$40,$60,$80,$a0,$c0,$e0,$00,$20,$40,$60,$80,$a0,$c0,$e0,$00,$20,$40,$60
rising_cloud_row_hi:
        db $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02

rising_cloud_bat_lo:
        db <(3*BAT_LINE+CLOUD_VIS_COL),<(4*BAT_LINE+CLOUD_VIS_COL),<(5*BAT_LINE+CLOUD_VIS_COL),<(6*BAT_LINE+CLOUD_VIS_COL)
        db <(7*BAT_LINE+CLOUD_VIS_COL),<(8*BAT_LINE+CLOUD_VIS_COL),<(9*BAT_LINE+CLOUD_VIS_COL),<(10*BAT_LINE+CLOUD_VIS_COL)
        db <(11*BAT_LINE+CLOUD_VIS_COL),<(12*BAT_LINE+CLOUD_VIS_COL),<(13*BAT_LINE+CLOUD_VIS_COL),<(14*BAT_LINE+CLOUD_VIS_COL)
        db <(15*BAT_LINE+CLOUD_VIS_COL),<(16*BAT_LINE+CLOUD_VIS_COL),<(17*BAT_LINE+CLOUD_VIS_COL),<(18*BAT_LINE+CLOUD_VIS_COL)
        db <(19*BAT_LINE+CLOUD_VIS_COL),<(20*BAT_LINE+CLOUD_VIS_COL),<(21*BAT_LINE+CLOUD_VIS_COL),<(22*BAT_LINE+CLOUD_VIS_COL)
rising_cloud_bat_hi:
        db >(3*BAT_LINE+CLOUD_VIS_COL),>(4*BAT_LINE+CLOUD_VIS_COL),>(5*BAT_LINE+CLOUD_VIS_COL),>(6*BAT_LINE+CLOUD_VIS_COL)
        db >(7*BAT_LINE+CLOUD_VIS_COL),>(8*BAT_LINE+CLOUD_VIS_COL),>(9*BAT_LINE+CLOUD_VIS_COL),>(10*BAT_LINE+CLOUD_VIS_COL)
        db >(11*BAT_LINE+CLOUD_VIS_COL),>(12*BAT_LINE+CLOUD_VIS_COL),>(13*BAT_LINE+CLOUD_VIS_COL),>(14*BAT_LINE+CLOUD_VIS_COL)
        db >(15*BAT_LINE+CLOUD_VIS_COL),>(16*BAT_LINE+CLOUD_VIS_COL),>(17*BAT_LINE+CLOUD_VIS_COL),>(18*BAT_LINE+CLOUD_VIS_COL)
        db >(19*BAT_LINE+CLOUD_VIS_COL),>(20*BAT_LINE+CLOUD_VIS_COL),>(21*BAT_LINE+CLOUD_VIS_COL),>(22*BAT_LINE+CLOUD_VIS_COL)
