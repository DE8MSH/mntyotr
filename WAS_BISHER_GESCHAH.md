# Was bisher geschah

Stand: 2026-09-04 — Phase 19

## Portierungsstand

**Gesamtport: ca. 34 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems. Toolchain-/Buildfixes allein erhoehen sie nicht.

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
- Echte Monty-Climbgrafik und jetzt auch deren Gameplay-Auswahl.

## Phase 18i — erster erfolgreicher ROM-Build

Vom Nutzer am 2026-09-04 bestaetigt: Nach den PCEAS-Final-Pass- und Branch-Reichweitenkorrekturen baut `./build.sh` erfolgreich eine startende `.pce`. Der Nutzer hat einen Emulator-Screenshot des laufenden ROMs geliefert. Damit sind Toolchain, lokaler Regressionstest, PCEAS-Durchlauf und ROM-Start erstmals end-to-end bestaetigt. Die sichtbare Raumdarstellung ist noch ein Zwischenstand und kein Pixelvergleich gegen das C64-Original.

## Phase 19 — Tile-State, UP/DOWN und Climb-Runtime

Die C64-Routine `Monty.UpdateTileFlags` wurde als naechster Gameplay-Baustein uebertragen: Montys logischer 2x3-Footprint wird auf Collision-Property 3 untersucht und daraus `monty_tile_state` gebildet. Wie im C64-Code wird vertikale Spielerbewegung nur zugelassen, wenn dieser Tile-State aktiv ist und kein Sprung laeuft.

PCE-Pad UP/DOWN bewegen Monty nun vertikal unter Collision-Pruefung. `monty_climbing` markiert die tatsaechliche vertikale Bewegung. Der bereits vorhandene authentische Viererblock der C64-Climb-Sprites wird jetzt vom Runtime-Animator ausgewaehlt; Wechsel zwischen Walk und Climb erzwingen einen VRAM-Frame-Upload. Die Animationsperiode bleibt bei vier logischen Ticks.

Wichtig: Raum $00 besitzt nach den bisher rekonstruierten Tile-Properties keine Property-3-Kachel. Der neue Leiter-/Seilpfad ist deshalb implementiert, wird aber erst in einem passenden Raum sichtbar testbar. Die generische Raumdatenpipeline ist weiterhin offen.

## Verifikationsstatus

Vom Nutzer bestaetigt: `./build.sh` erzeugt ein startendes PCE-ROM und der bisherige Raum wird im Emulator dargestellt. Phase 19 ist im Quellcode portiert, aber der neue Stand muss nach `git pull && ./build.sh` erneut assembliert werden. Leiter-/Seilbewegung kann in Raum $00 mangels Property-3-Tile noch nicht sinnvoll visuell verifiziert werden.

## Aktuell offen

- Phase-19-Stand erneut bauen und auf PCEAS-Regression pruefen.
- 12+12 Somersault-/Jumpframes portieren und an `monty_jump_phase` koppeln.
- Raum $01 und generischen Room-State/Renderer anschliessen; damit weitere Collision-Properties und Leiter-/Seilpfade real testbar machen.
- Collision-Abbildung zwischen C64-Screenkoordinaten und logischem 32x20-Raum weiter exakt verifizieren.
- Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
