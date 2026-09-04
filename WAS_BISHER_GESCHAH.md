# Was bisher geschah

Stand: 2026-09-04 — Phase 20d

## Portierungsstand

**Gesamtport: ca. 32 %**

Die Prozentzahl bleibt konservativ: Bring-up- und Testreparaturen zaehlen noch nicht als neuer Gameplay-Funktionsblock.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`; `byte-perfect` dient nur als zusaetzliche Ground-Truth.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard.

## Bestaetigt

- Linux-Mint-22 HuC/PCEAS Toolchain und startendes `.pce`.
- PCE VDC/VCE Bring-up, PAL-orientierter Gameplay-Scheduler und Raum-$00-Zwischenstand.
- Monty ist im Emulator sichtbar.

## Phase 20d — Regressionstest an Referenzdaten angepasst

Der Build nach Phase 20c kam nun bis `tools/test_port.py` und scheiterte an der alten Annahme, Climb-Frame 0 und 2 muessten byteidentisch sein. Diese Gleichheit ist keine Eigenschaft des VIC-Spriteformats und darf die Daten aus der verbindlichen `refactored/src`-Referenz nicht ueberschreiben. Der Test prueft jetzt stattdessen fuer alle 12 Walk-/Climbframes: vier Frames pro Animation, jeweils 24x21 dekodierbare C64-Pixel sowie 2048 Byte gueltige PCE-Spritedaten pro Vier-Frame-Animation. Die falsche Frame-0==Frame-2-Assertion ist entfernt.

## Koordinatenaudit

Der aktuelle PCE-Port zeichnet lediglich die rohe 32x20-Raumkarte. Die Referenz arbeitet mit einem 40-Zeichen-Screen. Das eigentliche 32-Zeichen-Playfield liegt in Spalten 4..35 und Zeilen 3..22; `CreatePlayfieldBorder` spiegelt die Kanten in die Gutters Spalten 2..3 und 36..37. `PopulateColourRam` verarbeitet deshalb 36 Zeichen pro Zeile ab Spalte 2. HUD/obere Zeilen und Sektorname unten fehlen im PCE-Port ebenfalls noch.

Besonders kritisch ist Montys C64-X-System: Kollisionsroutinen rechnen `(monty_x-$0c)>>2`, waehrend der bisherige PCE-SAT-Pfad `monty_x` fast direkt als Pixel-X benutzt. Diese Skalierung gilt nicht mehr als korrekt. Vor weiterem Gameplay werden Screen-, Sprite- und Collision-Koordinaten gemeinsam aus der C64-Referenz abgeleitet.

## Verifikationsstatus

- Host-Toolchain/startendes ROM: bestaetigt.
- Phase-20d Testfix: lokal noch zu testen.
- Raumgeometrie 1:1: **noch nicht erreicht**.
- Sprite-X/Collision-X 1:1: **noch nicht erreicht**.
- Padbewegung: durch die fehlerhafte Collision-/Koordinatenabbildung noch nicht aussagekraeftig.

## Naechste Portschritte

1. Build mit dem korrigierten Regressionstest bestaetigen.
2. C64 `DrawRoomPlayfield` + `CreatePlayfieldBorder` als 40-Spalten-Screenmodell auf PCE abbilden.
3. C64 Monty-X/Y -> PCE-SAT-Transformation exakt festlegen; dieselbe Transformation fuer Collision verwenden.
4. Erst danach Bewegung/Jump erneut visuell testen.
5. Danach Somersaultframes, generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
