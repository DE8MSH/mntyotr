# Was bisher geschah

Stand: 2026-09-04 — Phase 29

## Portierungsstand

**Gesamtport: ca. 40 %**

Die Phase-28e-Sprunganimation ist vom Nutzer jetzt visuell bestaetigt. Phase 29 beginnt den echten C64-Decor-Pfad fuer Raum $00.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Basis-Raumgrafik stimmt laut Nutzer brauchbar.
- Montys Start-/SAT-Position passt weitgehend.
- Gehen, Springen und unsupported Falling funktionieren.
- Landen auf Plattformen funktioniert.
- Die Hauswandoeffnung in Raum $00 ist passierbar.
- Die 12+12 Somersault-/Jumpframes funktionieren nach dem bankfesten Phase-28e-Loader jetzt visuell korrekt.

## Phase 28e — Jump-Sprite-Banking bestaetigt

Die grossen Somersaultdaten werden nicht mehr mit bankunsicheren direkten `TIA monty_sault_*`-Transfers gelesen. Der Jump-Loader benutzt Far-Pointer-Tabellen und `map_bp_to_mpr34`, sodass auch Frames in spaeteren ROM-Banks und ueber Bankgrenzen hinweg korrekt nach VRAM geladen werden.

Der Nutzer hat danach bestaetigt: die Sprunganimation passt.

## Phase 29 — Raum-$00-Decor, erster echter Teil

Die C64-Referenz `decor_data.asm` enthaelt fuer Raum $00 acht Decor-Records. Die Decor-Engine interpretiert sie als `room_id,x,y,type_id`, laedt pro Type Breite/Hoehe und allokiert dessen Zeichen nur einmal pro Raum.

Phase 29 portiert zunaechst die **solid-colour** Decor-Typen aus Raum $00 exakt aus den C64-Daten:

- Type 0 `street_lamp_base`, 1x2 Zeichen, C64 Farbe $0c
- Type 1 `street_lamp_pole`, 1x4 Zeichen, C64 Farbe $0c; wird in Raum $00 zweimal verwendet
- Type 3 `window`, 3x3 Zeichen, C64 Farbe $0f
- Type 4 `mpl_st_sign`, 5x1 Zeichen, C64 Farbe $01

Dazu sind die exakten C64-8x8-Bitmaps in `tools/room00_decor.py` uebernommen. Der Generator wandelt jedes C64-Zeichen in ein PCE-8x8-4bpp-Tile, allokiert 20 PCE-Zeichen ab `CHR_GAME+9` und legt die C64-Raumkoordinaten auf das bestehende 36x20-Fenster (C64 Spalten 2..37, Zeilen 3..22) um.

Die entsprechenden Raum-$00-Records sind:

- `$00,$24,$10,$00`
- `$00,$24,$0c,$01`
- `$00,$24,$08,$01`
- `$00,$17,$08,$03`
- `$00,$03,$08,$04`

`build.sh` erzeugt nach dem Basis-RLE nun `room00-decor-patterns.dat` und ueberschreibt `room00-screen-bat.dat` mit dem Decor-Overlay. `src/room00_assets.asm` laedt die 20 neuen Zeichen sowie drei dedizierte BG-Paletten fuer C64 $0c/$0f/$01. `src/main.asm` laedt diese Paletten in BG-Slots 9..11.

Neu ist `tools/test_room00_decor.py`. Es prueft die 20-Zeichen-Allokation, die 3x3-Fensterposition, das 5x1-MPL-ST-Schild sowie die Wiederverwendung derselben Type-1-Zeichen fuer beide Lampenmast-Records.

## Noch offen im Raum-$00-Decor

Vier Raum-$00-Records benutzen patterned colour streams und sind bewusst noch nicht vorgetaescht worden:

- Type 2 `street_lamp_lamp`
- Type 5 `yellow_flower`
- Type 6 `brown_flower`
- Type 67 `sad_flowers`

Diese kommen als naechster Decor-Schritt mit ihren originalen Farbstroemen. Danach ist Raum-$00-Decor vollstaendig genug fuer den Vergleich mit dem C64-Raum.

## Verifikationsstatus

- Phase 29 ist hochgeladen.
- Lokal muss `git pull && ./build.sh` ausgefuehrt werden.
- Danach sollte Raum $00 sichtbar zusaetzliche feste Objekte zeigen: MPL-ST-Schild, Fenster und Teile der Strassenlampe.
- Physik, Collision, Startposition und die bestaetigte Jump-Animation wurden nicht veraendert.

## Naechste Portschritte

1. Phase 29 lokal bauen und die neuen Raum-$00-Decors pruefen.
2. Patterned Decor Types 2/5/6/67 inklusive originaler Colour-Streams portieren.
3. Walk/Climb auf denselben bankfesten Original-Slot-Pfad wie Somersault umstellen.
4. Danach generischer Room-Loader und echte Raumwechsel.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen danach.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
