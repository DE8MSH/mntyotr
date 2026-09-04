# Was bisher geschah

Stand: 2026-09-04 — Phase 31

## Portierungsstand

**Gesamtport: ca. 42 %**

Der Nutzer hat Phase 30a visuell bestaetigt: der Rechtslauf-Grafikfehler ist nach der bankfesten Vereinheitlichung wieder weg. Phase 31 vervollstaendigt nun den statischen Decor-Satz von Raum $00.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Basis-Raumgrafik stimmt brauchbar.
- Montys Start-/SAT-Position passt weitgehend.
- Gehen, Springen, Falling und Landen auf Plattformen funktionieren.
- Die Hauswandoeffnung in Raum $00 ist passierbar.
- Die 12+12 Somersault-/Jumpframes funktionieren visuell korrekt.
- Walk links/rechts und Climb benutzen nun ebenfalls den bankfesten Far-Pointer-Pfad; der zwischenzeitliche Rechtslauf-Grafikfehler ist laut Nutzer wieder behoben.
- Die Phase-29/30-Decors sind sichtbar; der Nutzer sieht bereits deutlich mehr Raumobjekte.

## Phase 31 — Raum-$00-Decor komplett

Der letzte noch fehlende statische Decor-Record in Raum $00 ist Type `$43` (`sad_flowers`) bei C64-Koordinate `$21,$0f`.

Die C64-Referenz definiert Type 67 als 3x3 Zeichen. Das exakte Bitmap umfasst 72 Byte = 9 Zeichen. Der originale Farbstrom ist:

`$05,$05,$05,$05,$05,$05,$07,$0a,$08`

`tools/room00_decor.py` enthaelt jetzt auch diesen Typ und emittiert damit alle neun Raum-$00-Records in Quellreihenfolge:

- `$00,$24,$10,$00`
- `$00,$24,$0c,$01`
- `$00,$24,$08,$01`
- `$00,$22,$06,$02`
- `$00,$17,$08,$03`
- `$00,$03,$08,$04`
- `$00,$0e,$0a,$05`
- `$00,$0c,$0c,$06`
- `$00,$21,$0f,$43`

Die PCE-Decor-Allokation waechst von 32 auf 41 Zeichen. `src/room00_assets.asm` laedt daher 1312 Byte Decor-Patterns nach VRAM. Die vorhandene kompakte Palettentabelle reicht aus, weil `sad_flowers` nur bereits vorhandene C64-Farben `$05,$07,$0a,$08` benutzt.

`tools/test_room00_decor.py` prueft jetzt zusaetzlich die komplette 3x3-Position, Zeichenfolge und den exakten Farbstrom von Type `$43`. Der Build benutzt diesen Test bereits ueber den bestehenden `build.sh`-Aufruf.

## Verifikationsstatus

- Phase 30a ist vom Nutzer visuell bestaetigt.
- Phase 31 ist hochgeladen, aber noch nicht lokal mit dem Nutzer-PCEAS gebaut.
- Als naechstes `git pull && ./build.sh`.
- Danach in Raum $00 besonders das letzte 3x3-Blumenobjekt bei der rechten Raumseite pruefen.
- Physik, Collision und Monty-Animation wurden in Phase 31 nicht veraendert.

## Naechste Portschritte

1. Phase 31 lokal bauen und komplettes Raum-$00-Decor visuell bestaetigen.
2. Danach generischen Room-Loader aus `room.asm` portieren, damit die vorhandene Weltkarte echte Raumwechsel laden kann.
3. Weitere Raumdaten/Tile-Sets/Decor dann ueber denselben generischen Pfad anbinden.
4. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
