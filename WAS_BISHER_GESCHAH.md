# Was bisher geschah

Stand: 2026-09-04 — Phase 33a

## Portierungsstand

**Gesamtport: ca. 45 %**

Phase 32b ist vom Nutzer praktisch bestaetigt: Raum $00 -> $01 nach links funktioniert, und aus Raum $01 kommt Monty nach rechts wieder korrekt in Raum $00 zurueck. Dass man aus Raum $00 nicht nach rechts in einen weiteren Raum gelangt, ist kein Fehler: im originalen 6x23-Weltgitter ist rechts neben Raum $00 (`row 2, col $16`) `$ff`, also eine Wand/kein Raum.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- Raum $00 Basisgrafik und alle neun statischen Decor-Records sind sichtbar; `sad_flowers` wurde bestaetigt.
- Gehen, Springen, Falling, Plattform-Landung und Hauseingang funktionieren.
- 12+12 Somersaultframes sowie Walk/Climb laufen ueber bankfeste ROM-Uploads.
- Der echte Raumwechsel $00 -> $01 nach links funktioniert.
- Der Rueckweg $01 -> $00 nach rechts funktioniert.
- Rechts von Raum $00 liegt laut Original-Weltkarte `$ff`; dort darf kein weiterer Raum geladen werden.

## Phase 33 — Original-Decors fuer Raum $01

Die C64-`Decor.room_list` enthaelt fuer Raum $01 exakt zwei statische Records:

- `$01,$03,$11,$42` — Type 66 `purple_flowers`, 4x4 Zeichen
- `$01,$1d,$07,$41` — Type 65 `bunch_flower`, 3x3 Zeichen

`tools/room01_decor.py` portiert beide direkt aus `refactored/src/subsystems/decor_data.asm`.

### Type $42 `purple_flowers`

- 4x4 = 16 C64-Zeichen
- exaktes 128-Byte-Bitmap aus `chr_data.purple_flowers`
- Farbstrom: `$04,$04,$04,$04,$04,$05,$05,$04,$05,$05,$05,$05,$08,$08,$08,$08`

### Type $41 `bunch_flower`

- 3x3 = 9 C64-Zeichen
- exaktes 72-Byte-Bitmap aus `chr_data.bunch_flower`
- Farbstrom: `$07,$08,$03,$0a,$05,$04,$08,$02,$00`

Zusammen erzeugt Phase 33 25 PCE-Decor-Zeichen = 800 Byte. Sie beginnen wie die Raum-$00-Decors bei `CHR_GAME+9`; ein Raumwechsel darf diese gemeinsamen Decor-Slots bewusst ueberschreiben.

Die vorhandenen PCE-Paletten reichen aus. Purple `$04` verwendet Room-$01-Slot 13; die restlichen Farben sind bereits durch Raum $00 bzw. die Basisraumfarben vorhanden.

## Phase 33a — PCEAS Reichweitenfix im Room-Loader

Beim ersten lokalen Phase-33-Build liefen alle Python-Regressionstests erfolgreich durch, inklusive Room-$01-Decor. PCEAS stoppte danach in `src/room_loader.asm` bei:

`bsr room01_draw_native` — Branch address out of range.

Die Room-$01-Routine ist durch den neuen 800-Byte-Decor-Upload inzwischen zu gross fuer relative `BSR`-Aufrufe aus `room_load_pending`. Phase 33a stellt deshalb alle drei Room-$01-Subroutine-Aufrufe auf absolute `JSR` um:

- `room01_upload_patterns`
- `room01_upload_decor`
- `room01_draw_native`

Die Loader-, Grafik- und Raumwechsel-Semantik bleibt unveraendert; nur die HuC6280-Reichweitenabhaengigkeit ist entfernt.

## Loader/Build

`src/room01_assets.asm` bindet `room01-decor-patterns.dat` ein. `src/room_loader.asm` laedt beim Eintritt in Raum $01 zuerst die neun Custom-Tiles und danach die 25 Decor-Zeichen bankfest ueber `map_bp_to_mpr34`. Der von `tools/room01.py` erzeugte 36x20-BAT wird vor dem Assemblieren durch `tools/room01_decor.py` mit den beiden Original-Records ueberlagert.

`tools/test_room01_decor.py` prueft beide Originalpositionen, die komplette Zeichenreihenfolge und jeden Eintrag der beiden C64-Farbstroeme. `build.sh` fuehrt den Test aus und erzeugt die Decor-Patterns vor PCEAS.

## Verifikationsstatus

- Phase 32b Raumwechsel $00 <-> $01 ist vom Nutzer bestaetigt.
- Beim ersten Phase-33-Lauf liefen alle Python-Tests durch; PCEAS stoppte nur am relativen `BSR room01_draw_native`.
- Phase 33a behebt diesen Assemblerfehler und ist hochgeladen, aber noch nicht lokal mit dem Nutzer-PCEAS verifiziert.
- Nach `git pull && ./build.sh` in Raum $01 besonders nach `purple_flowers` und `bunch_flower` schauen.
- Physik, Weltkoordinaten und Monty-Animation wurden in Phase 33/33a nicht geaendert.

## Naechste Portschritte

1. Phase 33a lokal bauen und die zwei Raum-$01-Decors visuell bestaetigen.
2. Raum $02 mit seinem exakten RLE, room_defs-Tileset, Farben und Collision in den Loader aufnehmen.
3. Danach Room-$02-Decors anbinden und die temporaere Loader-Schranke auf `$00..$02` erweitern.
4. Den Room-Loader weiter verallgemeinern.
5. Gegner, Mechanismen, Items, HUD/Gameflow und Audio folgen auf dem Mehrraum-Unterbau.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
