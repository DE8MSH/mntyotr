# Was bisher geschah

Stand: 2026-09-04 — Phase 18i

## Portierungsstand

**Gesamtport: ca. 32 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems und steigt nur fuer konkret portierte Subsysteme. Toolchain- und Build-Fixes erhoehen den Gameplay-Prozentsatz bewusst nicht.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent.

## Bereits umgesetzt

- Linux-Mint-22 Toolchain/Build/Run-Grundgeruest; GitHub-Actions-ROM-Build bleibt entfernt.
- PCE VDC/VCE Bring-up, Palette, BAT und VSync.
- Raum $00 mit echten konvertierten C64-Hintergrundtiles.
- PAL-orientierter Gameplay-Scheduler.
- Montys Sprungkurve, PCE-Pad, horizontale Bewegung, Step-Gate und erste Tile-Kollision.
- C64-Raumkanten und statisches 6x23-Weltgrid.
- Echte Monty-Walkgrafik fuer beide Blickrichtungen.
- Echte Monty-Climbgrafik als PCE-Spriteasset und VRAM-Uploadpfad.

## Phase 18i — PCEAS final-pass / Branch-Reichweite

Der Nutzerbuild kommt jetzt sauber durch alle Python-Regressionschecks und durch PCEAS Pass 1 und Pass 2. In Pass 3 wurden zwei getrennte Probleme sichtbar.

Erstens waren mehrere lokale `bsr`-Aufrufe im inzwischen groesser gewordenen Monty-Code ausserhalb der relativen BSR-Reichweite. Diese Aufrufe wurden auf die bereits im Projekt und in der HuC-Library verwendete `call`-Form umgestellt. Das betrifft die Collision-/Movement-Helfer in `monty_physics.asm` sowie den verbliebenen Walk-Upload-Aufruf in `monty_sprite.asm`.

Zweitens meldete die aktuelle HuC `include/hucc/vdc.asm` bei ihrer HuCard-RAM-Phase (`tia_to_vram_rom .phase tia_to_vram_ram`) in Pass 3 instabile Symboladressen. Das offizielle aktuelle Elmer-HuCard-Beispiel assembliert genau diese Bibliotheksfamilie mit `--newproc --strip -m -l 2 -S -gA --raw`. `build.sh` verwendet nun dieselbe PCEAS-Flagkombination statt nur `-S -gA -l 3`.

## Verifikationsstatus

Vom Nutzer bestaetigt: HuC/pceas wird gefunden, Split-Include-Pfade funktionieren, alle lokalen Regressionstests laufen durch, PCEAS erreicht Pass 3. Phase 18i behebt die konkret gemeldeten BSR-Reichweitenfehler und gleicht die PCEAS-Aufrufparameter an das aktuelle offizielle Elmer-HuCard-Beispiel an. Ein erfolgreicher kompletter Pass 3 und `build/monty.pce` sind noch nicht bestaetigt. GitHub Actions bleibt auf Wunsch entfernt.

## Aktuell offen

- Erneuten lokalen `./build.sh`-Lauf bis zur ROM-Erzeugung bringen und verbleibende PCEAS-Fehler direkt beheben.
- UP/DOWN sowie Leiter-/Seil-Tile-State portieren und `monty_upload_climb_frame` aktivieren.
- 12+12 Somersault-/Jumpframes portieren und an `monty_jump_phase` koppeln.
- Raum $01 und generischen Room-State/Renderer anschliessen.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
