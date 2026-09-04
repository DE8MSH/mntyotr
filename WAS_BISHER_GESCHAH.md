# Was bisher geschah

Stand: 2026-09-04 — Phase 18e

## Portierungsstand

**Gesamtport: ca. 32 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems und steigt nur fuer konkret portierte Subsysteme. Toolchain- und Regressionstest-Fixes erhoehen den Gameplay-Prozentsatz bewusst nicht.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent.

## Bereits umgesetzt

- Linux-Mint-22 Toolchain/Build/Run-Grundgeruest; GitHub-Actions-ROM-Build bleibt entfernt.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- Raum $00 mit echten konvertierten C64-Hintergrundtiles.
- PAL-orientierter Gameplay-Scheduler.
- Montys Sprungkurve, PCE-Pad, horizontale Bewegung, Step-Gate und erste Tile-Kollision.
- C64-Raumkanten und statisches 6x23-Weltgrid.
- Echte Monty-Walkgrafik fuer beide Blickrichtungen.
- Echte Monty-Climbgrafik als PCE-Spriteasset und VRAM-Uploadpfad.

## Phase 18e — Sprite-Regressionscheck

Der echte Nutzerlauf kommt jetzt erfolgreich durch die HuC/PCEAS- und Include-Erkennung. Der naechste Abbruch liegt in `tools/test_port.py`: die pauschale verkettete Assertion fuer WALK_L/WALK_R/CLIMB schlug fehl, bevor PCEAS gestartet wurde.

Der Test wurde so umgebaut, dass jede Spritegruppe separat auf Byte-Vielfaches und exakt vier Frames geprueft wird und bei einem Fehler den konkreten Gruppennamen, die Bytezahl und die ermittelte Framezahl meldet. Damit ist der naechste Lauf diagnostisch eindeutig statt nur `AssertionError` zu liefern. Die eigentliche Spritekonvertierung wird weiterhin auf 2048 PCE-Bytes pro Vier-Frame-Gruppe und gueltige 24x21-C64-Pixelmatrix geprueft.

## Verifikationsstatus

HuC/pceas wird im Nutzerlog gefunden und `PCE_INCLUDE` zeigt auf Elmer plus HuCC. Der Build erreicht nun die lokalen Port-Regressionschecks. Ein kompletter PCEAS-Lauf und `build/monty.pce` sind weiterhin noch nicht bestaetigt. GitHub Actions bleibt auf Wunsch entfernt.

## Aktuell offen

- Den nun detaillierten Sprite-Testlauf auswerten und gegebenenfalls die konkrete fehlerhafte C64-Framegruppe korrigieren.
- Danach den ersten echten PCEAS-Assemblerlauf erreichen und dessen Fehler direkt beheben.
- UP/DOWN sowie Leiter-/Seil-Tile-State portieren und `monty_upload_climb_frame` aktivieren.
- 12+12 Somersault-/Jumpframes portieren und an `monty_jump_phase` koppeln.
- Raum $01 und generischen Room-State/Renderer anschliessen.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
