# Was bisher geschah

Stand: 2026-09-04 — Phase 30

## Portierungsstand

**Gesamtport: ca. 41 %**

Der Nutzer hat Phase 29 visuell bestaetigt (`passt`). Phase 30 erweitert Raum $00 nun um die echten patterned-colour-Decors aus der C64-Quelle.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Basis-Raumgrafik stimmt brauchbar.
- Montys Start-/SAT-Position passt weitgehend.
- Gehen, Springen, Falling und Landen auf Plattformen funktionieren.
- Die Hauswandoeffnung in Raum $00 ist passierbar.
- Die 12+12 Somersault-/Jumpframes funktionieren nach dem bankfesten Phase-28e-Loader visuell korrekt.
- Phase-29-Decors (Fenster, MPL-ST-Schild und Lampenteile) sind vom Nutzer visuell bestaetigt.

## Phase 30 — patterned Raum-$00-Decor

Die C64-Decor-Engine arbeitet pro Zeichen mit einer Farbe. Bei patterned Decors ist die Farbe deshalb ein Stream mit genau `width*height` Bytes. Phase 30 portiert drei weitere Raum-$00-Typen inklusive dieser originalen Streams:

- Type 2 `street_lamp_lamp`, 3x2 Zeichen, Stream `$0c,$0c,$0c,$07,$07,$0c`
- Type 5 `yellow_flower`, 1x3 Zeichen, Stream `$07,$0d,$0a`
- Type 6 `brown_flower`, 1x3 Zeichen, Stream `$08,$05,$0a`

Die zugehoerigen C64-Bitmaps stammen ebenfalls direkt aus `refactored/src/subsystems/decor_data.asm`. Type 5 und 6 benutzen dieselbe Bitmap, werden aber wie im C64-Allocator als getrennte Type-ID-Zeichenbereiche angelegt.

Damit emittiert `tools/room00_decor.py` nun diese acht Raum-$00-Records:

- `$00,$24,$10,$00`
- `$00,$24,$0c,$01`
- `$00,$24,$08,$01`
- `$00,$22,$06,$02`
- `$00,$17,$08,$03`
- `$00,$03,$08,$04`
- `$00,$0e,$0a,$05`
- `$00,$0c,$0c,$06`

Der einzige noch fehlende Raum-$00-Decor-Record ist Type `$43` (`sad_flowers`) bei `$21,$0f`; dessen Farbstrom wird erst nach eindeutiger Pinning-Pruefung aus der Quelle eingebaut.

## Palette-Infrastruktur

Phase 29 hatte fuer jeden Room-Screencode praktisch einen eigenen PCE-BG-Palettenslot reserviert. Das verschwendete Slots, obwohl mehrere Codes dieselbe C64-Farbe besitzen. Phase 30 kompaktiert deshalb die Basisbelegung ohne die bestaetigten Farben zu aendern:

- Palette 0: schwarz
- Palette 1: C64 braun `$09` (von Room-Codes 1 und 2 gemeinsam benutzt)
- Palette 2: C64 rot `$02`
- Palette 3: C64 cyan `$03`
- Palette 4: C64 dunkelgrau `$0b`
- Paletten 5..12: die fuer Decor benoetigten C64-Farben `$0c,$0f,$01,$07,$0d,$0a,$08,$05`

`tools/room_rle.py` schreibt jetzt diese kompakte Palettennummer in das BAT. Dadurch bleiben genug der 16 PCE-BG-Paletten fuer die originalen C64-Decor-Farbstroeme frei.

## Daten und Tests

`tools/room00_decor.py` erzeugt jetzt 32 PCE-Zeichen (1024 Byte) fuer Types 0..6 und setzt pro Decor-Zelle die richtige Palette aus dem C64-Farbstrom. `src/room00_assets.asm` laedt 1024 Byte statt 640 Byte und enthaelt die gemeinsame `room00_bg_palettes`-Tabelle. `src/main.asm` laedt diese 13 BG-Paletten in einem Schritt.

`tools/test_room00_decor.py` prueft jetzt zusaetzlich alle sechs Lampenkopf-Farben und beide dreizeiligen Blumen-Farbstroeme sowie die exakten Zeichenallokationen. `tools/test_port.py` prueft die neue kompakte Palette-Abbildung des Basisraums.

## Verifikationsstatus

- Phase 30 ist hochgeladen, aber noch nicht lokal mit dem Nutzer-PCEAS gebaut.
- Als naechstes `git pull && ./build.sh`.
- Danach besonders Lampenkopf sowie gelbe/braune Blumen in Raum $00 visuell pruefen.
- Physik, Collision, Startposition und Jump-Animation wurden nicht veraendert.

## Naechste Portschritte

1. Phase 30 lokal bauen und patterned Decors visuell pruefen.
2. Type `$43` `sad_flowers` mit eindeutig gepinntem Original-Farbstrom nachziehen.
3. Walk/Climb auf den bankfesten Original-Slot-Pfad des Somersault-Loaders vereinheitlichen.
4. Generischen Room-Loader und echte Raumwechsel anbinden.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
