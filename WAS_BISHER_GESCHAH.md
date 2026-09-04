# Was bisher geschah

Stand: 2026-09-04 — Phase 12

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
- PCE-Pad: Links/Rechts + Button I/Fire, gespeicherte Sprungrichtung und C64-`ToggleStepGate`.
- 16-Bit-Zugriff auf die komplette 640-Byte-Kollisionsmap.
- Automatische Regressionstests fuer Raum, Jump-Arc und Scheduler.
- GitHub-Actions-ROM-Build fuer `motr.pce` und Diagnosedateien.

## Neu in Phase 12

### CI-Fehler exakt diagnostiziert

Der aktuelle GitHub-Actions-Lauf erreichte den Upstream-HuC-Build. `pceas` wurde nachweislich erfolgreich gelinkt und nach `$HOME/huc/bin/pceas` kopiert. Trotzdem beendete der Upstream-`make -C src` den Schritt mit Exitcode 1. Dadurch wurde unser eigener PCEAS-Aufruf noch gar nicht erreicht.

Der Workflow wurde deshalb robuster gemacht: Der bekannte Upstream-Gesamt-Make-Exit wird separat erfasst; entscheidend ist danach, ob das fuer diesen Pure-ASM-Port benoetigte `$HOME/huc/bin/pceas` wirklich existiert und ausfuehrbar ist. Erst dann geht CI in `./build.sh`.

Ausserdem ist der Artifact-Upload tolerant gegen optionale `.sym`/`.lst`: `motr.pce` bleibt zwingend, Diagnosedateien werden hochgeladen, wenn PCEAS sie erzeugt.

### Warum der Prozentstand nicht steigt

Diese Phase beseitigt einen Build-Infrastrukturblocker, portiert aber kein weiteres Gameplay-Subsystem. Deshalb bleibt der belastbare Gesamtstand bei ca. 22 %, bis der eigene Assemblercode erfolgreich durch CI geht bzw. Montys sichtbarer Spritepfad implementiert ist.

## Aktuell offen

- Neuer CI-Lauf muss jetzt erstmals `./build.sh` / unseren PCEAS-Code erreichen.
- Etwaige echte Assemblerfehler werden aus diesem Lauf behoben.
- Monty ist noch nicht als PCE-Sprite sichtbar.
- UP/DOWN, Leiter-/Seil-Semantik und exakte Tile-State-Logik fehlen.
- Property-4/Piledriver-Nebenwirkung und Raumwechsel fehlen.
- 320px-Horizontalporches muessen im Emulator/Echthardware verifiziert werden.
- 5/6 ist weiterhin eine Bring-up-Approximation fuer PAL-Timing.

## Naechste harte Schritte

1. CI bis zum eigenen PCEAS-Lauf bringen und alle Assemblerfehler beseitigen.
2. Ein echtes `motr.pce` als CI-Artifact erzeugen und lokal zum Test bereitstellen.
3. Montys C64-Spritedaten extrahieren und in PCE-SPR-4bpp konvertieren.
4. SATB-Update anschliessen, damit Pad/Jump sichtbar werden.
5. UP/DOWN und vollstaendige C64-Tile-State-Logik portieren.
6. Raumwechsel, Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
