; Startup-only palette transfer. Keep this out of Bank 0 so --newproc thunks have room.
.code
.proc init_game_palettes
        stz     <_al
        lda     #13
        sta     <_ah
        lda     #<room00_bg_palettes
        sta     <_bp + 0
        lda     #>room00_bg_palettes
        sta     <_bp + 1
        ldy     #^room00_bg_palettes
        call    load_palettes

        lda     #13
        sta     <_al
        lda     #2
        sta     <_ah
        lda     #<room01_extra_palettes
        sta     <_bp + 0
        lda     #>room01_extra_palettes
        sta     <_bp + 1
        ldy     #^room01_extra_palettes
        call    load_palettes

        lda     #15
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<room03_extra_palette
        sta     <_bp + 0
        lda     #>room03_extra_palette
        sta     <_bp + 1
        ldy     #^room03_extra_palette
        call    load_palettes

        lda     #16
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<monty_sprite_palette
        sta     <_bp + 0
        lda     #>monty_sprite_palette
        sta     <_bp + 1
        ldy     #^monty_sprite_palette
        call    load_palettes

        lda     #17
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<moving_lift_palette
        sta     <_bp + 0
        lda     #>moving_lift_palette
        sta     <_bp + 1
        ldy     #^moving_lift_palette
        call    load_palettes

        lda     #18
        sta     <_al
        lda     #1
        sta     <_ah
        lda     #<rising_cloud_sprite_palette
        sta     <_bp + 0
        lda     #>rising_cloud_sprite_palette
        sta     <_bp + 1
        ldy     #^rising_cloud_sprite_palette
        call    load_palettes
        call    xfer_palettes
        leave
.endp
