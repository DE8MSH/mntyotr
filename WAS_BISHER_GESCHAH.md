# Was bisher geschah

Stand: 2026-09-04 — Phase 13

## Portierungsstand

**Gesamtport: ca. 23 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems. Sie steigt nur fuer konkret portierte bzw. verifizierte Subsysteme.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer Verhalten und Daten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent.

## Bereits umgesetzt

- Linux-Mint-22-Toolchain-, Build- und Run-Grundgeruest.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- 320-Pixel-Ausgabe fuer die 320x200-C64-Spielmatrix vorbereitet.
- Raum `$00` auf 640 logische Zellen = 32x20 dekodiert und als native PCE-BAT-Daten erzeugt.
- Acht raumspezifische C64-Character-Bitmaps nach PCE-4bpp konvertiert und Paletten angelegt.
- PAL-orientierter Gameplay-Scheduler mit getrenntem VBlank/Gameplay-Takt.
- Montys originale Sprungkurve, PCE-Pad Links/Rechts + Button I/Fire, gespeicherte Sprungrichtung, C64-`ToggleStepGate` und erste Tile-Kollision.
- 16-Bit-Zugriff auf die komplette 640-Byte-Kollisionsmap.
- Automatische Regressionstests fuer Raum, Jump-Arc und Scheduler.

## Neu in Phase 13

### GitHub Action entfernt

Auf Wunsch wurde `.github/workflows/build-rom.yml` komplett aus dem Repository geloescht. Es gibt damit keinen automatischen GitHub-Actions-Build des PCE-ROMs mehr. Der lokale Linux-Mint-Build ueber `install.sh` und `build.sh` bleibt Bestandteil des Projekts.

### Raumkanten / Room-Exit-Pfad begonnen

`monty_physics.asm` besitzt jetzt einen expliziten `monty_room_exit`-Status. Links-, Rechts- und Oberkanten werden nach Bewegungs-/Sprungschritten geprueft. Die C64-orientierten Hand-off-Koordinaten werden dabei uebernommen: rechter Ausgang setzt X auf `$15`, oberer Ausgang Y auf `$da`; fuer den linken Gegenweg wird X an die rechte Eintrittsseite gesetzt.

Der Exit wird bewusst nur signalisiert. Das Laden der Nachbarraumdaten wird als eigener World/Room-Schritt portiert, damit die derzeit feste Raum-$00-Kollisionsmap nicht versehentlich fuer einen anderen Raum weiterverwendet wird.

## Aktuell offen

- Monty ist noch nicht als PCE-Sprite sichtbar.
- Nachbarraum-Tabelle und echter Raumdatenwechsel muessen an `monty_room_exit` angeschlossen werden.
- DOWN/UP, Leiter-/Seil-Semantik und exakte Tile-State-Logik fehlen.
- Property-4/Piledriver-Nebenwirkung fehlt.
- 320px-Horizontalporches muessen im Emulator/Echthardware verifiziert werden.
- 5/6 ist weiterhin eine Bring-up-Approximation fuer PAL-Timing.
- Der Build wird nicht mehr ueber GitHub Actions ausgefuehrt; echte PCEAS-Verifikation erfolgt lokal.

## Naechste harte Schritte

1. C64-Weltgrid und Raum-Nachbarschaften als PCE-Daten portieren.
2. `monty_room_exit` an echten Raumwechsel anschliessen.
3. Montys C64-Spritedaten in PCE-SPR-4bpp konvertieren.
4. SATB-Update anschliessen, damit Pad/Jump sichtbar werden.
5. Vollstaendige C64-Tile-State-Logik portieren.
6. Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
