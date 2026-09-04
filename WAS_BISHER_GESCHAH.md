# Was bisher geschah

Stand: 2026-09-04 — Phase 18f

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

## Phase 18f — C64-Sprite-Stride korrigiert

Der Nutzerlauf hat den vorher verbesserten Regressionstest erreicht und den eigentlichen Datenfehler eindeutig gezeigt: `WALK_L` enthaelt 252 Byte. Das ist korrekt fuer vier hintereinander notierte 24x21-Monochrom-Bitmaps: 21 Zeilen * 3 Byte = 63 sichtbare Bitmapbytes pro Frame, also 252 Byte fuer vier Frames.

Die VIC-II-Spritepointer arbeiten dagegen mit 64-Byte-Slots. Das 64. Byte eines Slots ist kein Teil der 24x21-Bitmap. Unser Konverter hatte die eingebetteten, pad-losen 63-Byte-Quellblobs faelschlich mit einem 64-Byte-Stride zerlegt. `tools/monty_sprite.py` verwendet deshalb jetzt explizit `BITMAP_BYTES=63` fuer die eingebetteten Quelldaten und dokumentiert `VIC_FRAME_BYTES=64` separat. `c64_frame_pixels()` akzeptiert sowohl 63-Byte-Bitmapdaten als auch einen vollstaendigen 64-Byte-VIC-Slot und ignoriert beim Dekodieren ein vorhandenes Padbyte. `build()` zerlegt die eingebetteten WALK_L/WALK_R/CLIMB-Daten mit dem korrekten 63-Byte-Stride.

Damit prueft `tools/test_port.py` weiterhin vier Frames je Gruppe, nun aber gegen die tatsaechliche Struktur der eingebetteten Rekonstruktionsdaten. Die erzeugte PCE-Ausgabe bleibt unveraendert 512 Byte pro konvertiertem Monty-Frame bzw. 2048 Byte pro Vier-Frame-Gruppe.

## Verifikationsstatus

HuC/pceas wird im Nutzerlog gefunden und `PCE_INCLUDE` zeigt auf Elmer plus HuCC. Der Build erreicht die lokalen Port-Regressionschecks. Der konkret gemeldete `WALK_L: 252 bytes ... FRAME_BYTES=64`-Fehler ist in Phase 18f im Konverter behoben. Ein erneuter Nutzerlauf muss jetzt bestaetigen, dass alle lokalen Tests passieren und PCEAS erstmals den eigentlichen Monty-Assembler erreicht. `build/monty.pce` ist weiterhin noch nicht bestaetigt. GitHub Actions bleibt auf Wunsch entfernt.

## Aktuell offen

- Erneuten lokalen `./build.sh`-Lauf auswerten; naechsten Fehler direkt beheben, bis PCEAS ein ROM erzeugt.
- UP/DOWN sowie Leiter-/Seil-Tile-State portieren und `monty_upload_climb_frame` aktivieren.
- 12+12 Somersault-/Jumpframes portieren und an `monty_jump_phase` koppeln.
- Raum $01 und generischen Room-State/Renderer anschliessen.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
