; Native SNES Room $00 render bring-up.
; The generated assets are SNES-owned and are produced by snes/tools/room00_assets.py.

ROOM00_MAP_BYTES = 2048
ROOM00_CHR_BYTES = 1600
C64_PAL_BYTES    = 32
ROOM00_CHR_VRAM  = $1000       ; VRAM word address -> byte address $2000

.segment "CODE"

room00_upload:
        sep     #$20
.a8
.i16

        ; VRAM increments one word after writes to VMDATAH.
        lda     #$80
        sta     VMAIN

        ; BG1 32x32 tilemap at VRAM word $0000.
        stz     VMADDL
        stz     VMADDH
        ldx     #$0000
@map_loop:
        lda     room00_tilemap,x
        sta     VMDATAL
        inx
        lda     room00_tilemap,x
        sta     VMDATAH
        inx
        cpx     #ROOM00_MAP_BYTES
        bne     @map_loop

        ; BG1 4bpp character data at VRAM word $1000.
        lda     #<ROOM00_CHR_VRAM
        sta     VMADDL
        lda     #>ROOM00_CHR_VRAM
        sta     VMADDH
        ldx     #$0000
@chr_loop:
        lda     room00_chr,x
        sta     VMDATAL
        inx
        lda     room00_chr,x
        sta     VMDATAH
        inx
        cpx     #ROOM00_CHR_BYTES
        bne     @chr_loop

        ; One 16-colour C64-style palette in CGRAM palette 0.
        stz     CGADD
        ldx     #$0000
@pal_loop:
        lda     c64_palette,x
        sta     CGDATA
        inx
        cpx     #C64_PAL_BYTES
        bne     @pal_loop
        rts

.segment "RODATA"
room00_tilemap:
        .incbin "room00.map"
room00_tilemap_end:
room00_chr:
        .incbin "room00.chr"
room00_chr_end:
c64_palette:
        .incbin "c64.pal"
c64_palette_end:

.assert room00_tilemap_end - room00_tilemap = ROOM00_MAP_BYTES, error, "Room00 map size mismatch"
.assert room00_chr_end - room00_chr = ROOM00_CHR_BYTES, error, "Room00 CHR size mismatch"
.assert c64_palette_end - c64_palette = C64_PAL_BYTES, error, "C64 palette size mismatch"
