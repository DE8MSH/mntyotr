# Was bisher geschah

Stand: 2026-09-04 — Phase 18b

## Portierungsstand

**Gesamtport: ca. 32 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems und steigt nur fuer konkret portierte Subsysteme. Die Toolchain-Fixes in Phase 18a/18b erhoehen den Gameplay-Prozentsatz bewusst nicht.

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

## Neu in Phase 18

Die vier originalen C64-Climbframes (Pointer $58-$5B, $5600-$56ff) sind jetzt in `tools/monty_sprite.py` enthalten. Wie die Walkframes werden die 24x21-C64-Bitmaps pixelgetreu in je zwei 16x32-PCE-Sprites umgesetzt.

`build.sh` erzeugt nun zusaetzlich `monty-climb.dat`. `src/monty_sprite.asm` bindet alle vier Frames ein und besitzt mit `monty_upload_climb_frame` einen eigenen VRAM-Uploadpfad. Der C64-Code verwendet fuer Climb `(movement_ticker & 3) + $58` und eine Vier-Tick-Animationskadenz; diese Vier-Frame-Struktur ist damit auf PCE-Seite vorbereitet.

## Phase 18a/18b — Linux-Mint-Toolchain korrigiert

Echte Nutzer-Builds zeigten, dass das aktuelle HuC-Buildsystem `pceas` unter `$HUC_DIR/src/mkit/as/pceas` erzeugt. Der erste Installer-Fix fand diesen Assembler und verlinkte `~/.local/bin/pceas`, aber ein unmittelbar danach gestartetes `build.sh` konnte den Link in einer Shell mit altem/ungewoehnlichem PATH weiterhin nicht ueber `command -v` finden.

Deshalb ist `build.sh` jetzt unabhaengig vom aktualisierten Shell-PATH: es akzeptiert zuerst einen expliziten `$PCEAS`, dann `command -v pceas`, danach direkt `$HUC_HOME/src/mkit/as/pceas`, `$HUC_HOME/src/bin/pceas` und `$HUC_HOME/bin/pceas`. Der vom Nutzer bestaetigte Pfad `/home/coderius/.local/opt/huc/src/mkit/as/pceas` wird damit direkt erkannt. Beim Start gibt das Script den tatsaechlich verwendeten Assembler aus.

## Verifikationsstatus

Der HuC/pceas-Hosttool-Build ist im Nutzerlog erfolgreich. Der Monty-ROM-Build kam bisher noch nicht bis zum Assemblieren, weil `build.sh` den vorhandenen Assembler nicht fand; dieser zweite Pfadfehler ist jetzt korrigiert. Der naechste `./build.sh`-Lauf sollte erstmals die eigentlichen PCEAS-Quellen erreichen. GitHub Actions bleibt auf Wunsch entfernt.

## Aktuell offen

- Naechsten echten lokalen `./build.sh`-Lauf auswerten und eventuelle PCEAS-Assemblerfehler direkt beheben.
- UP/DOWN sowie Leiter-/Seil-Tile-State portieren und `monty_upload_climb_frame` im Zustandsdispatcher aktivieren.
- 12+12 Somersault-/Jumpframes portieren und an `monty_jump_phase` koppeln.
- Raum $01 und generischen Room-State/Renderer anschliessen.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.
- 320px-Porches und PAL-Timing lokal verifizieren/kalibrieren.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
