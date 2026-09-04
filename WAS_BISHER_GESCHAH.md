# Was bisher geschah

Stand: 2026-09-04 — Phase 10

## Portierungsstand

**Gesamtport: ca. 18 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems, nicht nur die Anzahl bereits angelegter Dateien. Ab jetzt wird sie bei jedem Arbeitsbericht mitgefuehrt. Sie steigt nur fuer konkret portierte bzw. verifizierte Subsysteme.

Grobe Gewichtung: Plattform/Build 10 %, Video/Room-Renderer 15 %, Welt/Raumdaten 15 %, Monty Input/Physik/Kollision/Sprite 20 %, Gegner 12 %, Mechanismen/Special Items 10 %, HUD/Gameflow/Freedom Kit/Completion 8 %, Audio 10 %.

Aktueller Stand nach dieser Gewichtung: Plattform/Build weitgehend angelegt; Video und Raum-$00$ teilweise portiert; Weltformat analysiert; Monty-Sprungdaten und erste echte Kollisionsroutinen portiert. Gegner, Mechanismen, kompletter Gameflow und Audio sind noch weitgehend offen.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz fuer Verhalten und Daten ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent. Prioritaet: Raumgeometrie, Grafik, Bewegung und Kollisionen; Musik/SFX folgen spaeter.

## Bereits umgesetzt

- Linux-Mint-22-Toolchain-, Build- und Run-Grundgeruest.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- 320-Pixel-Ausgabe fuer die 320x200-C64-Spielmatrix vorbereitet.
- Raum `$00` exakt auf 640 logische Zellen = 32x20 dekodiert und als native PCE-BAT-Daten erzeugt.
- Acht raumspezifische C64-Character-Bitmaps nach PCE-4bpp konvertiert und Paletten angelegt.
- PAL-orientierter Gameplay-Scheduler mit getrenntem VBlank/Gameplay-Takt.
- Montys originale Sprungkurve: 22 Aufstiegs- und 17 Abstiegs-Samples plus Sentinel.
- Raum-$00-Collision-Properties und `monty_physics.asm` angelegt.
- Automatische Regressionstests fuer Raum, Jump-Arc und Scheduler.
- GitHub-Actions-ROM-Build fuer `motr.pce`, Symbole und Listing.

## Neu in Phase 10: C64-Kollision -> HuC6280

`monty_physics.asm` enthaelt jetzt echte PCE/HuC6280-Portierungen der C64-Kollisionsproben:

- `room00_get_tile_xy`: liest aus dem generierten 32x20-Logikraum.
- `room00_get_property_xy`: mappt Tile-ID auf die originale C64-Kollisionsklasse.
- `monty_check_tile_right` / `monty_check_tile_left`.
- `monty_check_tile_above` / `monty_check_tile_below`.
- C64-Grenztests `(x-$0c)&3` und `(y-$32)&7` bleiben erhalten.
- Die vertikale Sprungkurve ruft jetzt Above/Below-Kollision auf; Decke schaltet auf Abstieg, Boden beendet den Sprung.

Die Routinen arbeiten weiterhin in C64-Pixelkoordinaten. Damit bleibt Gameplay-Logik von PCE-VRAM/BAT getrennt.

Noch offen in diesem Teil: exakte Property-4-Piledriver-Nebenwirkung, situationsabhaengige Property-2/3-Semantik, originale dynamische Anzahl der Probe-Tiles und exakte Landekorrektur. Diese Punkte werden gegen die Referenz weiter nachgezogen und nicht als fertig behauptet.

## CI/Toolchain

Der CI-Log zeigt, dass der aktuelle `pce-devel/huc`-Checkout PCEAS erfolgreich linkt und nach `$HOME/huc/bin/pceas` kopiert. Der Workflow prueft deshalb gezielt dieses Binary und soll danach unseren eigenen Assemblercode bauen.

## Naechste harte Schritte

1. Aktuellen CI-Lauf bis PCEAS durchziehen und Syntax/Assemblerprobleme der neuen Routinen beseitigen.
2. PCE-Pad auf C64-Richtungs-/Fire-Flags abbilden.
3. Originales Links/Rechts-Verhalten samt `ToggleStepGate` anschliessen.
4. Kollisionsproben exakt an die C64-Zustandslogik angleichen.
5. Monty-Sprite-Daten nach PCE-SPR konvertieren und Bewegung sichtbar machen.
6. Raumwechsel und weitere Raumdaten portieren.
7. Danach Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Noch nicht behauptet

- Noch kein verifiziert spielbarer Port.
- Noch kein erfolgreich erzeugtes aktuelles `motr.pce`; CI muss den neuen Code assemblieren.
- Native Raumgrafik muss noch Emulator/Echthardware-getestet werden.
- Padsteuerung und Montys PCE-Sprite fehlen noch.
- 5/6 ist weiterhin nur die Bring-up-Approximation fuer PAL-Timing.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
