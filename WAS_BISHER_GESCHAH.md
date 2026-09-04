# Was bisher geschah

Stand: 2026-09-04 — Phase 6

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer Verhalten und Daten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent. Prioritaet: Raumgeometrie, Grafik, Bewegung und Kollisionen; Musik/SFX folgen spaeter.

## Bereits umgesetzt

- Linux-Mint-22-Toolchain-, Build- und Run-Grundgeruest.
- HuC/PCEAS + CORE(not TM)-Startup.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- 320-Pixel-Ausgabe fuer die 320x200-C64-Spielmatrix vorbereitet.
- C64 Raum-RLE-Format analysiert und dokumentiert.
- Raum `$00` exakt auf 640 logische Zellen = 32x20 dekodiert.
- Die acht raumspezifischen C64-Character-Bitmaps von Raum `$00` nach PCE-4bpp konvertiert.
- Acht PCE-BG-Paletten fuer die C64-Raumfarben angelegt.
- **Native BAT-Darstellung:** Raum `$00` wird nicht mehr als Diagnose-Ziffern geplant, sondern als PCE-BAT aus den konvertierten Original-Patterns aufgebaut.
- Build generiert `room00-map.dat` und `room00-bat.dat` deterministisch aus demselben RLE-Stream.
- Dadurch verwenden Renderer und kuenftige Kollisionserkennung dieselbe Raumgeometrie.
- PAL-orientierter Gameplay-Scheduler hinzugefuegt: Display-VBlank und Spiel-Update sind jetzt getrennt.
- Erste Gate-Version fuehrt 5 logische C64-Ticks pro 6 PCE-VBlanks aus; spaeter wird sie auf verifizierte ~50,12 Hz kalibriert.
- Montys originale Sprungkurve aus der C64-Rekonstruktion uebernommen: 22 Aufstiegs- und 17 Abstiegs-Samples plus Sentinel.
- Raum-$00`-Collision-Properties aus den originalen Character-Indizes abgeleitet: `1,1,1,2,1,1,1,1`.
- `monty_physics.asm` mit C64-Pixelkoordinaten, Jump-State und Jump-Step angelegt.

## Build-Pipeline

`tools/room_rle.py` ist jetzt Teil des Builds:

1. C64-RLE dekodieren.
2. Exakt 640 Zellen validieren.
3. 640-Byte logische Collision-Map erzeugen.
4. Daraus 640 PCE-BAT-Words erzeugen.
5. BAT-Words referenzieren `CHR_GAME + tile` und Palette `tile`.
6. PCEAS assembliert die generierten Daten per `incbin` in die HuCard-ROM.

Damit kann die grafische Darstellung nicht versehentlich von der logischen Kollisionskarte abweichen.

## C64-Verhalten, das bereits als Portierungsbasis feststeht

- `Monty.Draw` ruft zuerst Bewegung und danach Animationszustand auf.
- Bewegung aktualisiert zuerst die Tile-Flags.
- Feuer startet nur dann einen normalen Sprung, wenn Monty nicht bereits springt und kein Jetpack aktiv ist.
- Links/Rechts werden beim Sprung gespeichert und waehrend der Sprungkurve wiederverwendet.
- Die originale Sprungkurve arbeitet mit Pixel-Deltas pro logischem Frame.
- Horizontale Bewegung wird im Original teilweise durch ein Step-Gate halbiert; das wird als eigener Portierungsschritt uebernommen statt pauschal auf PCE-60-Hz umgerechnet.
- Tilecodes 1..8 werden ueber eine raumspezifische Property-Tabelle auf Kollisionsklassen 0..4 abgebildet.

## Aktueller PC-Engine-Aufbau

- 320x224 PCE-Ausgabe.
- 320x200 logisches C64-Canvas ohne horizontale Skalierung.
- 32x20 Raumfeld innerhalb des 40-Zeichen-Canvas.
- C64 1bpp Character -> PCE 4bpp Pattern.
- C64 Character-Farbe -> PCE Palette pro logischem Raumtile.
- Logische Tile-ID bleibt unabhaengig vom VRAM-Pattern erhalten.
- Gameplay-Takt ist von der VBlank-Rate getrennt.

## Naechste harte Schritte

1. Build auf realem HuC/PCEAS erneut durchlaufen und alle Assembler-Syntax-/Bankgrenzen beseitigen.
2. Native Raum-$00`-Darstellung in Geargrafx verifizieren.
3. Monty-Sprite-Daten aus der Rekonstruktion analysieren und in PCE-Sprite-Patterns konvertieren.
4. PCE-Pad auf die C64-Inputflags abbilden.
5. Links/Rechts inklusive originalem ToggleStepGate portieren.
6. Tile-Abfragen fuer Montys 2x3-Footprint an `room00_collision_map` anschliessen.
7. CheckTileBelow/Above/Left/Right portieren.
8. Sprungstart, Sprungkurve und Landung mit diesen Kollisionen verbinden.
9. Raumwechsel an den C64-Grenzwerten und Navigationsdaten anschliessen.
10. Danach Enemy-Slots, Mechanismen und Special Items.

## Noch nicht behauptet

- Noch kein verifiziert spielbarer Port.
- Native Raumgrafik und neuer Buildpfad muessen noch in Emulator/Echthardware getestet werden.
- Montys PCE-Sprite ist noch nicht eingebunden.
- Padsteuerung und vollstaendige Kollisionen fehlen noch.
- Der aktuelle 5/6-Scheduler ist eine Bring-up-Approximation und noch nicht die finale PAL-50,12-Hz-Kalibrierung.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/uli/huc
