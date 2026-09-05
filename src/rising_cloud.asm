; Phase 50: Room $01 rising cloud aligned with the original C64 routine.
;
; Original C64 SpecialItems.UpdateRisingCloud does NOT move Monty directly.
; It only:
;   - advances cloud_tick,
;   - moves the cloud sprite up by 1px on odd ticks,
;   - writes code $08/property-3 into screen columns $0C-$0E,
;   - clears the trail row below.
;
; Monty's own movement/collision runs before UpdateRisingCloud in the original
; frame order. Therefore this module never writes monty_y and can never create
; an UP room exit by pushing Monty through a ceiling.
;
; The only PCE-specific adaptation retained is rising_cloud_support_update:
; because our generic property-3 footprint scan can otherwise make the cloud
; behave like a ladder, exact cloud support is separated from monty_tile_state
; while preserving normal jump/left/right input.

CLOUD_OFFSCREEN_ROW = $ff
CLOUD_VIS_COL       = 12
CLOUD_CODE          = 8
CLOUD_PAL           = 12
CLOUD_BAT_WORD      = $c000+CHR_GAME+CLOUD_CODE

.zp
rising_cloud_last_room: ds 1
rising_cloud_y:         ds 1
rising_cloud_tick:      ds 1
rising_cloud_row:       ds 1
rising_cloud_support:   ds 1
rising_cloud_tmp_row:   ds 1

.code

rising_cloud_init:
        lda     #$ff
        sta     <rising_cloud_last_room
        sta     <rising_cloud_row
        lda     #$d9
        sta     <rising_cloud_y
        stz     <rising_cloud_tick
        stz     <rising_cloud_support
        rts

rising_cloud_room_sync:
        lda     <monty_room
        cmp     <rising_cloud_last_room
        bne     .changed
        rts
.changed:
        sta     <rising_cloud_last_room
        stz     <rising_cloud_support
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

; PCE adaptation only: report exact support without turning the moving cloud
; into a climbable property-3 ladder. This routine never moves Monty.
rising_cloud_support_update:
        stz     <rising_cloud_support
        lda     <monty_room
        cmp     #1
        bne     .done
        lda     <rising_cloud_y
        cmp     #$da
        bcs     .done
        cmp     #$52
        bcc     .done
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
        cmp     <monty_y
        bne     .done
        lda     #1
        sta     <rising_cloud_support
        stz     <monty_tile_state
.done:
        rts

; Exact original ordering inside UpdateRisingCloud: cloud tick changes first;
; only odd ticks move sprite Y. Monty position is never touched here.
rising_cloud_update:
        lda     <monty_room
        cmp     #1
        beq     .room01
        rts
.room01:
        inc     <rising_cloud_tick
        lda     <rising_cloud_tick
        and     #1
        beq     .refresh
        dec     <rising_cloud_y
.refresh:
        jmp     rising_cloud_refresh_row

; Convert C64 sprite Y into the logical row receiving code $08. $D9 maps to
; row17; $52 maps to row1. Once Y<$52 the original clears the top visible row.
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