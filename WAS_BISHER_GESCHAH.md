# Was bisher geschah

Stand: 2026-09-04 — Phase 7

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer Verhalten und Daten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent. Prioritaet: Raumgeometrie, Grafik, Bewegung und Kollisionen; Musik/SFX folgen spaeter.

## Bereits umgesetzt

- Linux-Mint-22-Toolchain-, Build- und Run-Grundgeruest.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- 320-Pixel-Ausgabe fuer die 320x200-C64-Spielmatrix vorbereitet.
- C64 Raum-RLE-Format analysiert und dokumentiert.
- Raum `$00` exakt auf 640 logische Zellen = 32x20 dekodiert.
- Die acht raumspezifischen C64-Character-Bitmaps von Raum `$00` nach PCE-4bpp konvertiert.
- Acht PCE-BG-Paletten fuer die C64-Raumfarben angelegt.
- Native BAT-Darstellung fuer Raum `$00` angelegt.
- Build generiert `room00-map.dat` und `room00-bat.dat` deterministisch aus demselben RLE-Stream.
- PAL-orientierter Gameplay-Scheduler: Display-VBlank und Spiel-Update getrennt; Bring-up-Gate 5 logische Ticks pro 6 PCE-VBlanks.
- Montys originale Sprungkurve uebernommen: 22 Aufstiegs- und 17 Abstiegs-Samples plus Sentinel.
- Raum-$00-Collision-Properties aus den originalen Character-Indizes abgeleitet: `1,1,1,2,1,1,1,1`.
- `monty_physics.asm` mit C64-Pixelkoordinaten, Jump-State und Jump-Step angelegt.
- **Neu:** `tools/test_port.py` prueft vor jedem ROM-Build deterministisch Raumgroesse, Jump-Arc-Fingerprints und 5/6-Timing.
- **Neu:** Build bewahrt neben `.pce` nun auch `.sym` und `.lst` unter dem Monty-Namen auf, wenn PCEAS sie erzeugt.

## Automatische Regression-Checks

Vor PCEAS wird jetzt geprueft:

1. Raum `$00` dekodiert auf exakt 640 Zellen.
2. Alle logischen Tile-IDs liegen im 4-Bit-Bereich.
3. Originale Jump-Ascent-Tabelle: 22 Samples, insgesamt 20 Pixel Y-Delta.
4. Originale Jump-Descent-Tabelle: 17 Samples, insgesamt 14 Pixel Y-Delta.
5. Aktueller PAL-Bring-up-Scheduler liefert 5/6, 50/60 und 500/600 Ticks.

Damit fallen versehentliche Daten- oder Timing-Aenderungen bereits vor dem Assemblieren auf.

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

## Toolchain-Audit

Die Quellbasis verwendet den neueren CORE(not TM)-artigen Startup (`bare-startup.asm`) und dessen VBlank/Joypad-Infrastruktur. Der aktuell eingetragene Installer zeigt jedoch noch auf `uli/huc`. Vor einem als verifiziert bezeichneten ROM muss deshalb die konkrete HuC/CORE-Version fest gepinnt und der Include-Satz gegen genau diese Version gebaut werden. Dieser Punkt wird nicht mehr als erledigt markiert, bis ein reproduzierbarer Linux-Mint-Build vorliegt.

## Naechste harte Schritte

1. HuC/CORE-Version pinnen und Linux-Mint-Build reproduzierbar machen.
2. Native Raum-$00-Darstellung in Emulator verifizieren.
3. Monty-Sprite-Daten analysieren und nach PCE-SPR konvertieren.
4. PCE-Pad auf C64-Inputflags abbilden.
5. Links/Rechts inklusive `ToggleStepGate` portieren.
6. Tile-Abfragen fuer Montys 2x3-Footprint an `room00_collision_map` anschliessen.
7. CheckTileBelow/Above/Left/Right portieren.
8. Sprungstart, Sprungkurve und Landung mit Kollisionen verbinden.
9. Raumwechsel anschliessen.
10. Danach Enemy-Slots, Mechanismen und Special Items.

## Noch nicht behauptet

- Noch kein verifiziert spielbarer Port.
- Noch kein reproduzierbar verifizierter HuC/CORE-ROM-Build auf Linux Mint 22.
- Native Raumgrafik muss noch in Emulator/Echthardware getestet werden.
- Montys PCE-Sprite, Padsteuerung und vollstaendige Kollisionen fehlen noch.
- Der 5/6-Scheduler ist eine Bring-up-Approximation und noch nicht die finale PAL-50,12-Hz-Kalibrierung.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/uli/huc
- Aktuell gepflegter CORE-Zweig: https://github.com/pce-devel/huc
