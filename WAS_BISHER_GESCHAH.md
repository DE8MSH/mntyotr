# Was bisher geschah

Stand: 2026-09-04 — Phase 8

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer Verhalten und Daten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent. Prioritaet: Raumgeometrie, Grafik, Bewegung und Kollisionen; Musik/SFX folgen spaeter.

## Bereits umgesetzt

- Linux-Mint-22-Toolchain-, Build- und Run-Grundgeruest.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- 320-Pixel-Ausgabe fuer die 320x200-C64-Spielmatrix vorbereitet.
- C64 Raum-RLE-Format analysiert und dokumentiert.
- Raum `$00` exakt auf 640 logische Zellen = 32x20 dekodiert.
- Acht raumspezifische C64-Character-Bitmaps von Raum `$00` nach PCE-4bpp konvertiert.
- Acht PCE-BG-Paletten fuer die C64-Raumfarben angelegt.
- Native BAT-Darstellung fuer Raum `$00` angelegt.
- Build generiert `room00-map.dat` und `room00-bat.dat` deterministisch aus demselben RLE-Stream.
- PAL-orientierter Gameplay-Scheduler: Display-VBlank und Spiel-Update getrennt; Bring-up-Gate 5 logische Ticks pro 6 PCE-VBlanks.
- Montys originale Sprungkurve uebernommen: 22 Aufstiegs- und 17 Abstiegs-Samples plus Sentinel.
- Raum-$00-Collision-Properties abgeleitet.
- `monty_physics.asm` mit C64-Pixelkoordinaten, Jump-State und Jump-Step angelegt.
- `tools/test_port.py` prueft vor jedem ROM-Build Raumgroesse, Jump-Arc-Fingerprints und 5/6-Timing.
- Build bewahrt `.pce`, `.sym` und `.lst` auf, soweit PCEAS sie erzeugt.
- GitHub-Actions-ROM-Build angelegt, damit jeder main-Stand reproduzierbar getestet und `motr.pce` als Artefakt ausgegeben werden kann.

## CI/Toolchain: neu verifiziert

Der erste CI-Lauf hat einen echten Infrastrukturfehler sichtbar gemacht: `make` im Root von `pce-devel/huc` baut nicht nur die Host-Tools, sondern danach auch alle Upstream-Beispiele. PCEAS selbst wurde erfolgreich kompiliert und nach `bin/pceas` kopiert; anschliessend scheiterte ein fuer MOTR irrelevantes HuCC-Beispiel (`metatile3-multiblk`, undefiniertes `_cd_loadbank.4`). Dadurch wurde unser ROM-Schritt faelschlich blockiert.

Der Workflow baut deshalb ab jetzt gezielt `huc/src` und prueft explizit `bin/pceas`. Damit wird nur die fuer MOTR benoetigte Toolchain als Voraussetzung behandelt; fehlerhafte fremde Beispiele blockieren den Port nicht mehr.

## Automatische Regression-Checks

Vor PCEAS wird geprueft:

1. Raum `$00` dekodiert auf exakt 640 Zellen.
2. Alle logischen Tile-IDs liegen im 4-Bit-Bereich.
3. Jump-Ascent: 22 Samples, insgesamt 20 Pixel Y-Delta.
4. Jump-Descent: 17 Samples, insgesamt 14 Pixel Y-Delta.
5. PAL-Bring-up-Scheduler liefert 5/6, 50/60 und 500/600 Ticks.

## C64-Verhalten als Portierungsbasis

- `Monty.Draw` ruft zuerst Bewegung und danach Animationszustand auf.
- Bewegung aktualisiert zuerst die Tile-Flags.
- Feuer startet nur, wenn Monty nicht bereits springt und kein Jetpack aktiv ist.
- Links/Rechts werden beim Sprung gespeichert und waehrend der Sprungkurve wiederverwendet.
- Die originale Sprungkurve arbeitet mit Pixel-Deltas pro logischem Frame.
- Horizontale Bewegung wird teilweise durch `ToggleStepGate` halbiert.
- Tilecodes 1..8 werden ueber eine raumspezifische Property-Tabelle auf Kollisionsklassen 0..4 abgebildet.
- C64-Grenzwerte und Room-Exit-Logik werden als Gameplaywerte portiert, nicht an PCE-Displaykoordinaten neu erfunden.

## PC-Engine-Aufbau

- 320x224 PCE-Ausgabe.
- 320x200 logisches C64-Canvas ohne horizontale Skalierung.
- 32x20 Raumfeld innerhalb des 40-Zeichen-Canvas.
- C64 1bpp Character -> PCE 4bpp Pattern.
- C64 Character-Farbe -> PCE Palette pro logischem Raumtile.
- Logische Tile-ID bleibt unabhaengig vom VRAM-Pattern erhalten.
- Gameplay-Takt ist von der VBlank-Rate getrennt.

## Naechste harte Schritte

1. Den korrigierten CI-Lauf bis zum eigenen `main.asm` laufen lassen und dessen konkrete Assemblerfehler beseitigen.
2. Erfolgreiches `motr.pce` als CI-Artefakt erzeugen und lokal testen.
3. Native Raum-$00-Darstellung im Emulator verifizieren.
4. Monty-Sprite-Daten analysieren und nach PCE-SPR konvertieren.
5. PCE-Pad auf C64-Inputflags abbilden.
6. Links/Rechts inklusive `ToggleStepGate` portieren.
7. Tile-Abfragen fuer Montys 2x3-Footprint anschliessen.
8. CheckTileBelow/Above/Left/Right portieren.
9. Sprungstart, Sprungkurve und Landung verbinden.
10. Raumwechsel, danach Gegner/Mechanismen/Special Items.

## Noch nicht behauptet

- Noch kein verifiziert spielbarer Port.
- Noch kein erfolgreich erzeugtes aktuelles `motr.pce`; der erste CI-Versuch scheiterte an einem fremden Upstream-Beispiel, nicht am MOTR-Assembler.
- Native Raumgrafik muss noch im Emulator/Echthardware getestet werden.
- Montys PCE-Sprite, Padsteuerung und vollstaendige Kollisionen fehlen noch.
- Der 5/6-Scheduler ist eine Bring-up-Approximation.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- Aktuell gepflegte HuC/PCEAS-Basis: https://github.com/pce-devel/huc
