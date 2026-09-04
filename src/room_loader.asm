; Phase 33c room loader: real C64 world transition, rooms $00 <-> $01.
; Room graphics and collision data are copied through MPR3/MPR4 so ROM-bank
; placement cannot corrupt gameplay as the HuCard grows.

.zp
room_copy_rows:  ds 1
room_copy_pages: ds 1

.bss
room_collision_map_ram:  ds 640
room_tile_properties_ram: ds 8

.code

; C=1 when a supported pending room was committed.
room_load_pending:
        lda     <world_pending_room
        beq     .room00
        cmp     #1
        beq     .room01
        clc
        rts

.room00:
        jsr     room_collision_load_pending
        call    upload_room00_patterns
        call    draw_room00_native
        stz     <monty_room
        stz     <world_transition_ready
        sec
        rts

.room01:
        jsr     room_collision_load_pending
        jsr     room01_upload_patterns
        jsr     room01_upload_decor
        jsr     room01_draw_native
        lda     #1
        sta     <monty_room
        stz     <world_transition_ready
        sec
        rts

; Copy the active room's 32x20 collision map and eight C64 tile properties into
; work RAM. Physics then reads only RAM, so adding ROM data can never move these
; tables out of the currently mapped HuCard bank again.
room_collision_load_pending:
        lda     <world_pending_room
        beq     .room00
        cmp     #1
        beq     .room01
        rts
.room00:
        lda     #<room00_collision_map
        sta     <_bp
        lda     #>room00_collision_map
        sta     <_bp+1
        ldy     #BANK(room00_collision_map)
        jsr     room_collision_copy640
        lda     #<room00_tile_properties
        sta     <_bp
        lda     #>room00_tile_properties
        sta     <_bp+1
        ldy     #BANK(room00_tile_properties)
        jmp     room_collision_copy_props
.room01:
        lda     #<room01_collision_map
        sta     <_bp
        lda     #>room01_collision_map
        sta     <_bp+1
        ldy     #BANK(room01_collision_map)
        jsr     room_collision_copy640
        lda     #<room01_tile_properties
        sta     <_bp
        lda     #>room01_tile_properties
        sta     <_bp+1
        ldy     #BANK(room01_tile_properties)
        jmp     room_collision_copy_props

; Input: _bp=ROM source, Y=source bank. Copies 640 bytes to RAM.
; IMPORTANT: use CALL for map_bp_to_mpr34, matching the proven sprite upload
; path. The helper is supplied by HuC and may live outside the caller's bank;
; plain JSR is not a safe substitute once the ROM layout grows.
room_collision_copy640:
        php
        sei
        tma3
        pha
        tma4
        pha
        call    map_bp_to_mpr34

        lda     #<room_collision_map_ram
        sta     <_di
        lda     #>room_collision_map_ram
        sta     <_di+1
        lda     #2
        sta     <room_copy_pages
.page:
        cly
.byte:
        lda     [_bp],y
        sta     [_di],y
        iny
        bne     .byte
        inc     <_bp+1
        inc     <_di+1
        dec     <room_copy_pages
        bne     .page

        cly
.tail:
        lda     [_bp],y
        sta     [_di],y
        iny
        cpy     #128
        bne     .tail

        pla
        tam4
        pla
        tam3
        plp
        rts

; Input: _bp=ROM source, Y=source bank. Copies 8 property bytes to RAM.
room_collision_copy_props:
        php
        sei
        tma3
        pha
        tma4
        pha
        call    map_bp_to_mpr34
        ldx     #0
        cly
.loop:
        lda     [_bp],y
        sta     room_tile_properties_ram,x
        iny
        inx
        cpx     #8
        bne     .loop
        pla
        tam4
        pla
        tam3
        plp
        rts

; Upload 9*32 = 288 bytes to the same custom-char VRAM used by every room.
room01_upload_patterns:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<room01_patterns
        sta     <_bp
        lda     #>room01_patterns
        sta     <_bp+1
        ldy     #BANK(room01_patterns)
        call    map_bp_to_mpr34

        lda     #<(CHR_GAME*16)
        sta     <_di
        lda     #>(CHR_GAME*16)
        sta     <_di+1
        call    vdc_di_to_mawr

        cly
        ldx     #128
.p0:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .p0
        inc     <_bp+1
        cly
        ldx     #16
.p1:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .p1

        pla
        tam4
        pla
        tam3
        plp
        rts

; Phase 33: 25 exact C64 decor chars = 800 bytes, beginning at CHR_GAME+9.
room01_upload_decor:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<room01_decor_patterns
        sta     <_bp
        lda     #>room01_decor_patterns
        sta     <_bp+1
        ldy     #BANK(room01_decor_patterns)
        call    map_bp_to_mpr34

        lda     #<((CHR_GAME+9)*16)
        sta     <_di
        lda     #>((CHR_GAME+9)*16)
        sta     <_di+1
        call    vdc_di_to_mawr

        lda     #3
        sta     <room_copy_pages
.full_page:
        cly
        ldx     #128
.full_word:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .full_word
        inc     <_bp+1
        dec     <room_copy_pages
        bne     .full_page

        cly
        ldx     #16
.tail_word:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .tail_word

        pla
        tam4
        pla
        tam3
        plp
        rts

; Draw the exact 36x20 visible room window at C64 cols 2..37, rows 3..22.
room01_draw_native:
        php
        sei
        tma3
        pha
        tma4
        pha

        lda     #<room01_screen_bat
        sta     <_bp
        lda     #>room01_screen_bat
        sta     <_bp+1
        ldy     #BANK(room01_screen_bat)
        call    map_bp_to_mpr34

        lda     #<((3)*BAT_LINE+ROOM_X)
        sta     <_di
        lda     #>((3)*BAT_LINE+ROOM_X)
        sta     <_di+1
        lda     #20
        sta     <room_copy_rows
.row:
        call    vdc_di_to_mawr
        cly
        ldx     #36
.word:
        lda     [_bp],y
        sta     VDC_DL
        iny
        lda     [_bp],y
        sta     VDC_DH
        iny
        dex
        bne     .word

        lda     <_bp
        clc
        adc     #72
        sta     <_bp
        bcc     .src_ok
        inc     <_bp+1
.src_ok:
        lda     <_di
        clc
        adc     #BAT_LINE
        sta     <_di
        bcc     .dst_ok
        inc     <_di+1
.dst_ok:
        dec     <room_copy_rows
        bne     .row

        pla
        tam4
        pla
        tam3
        plp
        rts
