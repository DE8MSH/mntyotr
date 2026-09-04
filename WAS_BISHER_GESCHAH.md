# Was bisher geschah

Stand: 2026-09-04 — Phase 18h

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

## Phase 18h — erster echter PCEAS-Lauf

Der Nutzerbuild passiert jetzt die Python-Regressionschecks und erreicht erstmals PCEAS. Dabei wurden zwei echte Buildfehler sichtbar und im Port korrigiert:

1. `tia [_bp],VDC_DL,512` war ungueltig. HuC6280 TIA ist ein Blocktransfer mit absoluten Quell-/Zieloperanden, nicht mit indirektem Quellzeiger. Der Monty-Upload dispatcht nun den Frame und verwendet pro Frame einen statisch assemblierbaren `tia frame_label,VDC_DL,512`.
2. `font8x8-ascii-bold-short.dat` war eine nicht mitkopierte externe Elmer-Beispieldatei. Der Debug-Banner samt Font-Upload wurde entfernt, weil er fuer das Spiel nicht benoetigt wird. Damit ist der ROM-Build nicht mehr von diesem externen Debug-Fontasset abhaengig.

Die Sprite-Regressionschecks selbst laufen im Nutzerlog bereits erfolgreich: room00=640, jump=22/17, clock=5/6, world=6x23 und 12 authentische Walk/Climb-Frames.

## Verifikationsstatus

HuC/pceas und die Split-Include-Pfade werden korrekt gefunden. Die lokalen Python-Porttests laufen im Nutzerlog erfolgreich. PCEAS startet und hat die oben dokumentierten ersten Assemblerfehler gemeldet. Die Korrekturen fuer diese Fehler sind committed; ein erneuter Nutzerlauf steht aus. `build/monty.pce` ist daher noch nicht bestaetigt. GitHub Actions bleibt auf Wunsch entfernt.

## Aktuell offen

- Erneuten `./build.sh` ausfuehren und verbleibende PCEAS-Fehler iterativ beseitigen, bis `build/monty.pce` entsteht.
- UP/DOWN sowie Leiter-/Seil-Tile-State portieren und `monty_upload_climb_frame` aktivieren.
- 12+12 Somersault-/Jumpframes portieren und an `monty_jump_phase` koppeln.
- Raum $01 und generischen Room-State/Renderer anschliessen.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
