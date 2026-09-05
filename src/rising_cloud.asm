; Phase 49: first real moving-room mechanism -- Room $01 rising cloud.
;
; C64 SpecialItems.UpdateRisingCloud:
;   - active only in Room $01
;   - fixed screen columns $0C-$0E (logical room cols 8..10)
;   - moves upward one pixel on odd logical ticks
;   - writes screen code $08 (Room01 tile $64 / property 3) into its row
;   - clears the row below as the cloud rises
;
; The PCE port now keeps Room01 collision in RAM, so the moving property-3 strip
; is real rather than a baked ladder. The visual first pass uses the authentic
; Room01 code-8 character in the BAT; a later sprite-art pass can add the smooth
; C64 cloud sprite without changing this collision behaviour.

CLOUD_OFFSCREEN_ROW = $ff
CLOUD_VIS_COL       = 12              ; exact C64 screen column $0C
CLOUD_CODE          = 8
CLOUD_PAL           = 12              ; Room01 code 8 uses C64 green $05

.zp
rising_cloud_last_room: ds 1
rising_cloud_y:         ds 1
rising_cloud_tick:      ds 1
rising_cloud_row:       ds 1
rising_cloud_carry:     ds 1
rising_cloud_tmp_row:   ds 1

.code

rising_cloud_init:
        lda     #$ff
        sta     <rising_cloud_last_room
        sta     <rising_cloud_row
        lda     #$d9
        sta     <rising_cloud_y
        stz     <rising_cloud_tick
        stz     <rising_cloud_carry
        rts

; Call after world/room loading while monty_room contains the real room id.
; A fresh Room01 entry restores its generated base collision map (exact source
; plus temporary access bridge), then places the cloud at the bottom of its path.
rising_cloud_room_sync:
        lda     <monty_room
        cmp     <rising_cloud_last_room
        bne     .changed
        rts
.changed:
        sta     <rising_cloud_last_room
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

; 640-byte ROM -> RAM copy. Room01 is now mutable just like the shared tail map,
; but keeps its own dedicated RAM because its cloud changes collision every run.
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
.page:
        lda     [_bp],y
        sta     [_di],y
        iny
        bne     .page
        inc     <_bp+1
        inc     <_di+1
        dex
        bne     .page

        cly
        ldx     #128
.tail:
        lda     [_bp],y
        sta     [_di],y
        iny
        dex
        bne     .tail

        pla
        tam4
        pla
        tam3
        plp
        rts

; Per logical gameplay tick. Carry detection happens before the cloud moves so
; Monty keeps the same relative position when supported by its property-3 strip.
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
        call    rising_cloud_detect_carry
        dec     <rising_cloud_y
        lda     <rising_cloud_carry
        beq     .refresh
        dec     <monty_y
        lda     #1
        sta     <monty_is_moving
.refresh:
        jmp     rising_cloud_refresh_row

; C=not used. Sets carry=1 only when Monty's two-column footprint overlaps the
; cloud columns and his feet are roughly 16 pixels above the cloud's Y, which is
; the same geometry implied by CheckTileBelow's +2 character rows.
rising_cloud_detect_carry:
        stz     <rising_cloud_carry
        lda     <monty_jump_phase
        bne     .done
        lda     <monty_falling
        bne     .done
        lda     <monty_tile_state
        beq     .done
        lda     <monty_x
        cmp     #$38
        bcc     .done
        cmp     #$48
        bcs     .done
        lda     <rising_cloud_y
        sec
        sbc     <monty_y
        cmp     #14
        bcc     .done
        cmp     #22
        bcs     .done
        lda     #1
        sta     <rising_cloud_carry
.done:
        rts

; Convert C64 pixel Y into logical Room01 row. $D9 maps to row17; $52 maps to
; row1. Below $52 and the wrapped/off-screen $DA-$FF range contain no cloud tile.
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
        beq     .done
        call    rising_cloud_clear_row
        lda     #$ff
        sta     <rising_cloud_row
.done:
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

; A = logical row 1..17. Cloud path base cells are empty in the exact room data.
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
        cly
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
        lda     #<((CLOUD_PAL<<12)+(CHR_GAME+CLOUD_CODE))
        sta     VDC_DL
        lda     #>((CLOUD_PAL<<12)+(CHR_GAME+CLOUD_CODE))
        sta     VDC_DH
        dex
        bne     .draw_word
        rts

.data
; row * 32 offsets into the 640-byte logical collision map.
rising_cloud_row_lo:
        db $00,$20,$40,$60,$80,$a0,$c0,$e0,$00,$20,$40,$60,$80,$a0,$c0,$e0,$00,$20,$40,$60
rising_cloud_row_hi:
        db $00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02

; BAT word addresses for C64 screen column $0C and logical rows 0..19
; (screen rows logical+3). Only entries 1..17 are used by the cloud.
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
