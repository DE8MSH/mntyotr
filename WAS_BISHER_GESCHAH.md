# Was bisher geschah

Stand: 2026-09-04 — Phase 20b

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

## Phase 20a/20b — Sprite, Build und Koordinatenaudit

Der Nutzer meldete nach Phase 20a einen Regressionstest-Abbruch in `monty_sprite.py`: der letzte transkribierte VIC-Frame endet mit ausgelassenem Null-Padding. Der Extraktor akzeptiert jetzt ausschliesslich beim letzten Frame dieses fehlende Null-Ende und ergaenzt es auf die 63 sichtbaren VIC-Bitmapbytes. Andere Trunkierungen bleiben Fehler.

Der Screenshot hat ausserdem einen wichtigeren Architekturfehler sichtbar gemacht: Der aktuelle PCE-Port zeichnet lediglich die rohe 32x20-Raumkarte als 32 BAT-Zeichen. Das ist **nicht** die komplette C64-Screengeometrie. Die Referenz arbeitet mit einem 40-Zeichen-Screen. Das eigentliche 32-Zeichen-Playfield liegt in Spalten 4..35 und Zeilen 3..22; `CreatePlayfieldBorder` spiegelt die Kanten in die Gutters Spalten 2..3 und 36..37. `PopulateColourRam` verarbeitet deshalb 36 Zeichen pro Zeile ab Spalte 2. HUD/obere Zeilen und Sektorname unten fehlen im PCE-Port ebenfalls noch.

Damit ist die Beobachtung des Nutzers korrekt: Die Verhaeltnisse und Koordinaten sind noch nicht 1:1. Besonders kritisch ist Montys C64-X-System: Kollisionsroutinen rechnen `(monty_x-$0c)>>2`, waehrend der bisherige PCE-SAT-Pfad `monty_x` fast direkt als Pixel-X benutzt. Diese Skalierung wird jetzt nicht mehr als korrekt betrachtet. Vor weiterem Gameplay werden Screen-, Sprite- und Collision-Koordinaten gemeinsam aus der C64-Referenz abgeleitet.

## Verifikationsstatus

- Host-Toolchain/startendes ROM: bestaetigt.
- Phase-20b Buildfix: lokal noch zu testen.
- Raumgeometrie 1:1: **noch nicht erreicht**.
- Sprite-X/Collision-X 1:1: **noch nicht erreicht**.
- Padbewegung: durch die fehlerhafte Collision-/Koordinatenabbildung noch nicht aussagekraeftig.

## Naechste Portschritte

1. Build nach dem Frame-Normalisierungsfix wieder gruen bekommen.
2. C64 `DrawRoomPlayfield` + `CreatePlayfieldBorder` als 40-Spalten-Screenmodell auf PCE abbilden.
3. C64 Monty-X/Y -> PCE-SAT-Transformation exakt festlegen; dieselbe Transformation fuer Collision verwenden.
4. Erst danach Bewegung/Jump erneut visuell testen.
5. Danach Somersaultframes, generischer Room-Loader, Gegner, Mechanismen, Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
