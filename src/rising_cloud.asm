; Phase 50: Room $01 rising cloud collision + rider carry.
;
; C64 SpecialItems.UpdateRisingCloud:
;   - active only in Room $01
;   - fixed screen columns $0C-$0E (logical room cols 8..10)
;   - moves upward one pixel on odd logical ticks
;   - writes screen code $08 (Room01 tile $64 / property 3) into its row
;   - clears the row below as the cloud rises
;
; Phase50 rider rule: landing is detected separately by rising_cloud_contact.asm.
; Carry then uses an explicit riding flag and exact cloud-top geometry rather
; than the broad property-3/tile-state heuristic that could make Monty feel glued.

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
rising_cloud_carry:     ds 1
rising_cloud_riding:    ds 1
rising_cloud_tmp_row:   ds 1
rising_cloud_top_y:     ds 1

.code

rising_cloud_init:
        lda     #$ff
        sta     <rising_cloud_last_room
        sta     <rising_cloud_row
        lda     #$d9
        sta     <rising_cloud_y
        stz     <rising_cloud_tick
        stz     <rising_cloud_carry
        stz     <rising_cloud_riding
        rts

rising_cloud_room_sync:
        lda     <monty_room
        cmp     <rising_cloud_last_room
        bne     .changed
        rts
.changed:
        sta     <rising_cloud_last_room
        stz     <rising_cloud_riding
        stz     <rising_cloud_carry
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

rising_cloud_update:
        lda     <monty_room
        cmp     #1
        beq     .room01
        stz     <rising_cloud_riding
        rts
.room01:
        inc     <rising_cloud_tick
        lda     <rising_cloud_tick
        and     #1
        bne     .move_tick
        ; Even ticks still validate attachment so walking/jumping releases
        ; immediately instead of waiting for the next cloud movement tick.
        call    rising_cloud_detect_carry
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

; Carry only a rider created by rising_cloud_contact_update, and only while the
; player still stands exactly on cloud_y-$10. Jumping/falling or leaving the
; horizontal footprint clears the attachment immediately. No tile_state test is
; used here, so the moving room character cannot re-attach Monty by itself.
rising_cloud_detect_carry:
        stz     <rising_cloud_carry
        lda     <rising_cloud_riding
        bne     .check_motion
        rts
.check_motion:
        lda     <monty_jump_phase
        beq     .check_fall
        stz     <rising_cloud_riding
        rts
.check_fall:
        lda     <monty_falling
        beq     .check_x
        stz     <rising_cloud_riding
        rts
.check_x:
        lda     <monty_x
        cmp     #$36
        bcc     .release
        cmp     #$49
        bcs     .release

        lda     <rising_cloud_y
        sec
        sbc     #$10
        sta     <rising_cloud_top_y
        cmp     <monty_y
        bne     .release

        lda     #1
        sta     <rising_cloud_carry
        rts
.release:
        stz     <rising_cloud_riding
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
