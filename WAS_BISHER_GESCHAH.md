# Was bisher geschah

Stand: 2026-09-04 — Phase 20c

## Portierungsstand

**Gesamtport: ca. 32 %**

Die Prozentzahl bleibt konservativ: sichtbare Bring-up-Reparaturen zaehlen noch nicht als neuer Gameplay-Funktionsblock.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- PCE VDC/VCE Bring-up, PAL-orientierter Gameplay-Scheduler und Raum-$00-Zwischenstand.
- Monty ist im Emulator sichtbar.

## Phase 20c — VIC-Sprite-Slots statt Marker-Heuristik

Der zweite Buildversuch zeigte, dass die Phase-20b-Heuristik weiterhin falsch war. Die C64-Referenz legt die Walk-/Climb-Animationen an festen Adressen `$5400`, `$5500`, `$5600` ab. Damit besteht jeder Vier-Frame-Block aus vier festen 64-Byte-VIC-Slots: 63 sichtbare Bitmapbytes plus ein Slot-/Paddingbyte. Frames duerfen deshalb nicht durch Suchen nach einem wiederkehrenden Pixelprefix erkannt werden.

`tools/monty_sprite.py` zerlegt die transkribierten Animationsbloecke jetzt positionsbasiert in 64-Byte-Slots und nimmt aus jedem Slot exakt die ersten 63 sichtbaren Bytes. Nur am Ende des handtranskribierten Blocks fehlende Nullbytes werden bis zur bekannten Blockgroesse aufgefuellt. Damit ist die fehlerhafte `_extract_bitmap_frames`-Markerlogik entfernt.

## Koordinatenaudit

Der aktuelle PCE-Port zeichnet lediglich die rohe 32x20-Raumkarte. Die Referenz arbeitet mit einem 40-Zeichen-Screen. Das eigentliche 32-Zeichen-Playfield liegt in Spalten 4..35 und Zeilen 3..22; `CreatePlayfieldBorder` spiegelt die Kanten in die Gutters Spalten 2..3 und 36..37. `PopulateColourRam` verarbeitet deshalb 36 Zeichen pro Zeile ab Spalte 2. HUD/obere Zeilen und Sektorname unten fehlen im PCE-Port ebenfalls noch.

Besonders kritisch ist Montys C64-X-System: Kollisionsroutinen rechnen `(monty_x-$0c)>>2`, waehrend der bisherige PCE-SAT-Pfad `monty_x` fast direkt als Pixel-X benutzt. Diese Skalierung gilt nicht mehr als korrekt. Vor weiterem Gameplay werden Screen-, Sprite- und Collision-Koordinaten gemeinsam aus der C64-Referenz abgeleitet.

## Verifikationsstatus

- Host-Toolchain/startendes ROM: bestaetigt.
- Phase-20c VIC-Slot-Buildfix: lokal noch zu testen.
- Raumgeometrie 1:1: **noch nicht erreicht**.
- Sprite-X/Collision-X 1:1: **noch nicht erreicht**.
- Padbewegung: durch die fehlerhafte Collision-/Koordinatenabbildung noch nicht aussagekraeftig.

## Naechste Portschritte

1. Build nach dem positionsbasierten VIC-Slot-Fix wieder gruen bekommen.
2. C64 `DrawRoomPlayfield` + `CreatePlayfieldBorder` als 40-Spalten-Screenmodell auf PCE abbilden.
3. C64 Monty-X/Y -> PCE-SAT-Transformation exakt festlegen; dieselbe Transformation fuer Collision verwenden.
4. Erst danach Bewegung/Jump erneut visuell testen.
5. Danach Somersaultframes, generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
