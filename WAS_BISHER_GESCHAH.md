# Was bisher geschah

Stand: 2026-09-04 — Phase 9

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

## CI/Toolchain: jetzt konkret verifiziert

Der CI-Log zeigt, dass der aktuelle `pce-devel/huc`-Checkout PCEAS erfolgreich linkt und nach `$HOME/huc/bin/pceas` kopiert. Das vorherige `make -C huc/src` liefert trotzdem Exitcode 1, obwohl PCEAS bereits fertig vorhanden ist; Ursache ist ein anderer paralleler Upstream-Subtarget. Fuer diesen Pure-ASM-Port ist `bin/pceas` die tatsaechliche Build-Voraussetzung.

Der Workflow akzeptiert deshalb den aggregierten Upstream-Make-Status nur als Hinweis und prueft danach hart `test -x $HOME/huc/bin/pceas`. Fehlt PCEAS, scheitert CI weiterhin. Existiert es, geht CI endlich in unseren eigenen `./build.sh` und damit zu den echten MOTR-Assemblerfehlern weiter.

## Neu analysierte C64-Kollisionsbasis

Die Referenzroutine `ComputeMontyTilePointer` rechnet Montys C64-Spritekoordinaten in Tilekoordinaten um. Sie zieht von Y `$32` ab und teilt durch 8. Fuer X zieht sie `$0c` ab und teilt durch 4, bevor die Kollisionshelfer die angrenzenden Tiles pruefen. Die Referenz beschreibt `CheckTileRight/Left`, `CheckTileAbove` und `CheckTileBelow` explizit als 1-2-Tile-Abfragen um Monty; `CheckTileBelow` behandelt zusaetzlich Property 4. Diese Semantik wird fuer den PCE-Port beibehalten, statt eine neue Bounding-Box-Physik zu erfinden.

## Automatische Regression-Checks

Vor PCEAS wird geprueft: Raum `$00` = 640 Zellen; Tile-IDs im erlaubten Bereich; Jump-Ascent 22 Samples/20 Pixel; Jump-Descent 17 Samples/14 Pixel; Bring-up-Scheduler 5/6.

## Naechste harte Schritte

1. Neuen CI-Lauf bis `./build.sh` bringen und PCEAS-Fehler unseres Codes beseitigen.
2. Erfolgreiches `motr.pce` als Artefakt erzeugen und hier zum Test bereitstellen.
3. Raum-$00-Darstellung im Emulator verifizieren.
4. C64-Kollisionskoordinaten und CheckTileBelow/Above/Left/Right an `room00_collision_map` anschliessen.
5. PCE-Pad + Sprungstart + Links/Rechts/ToggleStepGate.
6. Monty-Sprite nach PCE-SPR konvertieren und anzeigen.
7. Raumwechsel; danach Gegner, Mechanismen und Special Items.

## Noch nicht behauptet

- Noch kein verifiziert spielbarer Port.
- Noch kein erfolgreich erzeugtes aktuelles `motr.pce`; der neue CI-Lauf muss nun erstmals unseren Assembler erreichen.
- Native Raumgrafik muss noch Emulator/Echthardware-getestet werden.
- Montys PCE-Sprite, Padsteuerung und vollstaendige Kollisionen fehlen noch.
- 5/6 ist weiterhin nur die Bring-up-Approximation fuer PAL-Timing.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
