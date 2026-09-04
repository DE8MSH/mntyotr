# Was bisher geschah

Stand: 2026-09-04 — Phase 21

## Portierungsstand

**Gesamtport: ca. 32 %**

Die Prozentzahl bleibt vorerst konservativ, bis der neue Bildschirm-/Sprite-Stand lokal gebaut und im Emulator verifiziert ist.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- PCE VDC/VCE Bring-up und PAL-orientierter Gameplay-Scheduler.
- Monty war vor der letzten Spriteformat-Aenderung im Emulator sichtbar.
- Der Nutzer hat korrekt erkannt, dass der bisherige Raum nur ein 32x20-Rohplayfield war und nicht die C64-Screengeometrie abbildete.

## Phase 21 — C64-Screengeometrie und PCE-Spriteformat

Die verbindliche `refactored/src/subsystems/room.asm`-Referenz wurde jetzt direkt in die PCE-Datenpipeline uebernommen. `DrawRoomPlayfield` erzeugt ein 32x20-Playfield in C64-Screen-Spalten 4..35 und Zeilen 3..22; `CreatePlayfieldBorder` spiegelt pro Zeile den linken Rand nach Spalten 2..3 und den rechten Rand nach 36..37. Der PCE-Build erzeugt deshalb nun zusaetzlich eine echte 36x20-Screen-Window-BAT-Datei und zeichnet sie ab BAT-Spalte 2 / Zeile 3.

Dabei wurde ein weiterer konkreter Fehler entdeckt: `tools/room_rle.py` verwendete trotz der Phase-20-Assetkorrektur weiterhin Raumslot 0 direkt als PCE-Character/Palette 0. Das widerspricht `Room.SetupTileGraphics`: C64-Character 0 bleibt leer, die acht Raumslots 0..7 werden als Screen-Codes 1..8 installiert. Die BAT-Generierung verwendet jetzt konsequent `slot+1` fuer Pattern und Palette. Die Regressionstests pruefen diese Zuordnung und die 36-Spalten-Gutter-Geometrie.

Der zwischenzeitlich eingefuehrte interleaved PCE-Sprite-Encoder war ebenfalls falsch. Die HuC6270-Spritedaten bestehen bei einem 16x16-Cell aus vier aufeinanderfolgenden 32-Byte-Plane-Bloecken (16 16-Bit-Worte pro Plane). Der Converter ist auf dieses dokumentierte Layout zurueckgestellt. Das entspricht zugleich dem letzten Zustand, in dem Monty im Emulator sichtbar war. Die C64-Grafikquelle bleibt unveraendert `refactored/src/subsystems/monty_spr.asm`.

## Verifikationsstatus

- Host-Toolchain/startendes ROM: bestaetigt.
- Phase-21 Build: **noch lokal zu testen**.
- C64 Screen-Code 0/1..8 Zuordnung: im Generator/Test korrigiert.
- 36x20 Playfield+Gutters: im Generator/Renderer umgesetzt, visuell noch zu testen.
- Monty-Spriteformat: auf dokumentiertes HuC6270-Plane-Layout korrigiert, visuell noch zu testen.
- Monty-Koordinaten/Collision 1:1: weiterhin offen.

## Naechste Portschritte

1. Phase 21 mit `git pull && ./build.sh` bauen und Screenshot pruefen.
2. C64 Monty-X/Y -> PCE-SAT-Transformation aus `refactored/src` exakt festlegen.
3. Dieselbe Screenkoordinaten-Abbildung fuer Collision statt direkter 32x20-Indexierung verwenden.
4. Danach Links/Rechts/Jump sichtbar verifizieren.
5. Erst danach Somersaultframes, generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
