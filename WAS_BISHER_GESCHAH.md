# Was bisher geschah

Stand: 2026-09-04 — Phase 15

## Portierungsstand

**Gesamtport: ca. 29 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems. Sie steigt nur fuer konkret portierte bzw. verifizierte Subsysteme.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer Verhalten und Daten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent.

## Bereits umgesetzt

- Linux-Mint-22-Toolchain-, Build- und Run-Grundgeruest; kein GitHub-Actions-ROM-Build mehr.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- Raum `$00` als native PCE-BAT plus echte konvertierte C64-Hintergrundtiles.
- PAL-orientierter Gameplay-Scheduler.
- Montys originale Sprungkurve, PCE-Pad, horizontale Bewegung, Step-Gate und erste Tile-Kollision.
- C64-Raumkanten und vollstaendiges statisches 6x23-Weltgrid mit Exit-Resolver.
- Automatische Regressionstests fuer Raum, Jump-Arc, Scheduler, Weltgrid und jetzt Monty-Spritedaten.

## Neu in Phase 15

### Echte Monty-Grafik portiert

Die ersten vier originalen Walk-left-Frames aus `Monty.sprites.walk_l_spr` (C64-Pointer `$50-$53`, Quellbereich `$5400-$54ff`) sind jetzt Teil der PCE-Asset-Pipeline. `tools/monty_sprite.py` interpretiert jeden C64-Frame als 24x21 1bpp und wandelt ihn ohne Skalierung in native PCE-SPR-Daten um.

Da ein einzelner PCE-Hardware-Sprite die originale 24-Pixel-Breite nicht exakt abbildet, wird Monty aus zwei nebeneinanderliegenden 16x32-Sprites zusammengesetzt. Transparente Padding-Pixel erhalten die originale 24x21-Silhouette.

### Sprite-Pfad im HuC6280-Code

`src/monty_sprite.asm` fuegt VRAM-Upload, Vier-Frame-Animation und SATB-Eintraege hinzu. Die SATB-X/Y-Werte folgen direkt `monty_x`/`monty_y`, sodass die bereits portierte Pad-, Kollisions- und Sprungphysik nun einen sichtbaren Hardware-Sprite treiben kann.

Der Build erzeugt `monty-walk-l.dat` automatisch und assembliert mit `-gA`, damit Symbole fuer lokale Emulator-Debugginglaeufe entstehen koennen.

### Regression

`tools/test_port.py` prueft jetzt, dass genau vier 64-Byte-C64-Walkframes vorliegen, jedes Bild 24x21 dekodiert wird und daraus exakt 2048 Bytes PCE-Sprite-Daten entstehen.

## Wichtig: Verifikationsstatus

Der Sprite-Pfad ist portiert und im Quellcode angeschlossen, aber **noch nicht durch einen lokalen PCEAS-Lauf oder Emulator/Echthardware verifiziert**. Die GitHub Action bleibt auf Wunsch entfernt. Deshalb wird noch nicht behauptet, dass SATB-Attribute/Patternadressierung auf Hardware bereits fehlerfrei sichtbar sind.

## Aktuell offen

- PCEAS-/Emulatortest des neuen Monty-Spritepfads und ggf. Korrektur der SATB-Bitfelder/Patternadressierung.
- Walk-right, Climb und 12+12 Somersault/Jump-Frames noch in die PCE-Pipeline uebernehmen.
- Raum `$01` und generischer Room-State/Renderer fuer echte Raumwechsel.
- DOWN/UP, Leiter-/Seil-Semantik und vollstaendige Tile-State-Logik.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.
- 320px-Horizontalporches und PAL-Timing weiter kalibrieren.

## Naechste harte Schritte

1. Spritepfad assemblerfest machen und SATB/VRAM-Layout gegen HuC/PCE-Dokumentation pruefen.
2. Walk-right und Somersault-Frames portieren; Animation an Bewegung/Jump-State koppeln.
3. Raum `$01` + generischen Raumloader anschliessen.
4. Leiter/Seil/Tile-State portieren.
5. Gegner/Mechanismen/HUD/Gameflow/Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
