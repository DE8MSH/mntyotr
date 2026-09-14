; Authentic C64 room collectibles for the complete $00-$33 room set.
; The original RoomEntitiesInit draws char $34 for these records and CollectCoin
; permanently marks a touched record collected while awarding 50 points.
;
; PCE rendering uses one dedicated 8x8 BG tile. Coordinates are precomputed
; directly from FreedomKit.Data.item_tbl:
;   target_x = $15 + 4*col
;   target_y = $4c + 8*row
;   BAT      = (row+3)*64 + (col+4)

GEM_RECORD_COUNT = 64
; Current room/decor graphics use CHR_GAME+0..+65. Dynamic piledriver graphics
; start at CHR_GAME+96, so +80 is a stable dedicated slot for collectibles.
GEM_CHR          = CHR_GAME + 80
GEM_BAT_LO       = <GEM_CHR
; Initial colour is C64 red, palette slot 2. Runtime cycles the BAT palette nibble
; through the original 11-step CharacterAnimation sequence.
GEM_BAT_HI       = $20 | >GEM_CHR

.bss
gem_collected:       ds GEM_RECORD_COUNT
gem_total:           ds 1
gem_scan_index:      ds 1
gem_record_offset:   ds 1
gem_target_x:        ds 1
gem_target_y:        ds 1
gem_anim_step:       ds 1
gem_palette_hi:      ds 1

.code

.proc gem_init
        stz     gem_total
        stz     gem_anim_step
        ldx     #GEM_RECORD_COUNT-1
.clear:
        stz     gem_collected,x
        dex
        bpl     .clear
        call    gem_upload_pattern
        leave
.endp

; Upload the original C64 char $34 converted to one PCE 4bpp BG tile.
.proc gem_upload_pattern
        php
        sei
        tma3
        pha
        tma4
        pha
        lda     #<gem_tile_pattern
        sta     <_bp
        lda     #>gem_tile_pattern
        sta     <_bp+1
        ldy     #BANK(gem_tile_pattern)
        call    map_bp_to_mpr34

        lda     #<(GEM_CHR*16)
        sta     <_di
        lda     #>(GEM_CHR*16)
        sta     <_di+1
        call    vdc_di_to_mawr
        cly
        ldx     #16
.word:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .word

        pla
        tam4
        pla
        tam3
        plp
        leave
.endp

; Redraw all uncollected gems belonging to monty_room. Call after every room
; load, including same-room death reloads, because the room BAT was rebuilt.
.proc gem_draw_room
        php
        sei
        tma3
        pha
        tma4
        pha
        lda     #<gem_records
        sta     <_bp
        lda     #>gem_records
        sta     <_bp+1
        ldy     #BANK(gem_records)
        call    map_bp_to_mpr34

        stz     gem_scan_index
        stz     gem_record_offset
.scan:
        ldx     gem_scan_index
        cpx     #GEM_RECORD_COUNT
        beq     .done
        lda     gem_collected,x
        bne     .next

        ldy     gem_record_offset
        lda     [_bp],y
        cmp     <monty_room
        bne     .next
        iny
        iny
        iny
        lda     [_bp],y
        sta     <_di
        iny
        lda     [_bp],y
        sta     <_di+1
        call    vdc_di_to_mawr
        lda     #GEM_BAT_LO
        sta     VDC_DL
        lda     #GEM_BAT_HI
        sta     VDC_DH
.next:
        lda     gem_record_offset
        clc
        adc     #5
        sta     gem_record_offset
        inc     gem_scan_index
        bra     .scan
.done:
        pla
        tam4
        pla
        tam3
        plp
        leave
.endp

; Original CharacterAnimation colour cycle:
; red,purple,purple,light-red,yellow,white,white,yellow,light-red,purple,purple.
; The PCE already has those C64 colours in BG palette slots 2,13,10,8,7, so
; animation only changes each gem's BAT palette nibble and touches no CRAM data.
.proc gem_animate_room
        inc     gem_anim_step
        lda     gem_anim_step
        cmp     #11
        bcc     .step_ok
        stz     gem_anim_step
.step_ok:
        lda     gem_anim_step
        beq     .red
        cmp     #3
        bcc     .purple
        beq     .light_red
        cmp     #4
        beq     .yellow
        cmp     #7
        bcc     .white
        beq     .yellow
        cmp     #8
        beq     .light_red
        bra     .purple
.red:
        lda     #($20 | >GEM_CHR)
        bra     .have_palette
.purple:
        lda     #($d0 | >GEM_CHR)
        bra     .have_palette
.light_red:
        lda     #($a0 | >GEM_CHR)
        bra     .have_palette
.yellow:
        lda     #($80 | >GEM_CHR)
        bra     .have_palette
.white:
        lda     #($70 | >GEM_CHR)
.have_palette:
        sta     gem_palette_hi

        php
        sei
        tma3
        pha
        tma4
        pha
        lda     #<gem_records
        sta     <_bp
        lda     #>gem_records
        sta     <_bp+1
        ldy     #BANK(gem_records)
        call    map_bp_to_mpr34
        stz     gem_scan_index
        stz     gem_record_offset
.scan:
        ldx     gem_scan_index
        cpx     #GEM_RECORD_COUNT
        beq     .done
        lda     gem_collected,x
        bne     .next
        ldy     gem_record_offset
        lda     [_bp],y
        cmp     <monty_room
        bne     .next
        iny
        iny
        iny
        lda     [_bp],y
        sta     <_di
        iny
        lda     [_bp],y
        sta     <_di+1
        call    vdc_di_to_mawr
        lda     #GEM_BAT_LO
        sta     VDC_DL
        lda     gem_palette_hi
        sta     VDC_DH
.next:
        lda     gem_record_offset
        clc
        adc     #5
        sta     gem_record_offset
        inc     gem_scan_index
        bra     .scan
.done:
        pla
        tam4
        pla
        tam3
        plp
        leave
.endp

; Per gameplay tick: animate/touch an active gem, remove it, remember it globally
; and award the exact original coin value (A=5,Y=3 => +50).
.proc gem_update
        call    gem_animate_room

        php
        sei
        tma3
        pha
        tma4
        pha
        lda     #<gem_records
        sta     <_bp
        lda     #>gem_records
        sta     <_bp+1
        ldy     #BANK(gem_records)
        call    map_bp_to_mpr34

        stz     gem_scan_index
        stz     gem_record_offset
.scan:
        ldx     gem_scan_index
        cpx     #GEM_RECORD_COUNT
        beq     .done
        lda     gem_collected,x
        bne     .next

        ldy     gem_record_offset
        lda     [_bp],y
        cmp     <monty_room
        bne     .next

        iny
        lda     [_bp],y
        sta     gem_target_x
        sec
        sbc     #5
        cmp     <monty_x
        bcs     .next
        lda     gem_target_x
        clc
        adc     #5
        cmp     <monty_x
        bcc     .next

        iny
        lda     [_bp],y
        sta     gem_target_y
        sec
        sbc     #10
        cmp     <monty_y
        bcs     .next
        lda     gem_target_y
        clc
        adc     #10
        cmp     <monty_y
        bcc     .next

        ; Persist collection and award 50 points.
        ldx     gem_scan_index
        lda     #$ff
        sta     gem_collected,x
        inc     gem_total
        lda     #5
        ldy     #3
        call    score_increase

        ; Original clears the collectible character to blank on pickup.
        ldy     gem_record_offset
        iny
        iny
        iny
        lda     [_bp],y
        sta     <_di
        iny
        lda     [_bp],y
        sta     <_di+1
        call    vdc_di_to_mawr
        lda     #<CHR_GAME
        sta     VDC_DL
        lda     #>CHR_GAME
        sta     VDC_DH
        bra     .done

.next:
        lda     gem_record_offset
        clc
        adc     #5
        sta     gem_record_offset
        inc     gem_scan_index
        jmp     .scan
.done:
        pla
        tam4
        pla
        tam3
        plp
        leave
.endp
