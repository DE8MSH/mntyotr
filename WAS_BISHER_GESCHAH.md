# Was bisher geschah

Stand: 2026-09-04 — Phase 20

## Portierungsstand

**Gesamtport: ca. 32 %**

Die Prozentzahl bezeichnet den Anteil des fuer einen spielbaren 1:1-orientierten PCE-Port benoetigten Systems. Der Stand wurde konservativ von 34 % auf 32 % korrigiert, weil Raumdarstellung und Monty-Sprite erst jetzt visuell gegen die C64-Referenz nachgezogen werden.

## Verbindliche Referenz

Primaere Portierungsreferenz ist `Dave-Agent/monty-on-the-run/refactored/src`. Diese Version ist die editierbare, subsystem-orientierte KickAssembler-Rekonstruktion und laut Upstream funktional identisch zum Original. `byte-perfect` wird nur als zusaetzliche Ground-Truth fuer Originaladressen/Opcodefragen herangezogen. PCE-spezifische Anpassungen duerfen Hardwaredetails aendern, nicht aber Spielregeln, Raumdaten oder Animationslogik ohne dokumentierten Grund.

## Ziel

1:1-orientierter Port von *Monty on the Run* (C64) auf NEC PC Engine / HuCard.

## Bereits umgesetzt

- Linux-Mint-22 Toolchain/Build/Run-Grundgeruest; GitHub-Actions-ROM-Build bleibt entfernt.
- PCE VDC/VCE Bring-up, Palette, BAT und VSync.
- PAL-orientierter Gameplay-Scheduler.
- Montys Sprungkurve, PCE-Pad, horizontale Bewegung, Step-Gate und erste Tile-Kollision.
- C64-Raumkanten und statisches 6x23-Weltgrid.
- Echte Monty-Walkgrafik fuer beide Blickrichtungen.
- Echte Monty-Climbgrafik und deren Gameplay-Auswahl.

## Phase 18i — erster erfolgreicher ROM-Build

Vom Nutzer am 2026-09-04 bestaetigt: `./build.sh` erzeugt erfolgreich eine startende `.pce`; der Emulator zeigt den damaligen Raum-$00-Zwischenstand. Toolchain, Regressionstests, PCEAS und ROM-Start sind damit end-to-end bestaetigt.

## Phase 19/19a — Tile-State, UP/DOWN und Animation

C64-orientierter Tile-State, vertikale Bewegung und Climb-Auswahl wurden angelegt. Der Animator wurde danach so korrigiert, dass Idle nicht permanent Walkframes durchschaltet.

## Phase 20 — sichtbare C64-Paritaet zuerst

Der Screenshot des laufenden ROMs zeigte zwei grundlegende Fehler im bisherigen Bring-up. Beide werden vor weiteren Gameplay-Features korrigiert:

1. **Room-Character-Off-by-one:** `Room.SetupTileGraphics` des refactored C64-Codes laesst Character 0 leer und installiert die acht Raum-Tiles als Screen-Codes 1..8. Der PCE-Port hatte dagegen Tile-Slot 0 auf Character 0 gelegt. `room00_assets.asm` besitzt jetzt einen expliziten Blank-Character 0 und legt die acht echten C64-Tiles auf PCE Characters 1..8. Die PCE-Paletten sind ebenfalls nach Screen-Code 0..8 verschoben, passend zu `PopulateColourRam`.
2. **Unsichtbarer Monty:** Der Port lud bisher nur BG-Paletten. PCE-Sprites benutzen die separaten Paletten 16..31; Montys 1bpp-Konvertierung konnte deshalb schwarz/unsichtbar bleiben. SPR-Palette 0 wird jetzt explizit mit C64-Monty-Farbe 1 (weiss) geladen. Ausserdem wurde der PCE-SAT-X-Offset von +64 auf den Hardware-Offset +32 korrigiert; Y bleibt +64.

Diese Phase ist hochgeladen, aber noch nicht durch den naechsten lokalen Build/Emulator-Screenshot bestaetigt.

## Verifikationsstatus

- HuC/PCEAS Host-Toolchain: bestaetigt.
- Python-Regressionssuite: bestaetigt vor Phase 20.
- Startendes `.pce`: bestaetigt.
- Phase-20-Raumdarstellung: noch zu testen.
- Sichtbarer/animierter Monty: noch zu testen.
- Weitere Gameplay-Paritaet: erst nach dieser visuellen Baseline.

## Aktuell offen

- Phase 20 lokal bauen und Screenshot/Bewegung pruefen.
- C64 `DrawRoomPlayfield`, `CreatePlayfieldBorder`, `PopulateColourRam` und PCE-BAT-Ausgabe Pixel/Code fuer Pixel gegeneinander verifizieren.
- SATB-DMA/Sprite-Sichtbarkeit am laufenden ROM bestaetigen.
- Collision-Abbildung zwischen C64-40-Spalten-Screenkoordinaten und logischem 32x20-Raum exakt verifizieren.
- Danach 12+12 Somersault-/Jumpframes, generischer Room-Loader, Gegner, Mechanismen, Special Items, HUD/Gameflow und Audio.

## Referenzen

- C64-Rekonstruktion: https://github.com/Dave-Agent/monty-on-the-run
- Primaere Quelle: https://github.com/Dave-Agent/monty-on-the-run/tree/main/refactored/src
- Zielprojekt: https://github.com/DE8MSH/mntyotr
- HuC/PCEAS: https://github.com/pce-devel/huc
