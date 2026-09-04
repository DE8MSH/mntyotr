# Was bisher geschah

Stand: 2026-09-04 — Phase 18g

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

## Phase 18g — robuste VIC-Spritegrenzen

Der Nutzerlauf zeigte nach der ersten 63-Byte-Korrektur, dass WALK_R 255 Bytes enthaelt. Die handtranskribierten Animationen hatten also nicht einheitlich alle VIC-Paddingbytes entfernt: WALK_L war 252 Bytes, WALK_R 255 Bytes. Die Originalquelle belegt dagegen vier feste 64-Byte-VIC-Slots je Walk-Richtung und Climb ($5400-$56ff), wobei pro Frame nur die ersten 63 Bytes die 24x21-Bitmap bilden.

`tools/monty_sprite.py` nimmt deshalb nicht mehr an, dass die Transkription einen einheitlichen 63- oder 64-Byte-Stride hat. Fuer jede der drei bekannten Viereranimationen werden die vier authentischen Frame-Startsignaturen lokalisiert und jeweils exakt die folgenden 63 Bitmapbytes extrahiert. Damit werden eventuell vorhandene VIC-Padbytes verworfen, ohne sichtbare Bilddaten zu verschieben. Danach liegen WALK_L, WALK_R und CLIMB deterministisch bei je 4x63 Bytes; die PCE-Konvertierung bleibt 512 Bytes pro Frame bzw. 2048 Bytes pro Vierergruppe.

## Verifikationsstatus

HuC/pceas und die Split-Include-Pfade werden im Nutzerlog korrekt gefunden. Der Build erreicht die lokalen Port-Regressionschecks. Phase 18g behebt den dort konkret beobachteten inkonsistenten Sprite-Stride; ein erneuter Nutzerlauf steht noch aus. Ein kompletter PCEAS-Lauf und `build/monty.pce` sind weiterhin noch nicht bestaetigt. GitHub Actions bleibt auf Wunsch entfernt.

## Aktuell offen

- Erneuten lokalen `./build.sh`-Lauf bis zum ersten echten PCEAS-Assemblerlauf bringen und dessen Fehler direkt beheben.
- UP/DOWN sowie Leiter-/Seil-Tile-State portieren und `monty_upload_climb_frame` aktivieren.
- 12+12 Somersault-/Jumpframes portieren und an `monty_jump_phase` koppeln.
- Raum $01 und generischen Room-State/Renderer anschliessen.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
