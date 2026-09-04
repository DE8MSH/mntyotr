# Was bisher geschah

Stand: 2026-09-04 — Phase 16

## Portierungsstand

**Gesamtport: ca. 31 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems und steigt nur fuer konkret portierte Subsysteme.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent.

## Bereits umgesetzt

- Linux-Mint-22 Toolchain/Build/Run-Grundgeruest; GitHub-Actions-ROM-Build bleibt entfernt.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- Raum $00 mit echten konvertierten C64-Hintergrundtiles.
- PAL-orientierter Gameplay-Scheduler.
- Montys Sprungkurve, PCE-Pad, horizontale Bewegung, Step-Gate und erste Tile-Kollision.
- C64-Raumkanten und statisches 6x23-Weltgrid.
- Echte Monty-Walkgrafik jetzt fuer beide Blickrichtungen.

## Neu in Phase 16

`tools/monty_sprite.py` enthaelt jetzt neben den vier originalen Walk-left-Frames auch die vier originalen Walk-right-Frames (C64 Pointer $54-$57, Bereich $5500-$55ff). Beide Richtungen werden 24x21 pixelgetreu in zwei 16x32-PCE-Sprites pro Bild umgesetzt.

Der Build erzeugt nun `monty-walk-l.dat` und `monty-walk-r.dat`. `src/monty_sprite.asm` waehlt anhand des bereits portierten `monty_facing` automatisch den linken oder rechten Originalsatz. Ein Richtungswechsel markiert das Sprite sofort dirty und laedt das passende Bild in VRAM; die Vier-Tick-Animationskadenz bleibt erhalten.

Damit ist Montys normale Laufgrafik in beiden Richtungen in der Asset- und Runtime-Pipeline vorhanden. Climb und die 12+12 Somersaultframes fehlen weiterhin.

## Verifikationsstatus

Der neue Stand wurde nicht als ROM/Emulatorlauf verifiziert. GitHub Actions bleibt auf Wunsch entfernt. SATB-Attributbits und Patternadressierung muessen lokal mit PCEAS/Emulator bestaetigt werden.

## Aktuell offen

- 12+12 Somersault-/Jumpframes und Climbframes portieren und zustandsabhaengig auswaehlen.
- Raum $01 und generischen Room-State/Renderer anschliessen.
- DOWN/UP, Leiter-/Seil- und vollstaendige Tile-State-Logik.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.
- 320px-Porches und PAL-Timing verifizieren/kalibrieren.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
