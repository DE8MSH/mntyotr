# Was bisher geschah

Stand: 2026-09-04 — Phase 39 bestaetigt

## Portierungsstand

**Gesamtport: ca. 49 %**

Phase 39 ist vom Nutzer lokal bestaetigt. Raum $02 ist als dritter echter Raum aktiv; Gehen, Springen und Collision funktionieren dort und die originalen Room-$02-Decors laufen ebenfalls korrekt.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigter Runtime-Stand

- Raum $00 und $01 funktionieren mit Boden, Gehen, Springen, Landen und Animationen.
- Raum $01 zeigt die originalen `purple_flowers` und `bunch_flower`.
- Raum $02 ist aus Raum $01 nach links erreichbar.
- Monty kann in Raum $02 direkt nach dem Eintritt laufen und springen.
- Room-$02-Collision funktioniert mit dem RAM-Cache-Pfad.
- Die fuenf originalen Room-$02-Decors sind aktiv und lokal bestaetigt.
- Raum $02 -> $01 nach rechts funktioniert; links aus Raum $02 bleibt bis zum Port von Raum $03 gesperrt.
- Raum $00 rechts bleibt korrekt gesperrt.

## Phase 38a — stabiler Room-$02-Collision-Pfad

Room-$02-Collision und die acht Tile-Properties werden beim Raumladen aus dem ROM-Tail in einen 648-Byte-RAM-Cache kopiert. Damit muss der weit entfernte Room-$02-Assetbank nicht waehrend `monty_update_input`/`monty_jump_step` ueber MPR3/MPR4 liegen. Dieser Fix ist lokal bestaetigt.

## Phase 39 — originale Room-$02-Decors

`Decor.room_list` enthaelt fuer Raum $02 exakt fuenf Eintraege:

- `$02,$04,$0c,$19` -> type 25 `grandfather_clock`, 3x9 Zeichen, C64 brown `$09`
- `$02,$22,$0a,$08` -> type 8 `books`, 4x2 Zeichen, C64 orange `$08`
- `$02,$03,$12,$05` -> type 5 `yellow_flower`, 1x3 Zeichen, Farben `$07,$0d,$0a`
- `$02,$07,$12,$06` -> type 6 `brown_flower`, 1x3 Zeichen, Farben `$08,$05,$0a`
- `$02,$20,$11,$42` -> type 66 `purple_flowers`, 4x4 Zeichen

Die Dimensionen stammen direkt aus `Decor.props_tbl`: type 25 = 3x9/27, type 8 = 4x2/8, type 5/6 = 1x3/3, type 66 = 4x4/16. Die Bitmap- und Farbdaten sind exakt aus `decor_data.asm` uebernommen. Insgesamt werden 57 PCE-Hintergrundzeichen erzeugt; type 5 und type 6 behalten dabei wie im originalen Type-Pfad eigene Charbereiche, obwohl beide dieselben Flower-Bitmapdaten verwenden.

`tools/room02_decor.py` ueberlagert den bereits aus dem exakten Room-$02-RLE erzeugten 36x20-BAT an den originalen C64-Koordinaten und erzeugt `room02-decor-patterns.dat`.

`src/room02_assets_tail.asm` bindet die 1824 Byte Decorpatterns weiterhin nur im ROM-Tail ein. Die kritischen 640 Map-Bytes und 8 Property-Bytes bleiben direkt hintereinander, damit der bestaetigte 648-Byte-RAM-Cache unveraendert funktioniert.

`src/room02_decor_loader.asm` laedt die 57 Decorzeichen bankfest via `BANK(room02_decor_patterns)` und `map_bp_to_mpr34` in den gemeinsamen Decor-VRAM-Bereich ab `CHR_GAME+9`. Der Mapper ist nur waehrend des VRAM-Uploads aktiv und wird vor dem Gameplay wieder hergestellt.

`room_loader.asm` fuehrt beim Eintritt in Raum $02 aus: Basispatterns laden, Decorpatterns laden, dekorierten BAT zeichnen, Collision/Properties nach RAM cachen, dann `monty_room=2` setzen.

## Regressionstest

`tools/test_room02_decor.py` prueft die fuenf exakten `room_list`-Records in Originalreihenfolge, 57 generierte Char-Slots, die Objektgroessen, getrennte type-5/type-6-Charbereiche, Position/Charindex/Palette jedes Decorzeichens sowie Tail-Asset-Bindung und bankfesten Decor-Upload.

## Commits Phase 39

- `c0b3965193b0a39d82cf56de7886493560d88a18` — exakter Room-$02-Decor-Generator
- `c00c13857dbba66c41195e34cc363abd898cf8f2` — bankfester Room-$02-Decor-Uploader
- `2e8f61f6d1df3e8036878adcb44dffe53bc3f998` — Room-$02-Decor-Regressionstest
- `e301129897424322b0eeadecc81ee1f26df7740e` — Decorpattern als Room-$02-ROM-Tail-Asset
- `139e985ad4bfa6c05f91694287759cd6c3c97ccd` — Decor-Uploader in Main eingebunden
- `729f2ddcd7c00204a8bec0618be6992150e169c1` — Room-$02-Loader aktiviert Decor
- `c6150f339264ce08f38840e19be8e40fa139c42d` — Build erzeugt/testet Room-$02-Decor

## Verifikationsstatus

**Phase 39 ist lokal bestaetigt.** Room-$02-Decor, Bewegung, Sprung und Collision laufen gemeinsam stabil.

## Naechste Portschritte

1. Raum $03 mit exaktem RLE/Tiles/Farben/Properties vorbereiten und aktivieren.
2. Danach Room-$03-Decors portieren.
3. Weitere Raeume entlang der Original-Weltkarte.
4. Danach Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
