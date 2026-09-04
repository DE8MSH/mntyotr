; PC Engine VRAM layout for Monty on the Run.
; Runtime uses a 64x32 BAT with 320x224 display timing so the C64's 40
; character columns map 1:1 to 320 visible PCE pixels.

BAT_LINE        = 64
BAT_SIZE        = 64 * 32
SAT_ADDR        = BAT_SIZE

; 8x8 background tiles occupy 16 VRAM words each.
CHR_ZERO        = BAT_SIZE / 16
CHR_FONT        = CHR_ZERO + 16
CHR_ASCII_ZERO  = CHR_FONT

; Game graphics begin after the retained diagnostic-font allocation.
CHR_GAME        = CHR_FONT + 112
