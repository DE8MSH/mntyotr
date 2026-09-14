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
; Room/decor graphics currently occupy CHR_GAME+0..+65. The two standard
; piledriver sets occupy +64..+99 and the static piledriver sets occupy
; +96..+131, so the old +80 gem slot was being overwritten during gameplay
; (visible as number-like garbage instead of the original char $34). Keep the
; collectible in the first BG slot above all of those dynamic allocations.
GEM_CHR          = CHR_GAME + 132
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
;
; The C64 does NOT use an arbitrary pixel-distance box here. CollectCoin scans
; the four screen characters covered by the top two rows of Monty's 2x3 char
; footprint (tile_2col_row_offsets[0..3]) for char $34. Recreate that geometry
; directly: convert the source item col/row back from the stored target values,
; convert Monty's internal coordinates to his top-left screen character, and
; accept only a 2x2 character overlap. This keeps pickup collision aligned with
; the visibly drawn gem and cannot drift several pixels into a wall.
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
        bne     .scan_active
        jmp     .done
.scan_active:
        lda     gem_collected,x
        beq     .scan_room
        jmp     .next
.scan_room:
        ldy     gem_record_offset
        lda     [_bp],y
        cmp     <monty_room
        beq     .room_match
        jmp     .next
.room_match:

        ; Stored target_x = $15 + 4*source_col. Recover the item's absolute
        ; C64 screen column (source_col + 4).
        iny
        lda     [_bp],y
        sec
        sbc     #$15
        lsr     a
        lsr     a
        clc
        adc     #4
        sta     gem_target_x

        ; Monty screen-left column = (monty_x-$0c)/4. Original CollectCoin
        ; examines that column and the next one.
        lda     <monty_x
        sec
        sbc     #$0c
        lsr     a
        lsr     a
        cmp     gem_target_x
        beq     .x_hit
        clc
        adc     #1
        cmp     gem_target_x
        beq     .x_hit
        jmp     .next
.x_hit:
        ; Stored target_y = $4c + 8*source_row. Recover absolute screen row
        ; (source_row + 3), then compare against Monty's top two char rows.
        ldy     gem_record_offset
        iny
        iny
        lda     [_bp],y
        sec
        sbc     #$4c
        lsr     a
        lsr     a
        lsr     a
        clc
        adc     #3
        sta     gem_target_y

        lda     <monty_y
        inc     a
        sec
        sbc     #$32
        lsr     a
        lsr     a
        lsr     a
        cmp     gem_target_y
        beq     .collect
        clc
        adc     #1
        cmp     gem_target_y
        beq     .collect
        jmp     .next

.collect:
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
