# Was bisher geschah

Stand: 2026-09-04 — Phase 11

## Portierungsstand

**Gesamtport: ca. 22 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems. Sie steigt nur fuer konkret portierte bzw. verifizierte Subsysteme und wird bei jedem Arbeitsbericht genannt.

Grobe Gewichtung: Plattform/Build 10 %, Video/Room-Renderer 15 %, Welt/Raumdaten 15 %, Monty Input/Physik/Kollision/Sprite 20 %, Gegner 12 %, Mechanismen/Special Items 10 %, HUD/Gameflow/Freedom Kit/Completion 8 %, Audio 10 %.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer Verhalten und Daten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent.

## Bereits umgesetzt

- Linux-Mint-22-Toolchain-, Build- und Run-Grundgeruest.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- 320-Pixel-Ausgabe fuer die 320x200-C64-Spielmatrix vorbereitet.
- Raum `$00` exakt auf 640 logische Zellen = 32x20 dekodiert und als native PCE-BAT-Daten erzeugt.
- Acht raumspezifische C64-Character-Bitmaps nach PCE-4bpp konvertiert und Paletten angelegt.
- PAL-orientierter Gameplay-Scheduler mit getrenntem VBlank/Gameplay-Takt.
- Montys originale Sprungkurve und erste Kollisionslogik.
- Automatische Regressionstests fuer Raum, Jump-Arc und Scheduler.
- GitHub-Actions-ROM-Build fuer `motr.pce`, Symbole und Listing.

## Neu in Phase 11

### Toolchain-Pfad korrigiert

Der aktuelle `pce-devel/huc`-Baum hat `bare-startup.asm` unter `examples/asm/elmer/include`, waehrend `common.asm`, `vdc.asm`, `font.asm` und `joypad.asm` unter `include/hucc` liegen. `build.sh` setzt `PCE_INCLUDE` nun explizit auf beide Verzeichnisse und prueft die benoetigten Dateien vor PCEAS. `install.sh` baut die Host-Tools und gated gezielt auf `bin/pceas`.

### PCE-Pad -> Monty

Die aktuelle CORE-Joypadroutine liefert `joynow` mit aktiven High-Bits: I=$01, UP=$10, RIGHT=$20, DOWN=$40, LEFT=$80. `bare-startup.asm` aktualisiert diese Daten automatisch im VBlank-IRQ. Der Port nutzt jetzt I als C64-Fire und LEFT/RIGHT fuer Montys horizontale Bewegung.

### C64 ToggleStepGate

Das originale `ToggleStepGate` inkrementiert einen Byte-Zaehler und liefert Bit 0. Diese Semantik ist als `monty_toggle_step_gate` portiert. Links bewegt auf Gate=1, rechts auf Gate=0, entsprechend den originalen Call-Sites.

### Sprungrichtung gespeichert

Beim Start eines Sprungs werden LEFT/RIGHT gespeichert. Waehrend des Sprungs verwendet die horizontale Bewegung diese gespeicherten Richtungen, analog zu `jump_saved_left/right` der C64-Version.

### 640-Byte-Kollisionsmap korrigiert

Die Raumkarte ist groesser als ein 8-Bit-X-Index. `room00_get_tile_xy` benutzt deshalb jetzt einen 16-Bit-Pointer plus row*32-Tabelle statt eines ueberlaufenden 8-Bit-Index. Dadurch sind auch die unteren Raumzeilen adressierbar.

## Noch offen

- Der neue Code muss durch den aktuellen PCEAS-CI-Lauf und eventuelle Syntaxprobleme muessen beseitigt werden.
- Monty ist noch nicht als PCE-Sprite sichtbar.
- UP/DOWN, Leiter-/Seil-Semantik und exakte Tile-State-Logik fehlen.
- Property-4/Piledriver-Nebenwirkung und Raumwechsel fehlen.
- 320px-Horizontalporches muessen im Emulator/Echthardware verifiziert werden.
- 5/6 ist weiterhin eine Bring-up-Approximation fuer PAL-Timing.

## Naechste harte Schritte

1. CI/PCEAS des neuen Codes gruen bekommen und `motr.pce` erzeugen.
2. Montys C64-Spritedaten extrahieren und in PCE-SPR-4bpp konvertieren.
3. SATB-Update anschliessen, damit Pad/Jump sichtbar werden.
4. UP/DOWN und vollstaendige C64-Tile-State-Logik portieren.
5. Raumwechsel und weitere Raeume.
6. Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
