# Was bisher geschah

Stand: 2026-09-04 — Phase 17

## Portierungsstand

**Gesamtport: ca. 31 %**

Die Prozentzahl steigt nur fuer neue konkret portierte Spielsysteme. Dieser Block korrigiert den vorhandenen Spritepfad und erhoeht deshalb den Gesamtwert bewusst nicht.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard. Referenz ist die kommentierte/refaktorierte 6502-Rekonstruktion von Dave-Agent.

## Bereits umgesetzt

- Linux-Mint-22 Toolchain/Build/Run-Grundgeruest; GitHub-Actions-ROM-Build bleibt entfernt.
- PCE VDC/VCE Bring-up, Palette, Font, BAT und VSync.
- Raum $00 mit echten konvertierten C64-Hintergrundtiles.
- PAL-orientierter Gameplay-Scheduler.
- Montys Sprungkurve, PCE-Pad, horizontale Bewegung, Step-Gate und erste Tile-Kollision.
- C64-Raumkanten und statisches 6x23-Weltgrid.
- Echte Monty-Walkgrafik fuer beide Blickrichtungen, 8 authentische C64-Frames.

## Neu in Phase 17

Der PCE-Spritepfad wurde gegen die HuC6270-SATB-Dokumentation geprueft und drei konkrete Fehler wurden korrigiert:

1. Die SATB-Quelladresse wird jetzt ueber VDC-Register $13 gesetzt und nach Aktualisierung erneut fuer den VRAM->internen-SAT-Transfer aktiviert.
2. Das SPBG-Prioritaetsbit ist jetzt gesetzt, damit Monty vor dem Background liegt. Fuer 16x32 wird das Attributwort $1080 verwendet: CGY=01, CGX=0, foreground, Palette 0.
3. Der rechte 16x32-Teil beginnt nach 256 Bytes. Vorher stand dort faelschlich +128, was auf den unteren 16x16-Block des linken Sprites zeigte.

Ausserdem war `tools/test_port.py` nach der Walk-right-Erweiterung inkonsistent: er importierte noch die entfernte Funktion `build_walk_left`. Der Test nutzt jetzt die aktuelle `build()`-API und prueft beide Richtungen, insgesamt acht authentische Frames.

## Verifikationsstatus

Die statische SATB-/Patternlogik entspricht jetzt der dokumentierten HuC6270-Struktur. Ein echter PCEAS-/Emulatorlauf wurde weiterhin nicht ausgefuehrt; GitHub Actions bleibt auf Wunsch entfernt. Deshalb wird sichtbare Laufzeitfunktion noch nicht behauptet.

## Aktuell offen

- 12+12 Somersault-/Jumpframes und 4 Climbframes portieren und zustandsabhaengig auswaehlen.
- Raum $01 und generischen Room-State/Renderer anschliessen.
- DOWN/UP, Leiter-/Seil- und vollstaendige Tile-State-Logik.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.
- 320px-Porches und PAL-Timing lokal verifizieren/kalibrieren.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
